#'Query Qtlizer
#'
#'@description Makes a query at Qtlizer and writes the results 
#'into a specified (or default) file.
#'
#'@param query The qtlizer query.
#'@param outputFile (optional) The name of the output file.
#'@return Response goes directly into the output file.
#'@examples qtfun("rs4284742")
#'qtfun("rs4284742", "outputFile.txt")
#'@importFrom utils write.table
#'@export
qtfun <- function(query, outputFile=of_default){
    #Note: in the current version of Qtlizer, queries including 
    #gene identifier and chromosomal positions
    #of variants taker longer than if using rsids only

    of_default <- "defaultFile.txt"
    output_file <- outputFile
    q <- query
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

    write.table(meta, file=output_file, quote = FALSE, append=FALSE,
        row.names = FALSE, col.names = FALSE)

    write.table(gsub(", ", "\t",toString(header)), file=output_file, 
        quote = FALSE,  append=TRUE, 
        row.names = FALSE, col.names = FALSE)

    write.table(d, file=output_file, sep="\t", quote = FALSE, 
        append=TRUE, row.names = FALSE, col.names = FALSE)

}
