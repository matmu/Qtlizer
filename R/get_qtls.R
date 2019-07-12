#'Query Qtlizer
#'
#'@description Makes a query at Qtlizer and returns results as data frame.
#'
#'@param query The qtlizer query. Can either be a single string or a vector.
#'@param r2 Optional value between 0 and 1. Default value is 0.8. 
#'@return Data frame with response.
#'@examples get_qtls("rs4284742")
#'get_qtls(c("rs4284742", "DEFA1"))
#'get_qtls("rs4284742", 0.6)
#'@export
get_qtls <- function(query, r2 = 0.8){
  
  #inside function that actually makes the queries
  mkQuery <- function(q, r2 = 0.8){
    ld_method <- "r2" # optional default
    print(paste("connecting to Qtlizer with query ", q, " ......"))
    url <- paste('http://genehopper.de/rest/qtlizer?q=', gsub("\\s+", ",", q), 
                 "&corr=", r2, "&ld_method=", ld_method, sep="")
    print(paste("URL--------------------", url))
    response <- httr::POST(url)
    result <- httr::content(response)
    
    a <- unlist(strsplit(result , "\n"))
    meta <- grep("^#", a, value = TRUE)
    data <- grep("^[^#]", a, value = TRUE)
    header <- unlist(strsplit(data[1], "\t"))
    ncols <- length(header)
    
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
    print("finished")
    return(d)
  } 
    #Note: in the current version of Qtlizer, queries including 
    #gene identifier and chromosomal positions
    #of variants taker longer than if using rsids only
  
    #convert convert into the desired shape
    len = length(query)
    if(len == 1){ #single string
        q <- query
    } else{
        q <- paste(query, collapse = ' ') #make a single query
    }
    
    max_terms = 2 #maximum number of queries made at a time
    spltq <- unlist(strsplit(q, " "))
    y <- matrix(spltq,  ncol=max_terms)
    s <- apply(y,1,paste,collapse=" ")
    #q <- lapply(s, mkQuery)
    
    return(lapply(s, mkQuery, r2 = r2))
    

    

}
