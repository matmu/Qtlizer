.onLoad <- function(libname, pkgname){
  packageStartupMessage("
  ---------
  
  For example usage please run: vignette('Qtlizer')
  
  Web-based GUI: http://genehopper.de/qtlizer
  Documentation: http://genehopper.de/help#qtlizer_docu
  Github Repo: https://github.com/matmu/Qtlizer
  
  Citation appreciated:
  Munz M, Wohlers I, Simon E, Reinberger T, Busch H, Schaefer A and Erdmann J (2020) Qtlizer: comprehensive QTL annotation of GWAS results. Scientific Reports. doi:10.1038/s41598-020-75770-7
  
  ---------", domain = NULL, appendLF = TRUE)
}
