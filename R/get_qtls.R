#'Query Qtlizer
#'
#'@description Query Qtlizer database for expression quantitative trait loci (eQTLs) in human.
#'
#'@param query The query. Can either be a single string or a vector.
#' Qtlizer allows to query both variants (Rsid, ref_version:chr:pos) and
#'  genes (Symbol consisting of letters and numbers according to the HGNC guidelines).
#'@param corr Linkage disequilibrium based on 1000Genomes Phase 3 European.
#' Optional value between 0.1 and 1. Default value is NA. 
#'@param max_terms Number of queries made at a time. The default value is 5. 
#'A large value can lead to a very large result set and a error by the database.
#'@param ld_method There are two methods. Default method is "r2". 
#'The other opportunity is to use "dprime".
#'@param ref_version Two possible versions to use hg19 or hg38. Default value
#'is hg19.
#'@param return_obj The user can choose to get the output as a dataframe or 
#'as a GRange object. The default value is the dataframe. If a GRange object is 
#'wanted use return_obj = "grange". 
#'@return Data frame with response.
#'@examples get_qtls("rs4284742")
#'get_qtls(c("rs4284742", "DEFA1"))
#'get_qtls(c("rs4284742,DEFA1"))
#'get_qtls("rs4284742", return_obj="grange", ref_version="hg38")
#'get_qtls("rs4284742", corr=0.6)
#'get_qtls("rs4284742", corr=0.2, ld_method = "dprime")
#'@export
get_qtls = function(query, corr = NA, max_terms = 5, ld_method = "r2", 
                     ref_version = "hg19", return_obj = "dataframe"){
  
  # Check if there is an internet connection
  if (!curl::has_internet())
    stop("no internet connection detected...")
    
   
  # Split terms
  query = paste(query, sep = ' ', collapse = ' ')
  query = unique(unlist(strsplit(query, "[\\n\\s,\\t.;]+", perl=TRUE)))
  message(length(query)," unique query term(s) found")
  
  
  # Binning
  print(query)
  bins = vector_split(query, ceiling(length(query)/max_terms))
  bins = stri_join_list(bins, sep = ",")

  
  # Communicate with database
  message("Retrieving QTL information from Qtlizer...")
  res = lapply(bins, mkQuery, corr = corr, ld_method = ld_method)
  res = do.call(rbind, res)
  
  if(!is.null(res)){
    message(nrow(res), " data points received")
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
  
  
  # Create GRange container
  if(return_obj == "grange"){
    
    if(ref_version == "hg19"){
      
      # Check for missing hg19 positions
      res_with_hg19 = res[which(!is.na(res$var_pos_hg19)),] 
      if(nrow(res_with_hg19) < nrow(res)){
          message("Not all results in GRange object included due to missing hg19 positions. Please use set ref_version to 'hg38' andd/or set return_obj to 'dataframe' to obtain all results.")
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
#'@param corr Linkage disequilibrium based on 1000Genomes Phase 3 European.
#' Optional value between 0 and 1. Default value is NA. 
#'@param ld_method There are two methods. Default method is "r2". 
#'The other opportunity is to use "dprime".
#'@return Data frame with results.
mkQuery = function(q, corr, ld_method){
  
  
  # Build URL
  url = paste0('http://genehopper.de/rest/qtlizer?q=', q)
  
  if(is.numeric(corr) && corr>=0 && corr<=1){
    url = paste0(url, "&corr=", corr)
  }
  if(is.character(ld_method) && (ld_method == "r2" || corr == "dprime")){
    url = paste0(url, "&ld_method=", ld_method)
  }

  
  # Send post request and retrieve response
  response = httr::POST(url)
  result = httr::content(response)
  result = unlist(strsplit(result , "\n"))
  
  
  # Display error message from server
  if(is.null(grep("^#", result))){
    warning(result)
    return(NULL)
  }
  
  
  # Extract
  meta = grep("^#", result, value = TRUE)
  data = grep("^[^#]", result, value = TRUE)
  
  
  # If no QTLs were found
  if(length(data)-1 <= 0) {
    message("No QTLs found")
    return(NULL)
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
vector_split = function(v, n) {
  l = length(v)
  r = l/n
  return(lapply(1:n, function(i) {
    s = max(1, round(r*(i-1))+1)
    e = min(l, round(r*i))
    return(v[s:e])
  }))
}
