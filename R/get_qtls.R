#'Query Qtlizer
#'
#'@description Makes a query at Qtlizer and returns results as data frame.
#'
#'@param query The qtlizer query. Can either be a single string or a vector.
#'@param r2 Linkage disequilibrium based on 1000Genomes Phase 3 European.
#' Optional value between 0 and 1. Default value is 0.8. 
#'@param max_terms Number of queries made at a time.  The default value is 10. 
#'It is recommended to not set the value higher than 10.
#'@return Data frame with response.
#'@examples get_qtls("rs4284742")
#'get_qtls(c("rs4284742", "DEFA1"))
#'get_qtls("rs4284742", 0.6)
#'get_qtls("rs4284742", max_terms = 4)
#'@export
get_qtls <- function(query, r2 = 0.8, max_terms = 10){
    
    #inside function that actually makes the queries
    mkQuery <- function(q, r2 = 0.8){
        ld_method <- "r2" # optional default
        
        url <- paste('http://genehopper.de/rest/qtlizer?q=', gsub("\\s+", ",", q), 
            "&corr=", r2, "&ld_method=", ld_method, sep="")
        message("Retrieving QTL information from Qtlizer...")
        response <- httr::POST(url)
        result <- httr::content(response)
    
        a <- unlist(strsplit(result , "\n"))
        meta <- grep("^#", a, value = TRUE)
        data <- grep("^[^#]", a, value = TRUE)
        message(length(data)-1, " data points retrieved")
        header <- unlist(strsplit(data[1], "\t"))
        ncols <- length(header)
        if(!is.null(a) && is.null(grep("^#", a))) {warning(a)} #print return value if no QTL
        
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
        
        message("Done.")
        return(d)
    } 
    #convert convert into the desired shape
    len = length(query)
    if(len == 1){ #single string
        q <- query
    } else{
        q <- paste(query, collapse = ' ') #make a single query
    }
    
    spltq <- unlist(strsplit(q, " "))
    message(length(spltq)," query terms found")
    fill = max_terms - length(spltq) %% max_terms
    if (fill != 0 && max_terms != 1)
        {spltq <- c(spltq, vector(mode = "character", length = fill))}
    y <- matrix(spltq,  ncol=min(max_terms, length(spltq)))
    s <- apply(y,1,paste,collapse=" ")
    
    if (!curl::has_internet()) {warning("no internet connection detected...")}
    
    res = lapply(s, mkQuery, r2 = r2)
    res = res[[1]]
    
    return(res)

}
