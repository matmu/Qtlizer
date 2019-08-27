#'Query Qtlizer
#'
#'@description Queries Qtlizer database for expression quantitative trait loci (eQTLs) in human.
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
#'get_qtls("rs4284742", 0.6)
#'get_qtls("rs4284742", max_terms = 4)
#'get_qtls("rs4284742", ld_method = "dprime")
#'@export

get_qtls <- function(query, corr = NA, max_terms = 5, ld_method = "r2", 
                     ref_version = "hg19", return_obj = "dataframe"){

    {if (!curl::has_internet()) 
        stop("no internet connection detected...")
    
    #inside function that actually makes the queries
   
    #convert convert into the desired shape
    len = length(query)
    if(len == 1){ #single string
        q <- query
    } else{
        q <- paste(query, collapse = ' ') #make a single query
    }
    
    spltq <- unlist(strsplit(q, " "))
    message(length(spltq)," query term(s) found")
    fill = max_terms - length(spltq) %% max_terms
    if (fill != 0 && max_terms != 1)
        {spltq <- c(spltq, vector(mode = "character", length = fill))}
    y <- matrix(spltq,  ncol=min(max_terms, length(spltq)))
    s <- apply(y,1,paste,collapse=" ")
    message("Retrieving QTL information from Qtlizer...")
    res = lapply(s, mkQuery, corr = corr, ld_method = ld_method)
    res = do.call(rbind, res)
    
    if(all(c("p", "distance", "n_qtls", "n_best", "n_sw_sign", "n_occ")
        %in% names(res))){
        res$distance <- as.numeric(res$distance)
        res$p <- as.numeric(res$p) 
        res$n_qtls <- as.numeric(res$n_qtls)
        res$n_best <- as.numeric(res$n_best) 
        res$n_sw_sign <- as.numeric(res$n_sw_sign)
        res$n_occ <- as.numeric(res$n_occ)
    }
    if(!is.null(nrow(res))) message(nrow(res), " datapoints received")
    message("Done.")
    
    if (return_obj %in% "grange"){
      if(ref_version %in% "hg19") {
        rowtokeep = complete.cases(res$var_pos_hg19) #check for NA values
        if(!is.null(rowtokeep)) {
          resWithoutNA = res[rowtokeep,]
          if (nrow(resWithoutNA) < nrow(res)) message("Not all results in GRange object included due to NA values. 
                                                 Please use the ref_versioin = hg38 option or return a dataframe to obtain all results.")
        } else {
          resWithoutNA = res
        }
        gres = GenomicRanges::makeGRangesFromDataFrame(resWithoutNA,start.field = "var_pos_hg19", end.field = "var_pos_hg19", 
                                                       seqnames.field = "chr", keep.extra.columns = TRUE)
        
      } else {
        gres = GenomicRanges::makeGRangesFromDataFrame(res,start.field = "var_pos_hg38", end.field = "var_pos_hg38", 
                                                       seqnames.field = "chr", keep.extra.columns = TRUE)
      }
      GenomicRanges::strand(gres) <- "+" 
      comment(gres) = comment(res) 
      return(gres)
     
    } else {
      return(res)
    }
    }
}

#'Actullaly makes the connection to server and returns results
#'@param q The qtlizer query. Can either be a single string or a vector.
#'@param corr Linkage disequilibrium based on 1000Genomes Phase 3 European.
#' Optional value between 0.1 and 1. Default value is NA. 
#'@param ld_method There are two methods. Default method is "r2". 
#'The other opportunity is to use "dprime".
#'@return Data frame with response.
mkQuery <- function(q, corr, ld_method){
  
  
  # Build URL
  url <- paste0('http://genehopper.de/rest/qtlizer?q=', gsub("\\s+", ",", q))
  
  if(is.numeric(corr) && corr>=0 && corr<=1){
    url = paste0(url, "&corr=", corr)
  }
  if(is.character(ld_method) && (ld_method == "r2" || corr == "dprime")){
    url = paste0(url, "&ld_method=", ld_method)
  }
  
  
  # Send post request and retrieve response
  response <- httr::POST(url)
  result <- httr::content(response)
  
  
  # If response is fine convert to data frame
  a <- unlist(strsplit(result , "\n"))
  meta <- grep("^#", a, value = TRUE)
  data <- grep("^[^#]", a, value = TRUE)
  
  datapoints <- length(data)-1
  if(datapoints == 0) {
      message("No QTLs found")
      return(NULL)
  }
  header <- unlist(strsplit(data[1], "\t"))
  ncols <- length(header)
  if(is.null(grep("^#", a)))  
  {warning(a)} #Display error message from server
  
  if(is.null(data[-1])){
    data <- NA
  } else {
    data <- unlist(strsplit(data[-1], "\t"))
  }
  m <- matrix(data, ncol=ncols, byrow=TRUE)
  d <- as.data.frame(m, stringsAsFactors=FALSE)
  d[d=="-"] <- NA
  colnames(d) = header
  comment(d) = meta
  return(d)
} 

