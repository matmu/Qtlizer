.onLoad <- function(libname, pkgname){
  packageStartupMessage("
  ---------
  
  For example usage please run: vignette('Qtlizer')
  
  Web-based GUI: http://genehopper.de/qtlizer
  Documentation: http://genehopper.de/help#qtlizer_docu
  Github Repo: https://github.com/matmu/Qtlizer
  
  Citation appreciated:
  Munz M et al. (2020) Qtlizer: comprehensive QTL annotation of GWAS results. Scientific Reports. doi:10.1038/s41598-020-75770-7
  Munz M. et al. (2015) Multidimensional gene search with Genehopper. Nucleic Acids Res. doi:10.1093/nar/gkv511

  Support me: https://matthiasmunz.de/en/thanks/

  ---------", domain = NULL, appendLF = TRUE)
}
