#'Query Qtlizer
#'
#'@description Makes a query at Qtlizer and returns results as data frame.
#'
#'@param query The qtlizer query. Can either be a single string or a vector.
#'@return Data frame with response.
#'@examples get_qtls("rs4284742")
#'get_qtls(c("rs4284742", "DEFA1"))
#'
#'@importFrom utils write.table
#'@export
get_qtls <- function(query){
    #Note: in the current version of Qtlizer, queries including 
    #gene identifier and chromosomal positions
    #of variants taker longer than if using rsids only
    len = length(query)
    if(len == 1){ #single string
        q <- query
    } else{
        q <- paste(query, collapse = ' ') #make a single query
    }
    
    corr <- 0.8 # optional
    ld_method <- "r2" # optional
    url <- paste('http://genehopper.de/rest/qtlizer?q=', gsub("\\s+", ",", q), 
        "&corr=", corr, "&ld_method=", ld_method, sep="")
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
    return(d)

}
