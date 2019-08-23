#'Query Qtlizer
#'
#'@description Queries Qtlizer database for expression quantitative trait loci (eQTLs) in human.
#'
#'@param query The query. Can either be a single string or a vector. Qtlizer allows to query both variants (Rsid, ref_version:chr:pos) and genes (Symbol consisting of letters and numbers according to the HGNC guidelines).
#'@param corr Linkage disequilibrium based on 1000Genomes Phase 3 European.
#' Optional value between 0.1 and 1. Default value is 0.8. 
#'@param max_terms Number of queries made at a time. The default value is 5. 
#'A large value can lead to a very large result set and a error by the database.
#'@param ld_method There are two methods. Default method is "r2". 
#'The other opportunity is to use "dprime".
#'@return Data frame with response.
#'@examples get_qtls("rs4284742")
#'get_qtls(c("rs4284742", "DEFA1"))
#'get_qtls("rs4284742", 0.6)
#'get_qtls("rs4284742", max_terms = 4)
#'get_qtls("rs4284742", ld_method = "dprime")
#'@export
get_qtls <- function(query, corr = null, max_terms = 5, ld_method = "r2"){
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
    return(res)
    }
}

#'Actullaly makes the connection to server and returns results
#'@param q The qtlizer query. Can either be a single string or a vector.
#'@param corr Linkage disequilibrium based on 1000Genomes Phase 3 European.
#' Optional value between 0.1 and 1. Default value is 0.8. 
#'@param ld_method There are two methods. Default method is "r2". 
#'The other opportunity is to use "dprime".
#'@return Data frame with response.
mkQuery <- function(q, corr = 0.8, ld_method = "r2"){
  #ld_method <- "r2" # optional default
  
  url <- paste('http://genehopper.de/rest/qtlizer?q=', gsub("\\s+", ",", q), 
               "&corr=", corr, "&ld_method=", ld_method, sep="")

  response <- httr::POST(url)
  result <- httr::content(response)
  
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

