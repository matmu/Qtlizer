.onLoad <- function(libname, pkgname){
  packageStartupMessage("
  ---------
  
  For example usage please run: vignette('Qtlizer')
  
  Web-based GUI: http://genehopper.de/qtlizer
  Documentation: http://genehopper.de/help#qtlizer_docu
  Github Repo: https://github.com/matmu/Qtlizer
  
  Citation appreciated:
  Munz M, Wohlers I, Simon E, Busch H, Schaefer A* and Erdmann J* (2018) Qtlizer: comprehensive QTL annotation of GWAS results. bioRxiv DOI: https://doi.org/10.1101/495903
  
  ---------", domain = NULL, appendLF = TRUE)
}