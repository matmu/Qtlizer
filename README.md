# Qtlizer

This package offers the possibility to send requests to Qtlizer. Qtlizer comments on lists of common small variants and genes in humans with associated changes in gene expression using the most comprehensive database of published quantitative trait loci (QTLs) to date.

The user can use a function to make requests to Qtilzer and receives an output file with the requested data. 

##Installation
For example use the 
```
install_github()
```
command provided by the devtools package.

##Usage
Simply call the function with the query. The output will be written into an output file. 

```R
qtfun('rs4284742')
```

The name of the output file can also be specified:

```R
qtfun('rs4284742', 'out.txt')
```

##Authors and acknoledgment

##License


