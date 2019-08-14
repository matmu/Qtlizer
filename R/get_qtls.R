#'Query Qtlizer
#'
#'@description Makes a query at Qtlizer and returns results as data frame.
#'
#'@param query The qtlizer query. Can either be a single string or a vector.
#'@param corr Linkage disequilibrium based on 1000Genomes Phase 3 European.
#' Optional value between 0.1 and 1. Default value is 0.8. 
#'@param max_terms Number of queries made at a time.  The default value is 5. 
#'It is recommended to not set the value higher than 5.
#'@param ld_method There are two methods. Default method is "r2". 
#'The other opportunity is to use "dprime".
#'@return Data frame with response.
#'@examples get_qtls("rs4284742")
#'get_qtls(c("rs4284742", "DEFA1"))
#'get_qtls("rs4284742", 0.6)
#'get_qtls("rs4284742", max_terms = 4)
#'get_qtls("rs4284742", ld_method = "dprime")
#'@export
get_qtls <- function(query, corr = 0.8, max_terms = 5, ld_method = "r2"){
    message("Please visit our websites for further information \n
            --- \n
            Web-based GUI: http://genehopper.de/qtlizer \n
            Documentation: http://genehopper.de/help#qtlizer_docu \n
            Github Repo: https://github.com/matmu/Qtlizer \n
            ---")
    {if (!curl::has_internet()) 
        stop("no internet connection detected...")
    
    #inside function that actually makes the queries
    mkQuery <- function(q, corr = 0.8, ld_method = "r2"){
        #ld_method <- "r2" # optional default
        
        url <- paste('http://genehopper.de/rest/qtlizer?q=', gsub("\\s+", ",", q), 
            "&corr=", corr, "&ld_method=", ld_method, sep="")
        message("Retrieving QTL information from Qtlizer...")
        response <- httr::POST(url)
        result <- httr::content(response)
    
        a <- unlist(strsplit(result , "\n"))
        meta <- grep("^#", a, value = TRUE)
        data <- grep("^[^#]", a, value = TRUE)
        message(length(data)-1, " data points retrieved")
        header <- unlist(strsplit(data[1], "\t"))
        ncols <- length(header)
        if(!is.null(a) && is.null(grep("^#", a))) 
            {warning(a)} #print return value if no QTL
        
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
    res = lapply(s, mkQuery, corr = corr, ld_method = ld_method)
    res = res[[1]]
    
    if(all(c("p", "distance", "n_qtls", "n_best", "n_sw_sign", "n_occ")
        %in% names(res))){
        res$distance <- as.numeric(res$distance)
        res$p <- as.numeric(res$p) 
        res$n_qtls <- as.numeric(res$n_qtls)
        res$n_best <- as.numeric(res$n_best) 
        res$n_sw_sign <- as.numeric(res$n_sw_sign)
        res$n_occ <- as.numeric(res$n_occ)
    }
    
    return(res)
    }
}
