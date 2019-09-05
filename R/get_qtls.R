#'Query Qtlizer
#'
#'@description Query Qtlizer database for expression quantitative 
#'trait loci (eQTLs) in human.
#'
#'@param query The query consists of search terms and can be a single 
#'string or a vector. Qtlizer allows to query both variants 
#'(Rsid, ref_version:chr:pos) and genes (Symbol consisting of letters 
#'and numbers according to the HGNC guidelines). Minimum allowed term length is 2.
#'@param corr Linkage disequilibrium based on 1000 Genomes Phase 3 European. 
#'If this optional value between 0 and 1 is set, 
#'the input variants are enriched for proxy variants passing the threshold. 
#'Default value is NA. 
#'@param max_terms Number of terms in a single HTTP request. Default value is 5. 
#'A large value can lead to a very large result set and a error by the database.
#'@param ld_method There are two methods available: "r2" (default) and "dprime".
#'@param ref_version Two possible versions are supported: hg19 (GRCh37) or 
#'hg38 (GRCh38). Default value is "hg19". 
#'This argument is only considered if a GenomicRanges::GRanges object is returned.
#'@param return_obj The user can choose to get the QTL data to be returned 
#'as data frame or as a GenomicRanges::GRanges object. The default value is "dataframe".
#'@return Data frame or GenomicRanges::GRanges object containing QTL data.
#'@examples get_qtls("rs4284742")
#'get_qtls(c("rs4284742", "DEFA1"))
#'get_qtls("rs4284742,DEFA1")
#'get_qtls("rs4284742", return_obj="granges", ref_version="hg38")
#'get_qtls("rs4284742", corr=0.6)
#'@export
get_qtls = function(query, corr = NA, max_terms = 5, ld_method = "r2", 
                    ref_version = "hg19", return_obj = "dataframe"){
  
  # Check if there is an internet connection
  if (!curl::has_internet())
    stop("No internet connection detected...")
  
  
  # Split terms
  query = paste(query, sep = ' ', collapse = ' ')
  query = unique(unlist(strsplit(query, "[\\n\\s,\\t.;]+", perl=TRUE)))
  query = query[stringi::stri_length(query)>1]
  message(length(query)," unique query term(s) found")
  
  
  # Binningtolower
  bins = vector_split(query, ceiling(length(query)/max_terms))
  bins = stringi::stri_join_list(bins, sep = ",")
  
  
  # Communicate with database
  message("Retrieving QTL information from Qtlizer...")
  res = lapply(bins, communicate, corr = corr, ld_method = ld_method)
  res = do.call(rbind, res)
  
  if(!is.null(res)){
    message(nrow(res), " data point(s) received")
  } else {
    return(res)
  }
  
  
  # Convert to respective data types
  res[res == "-"] = NA
  if(all(c("p", "distance", "n_qtls", "n_best", "n_sw_sign", "n_occ") %in% names(res))){
    res$distance = as.numeric(res$distance)
    res$p = as.numeric(res$p) 
    res$n_qtls = as.numeric(res$n_qtls)
    res$n_best = as.numeric(res$n_best) 
    res$n_sw_sign = as.numeric(res$n_sw_sign)
    res$n_occ = as.numeric(res$n_occ)
  }
  
  
  # Create GRanges container
  if(tolower(return_obj) == "granges"){
    
    if(tolower(ref_version) == "hg19" || tolower(ref_version) == "grch37"){
      
      # Check for missing hg19 positions
      res_with_hg19 = res[which(!is.na(res$var_pos_hg19)),] 
      if(nrow(res_with_hg19) < nrow(res)){
        message("Not all results in GRanges object included due to missing hg19 (GRCh37) positions. Please use set ref_version to hg38 (GRCh38) andd/or set return_obj to 'dataframe' to obtain all results.")
      }
      
      gres = GenomicRanges::makeGRangesFromDataFrame(res_with_hg19, start.field = "var_pos_hg19", end.field = "var_pos_hg19", 
                                                     seqnames.field = "chr", keep.extra.columns = TRUE)
      
    } else {
      gres = GenomicRanges::makeGRangesFromDataFrame(res, start.field = "var_pos_hg38", end.field = "var_pos_hg38", 
                                                     seqnames.field = "chr", keep.extra.columns = TRUE)
    }
    
    GenomicRanges::strand(gres) = "+" 
    comment(gres) = comment(res)
    
    return(gres)
    
  } else {
    return(res)
  }
}


#'URL building and request/response handling
#'@param q The qtlizer query. Can either be a single string or a vector.
#'@param corr Linkage disequilibrium based on 1000 Genomes Phase 3 European.
#' Optional value between 0 and 1. Default value is NA. 
#'@param ld_method There are two methods. Default method is "r2". 
#'The other opportunity is to use "dprime".
#'@return Data frame with results.
#'@keywords internal
communicate = function(q, corr, ld_method, n.tries=2){
  
  
  # Build URL
  url = paste0('http://genehopper.de/rest/qtlizer?q=', q)
  
  if(is.numeric(corr) && corr>=0 && corr<=1){
    url = paste0(url, "&corr=", round(corr, digits=2))
    
    if(is.character(ld_method) && (ld_method == "r2" || ld_method == "dprime")){
      url = paste0(url, "&ld_method=", ld_method)
    }
  }
  
  
  # Send POST request and retrieve response
  while(n.tries > 0){
    response = httr::POST(url)
    
    if(!httr::http_error(response)){
      break
    }
    
    Sys.sleep(3)
    n.tries = n.tries-1
  }
  
  
  if(n.tries == 0){
    stop("Web server seems to be down. Try again later!")
  }
  
  
  result = httr::content(response)
  result = unlist(strsplit(result , "\n"))
  
  
  # Display error message from server
  if(is.null(grep("^#", result))){
    warning(result)
    return()
  }
  
  
  # Extract
  meta = grep("^#", result, value = TRUE)
  data = grep("^[^#]", result, value = TRUE)
  
  
  # If no QTLs were found
  if(length(data)-1 <= 0) {
    message("No QTLs found")
    return()
  }
  
  
  # Convert to dataframe
  header = unlist(strsplit(data[1], "\t"))
  ncols = length(header)
  data = unlist(strsplit(data[-1], "\t"))
  
  m = matrix(data, ncol=ncols, byrow=TRUE)
  d = as.data.frame(m, stringsAsFactors=FALSE)
  colnames(d) = header
  comment(d) = meta
  
  return(d)
}


#'Splits vector v into n subvectors
#'@param v input vector
#'@param n number of subvectors
#'@return List with subvectors.
#'@keywords internal
vector_split = function(v, n) {
  l = length(v)
  r = l/n
  return(lapply(seq_len(n), function(i){
    s = max(1, round(r*(i-1))+1)
    e = min(l, round(r*i))
    return(v[s:e])
  }))
}
