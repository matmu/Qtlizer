# Qtlizer

This package offers the possibility to send requests to Qtlizer. Qtlizer comments on lists of common small variants and genes in humans with associated changes in gene expression using the most comprehensive database of published quantitative trait loci (QTLs) to date.

The user can use a function to make requests to Qtilzer and receives an output file with the requested data. 

## Installation
For example use the 
```
install_github()
```
command provided by the devtools package.

## Usage
Simply call the function with the query. The output will be written into an output file. 

```R
qtfun('rs4284742')
```

The name of the output file can also be specified:

```R
qtfun('rs4284742', 'out.txt')
```

## Authors and acknowledgments

## Citation
Please cite the following article when using `Qtlizer`:

**Munz M**, Wohlers I, Simon E, Busch H, Schaefer A<sup>\*</sup> and Erdmann J <sup>\*</sup> (2018) Qtlizer: comprehensive QTL annotation of GWAS results. ***bioRxiv***

[![](https://img.shields.io/badge/doi-https%3A%2F%2Fdoi.org%2F10.1101%2F495903%20-green.svg)](https://doi.org/10.1101/495903)
[![](https://img.shields.io/badge/Altmetric-17-green.svg)](https://www.altmetric.com/details/52777590)

## License


