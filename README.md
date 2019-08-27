# Qtlizer: comprehensive QTL annotation of GWAS results
[![Twitter](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://twitter.com/intent/tweet?hashtags=Qtlizer&url=https://www.biorxiv.org/content/10.1101/495903v2&screen_name=_matmu)

This package offers the possibility to query the **Qtlizer** web server. **Qtlizer** annotates lists of common small variants and genes in humans with associated changes in gene expression using the most comprehensive database of published quantitative trait loci (QTLs) to date.

The user can use the `get_qtls()` function to make requests to **Qtilzer** and receives a data frame with the requested data. The queries are made with the Genehopper REST API (http://genehopper.de/rest) which can also be used directly by the user.

There is also a **Qtlizer GUI** that can be used (http://genehopper.de/qtlizer). More information about **Qtlizer** and detailed documentation about usage and available datasets can be found at http://genehopper.de/help#qtlizer_docu .

## Installation
```R
devtools::install_github('matmu/Qtlizer')
```

**Please note**: A internet connection is required (HTTP port: 80) in order to install and use the package.

## Usage
Simply call the function `get_qtls()` with your query as argument. The output will be returned as a data frame.

```R
get_qtls('rs4284742 DEFA1')
```
All kind of standard seperators (space, comma, space + comma, ...) are accepted. It is also possible to pass your query with a vector: 

```R
get_qtls(c("rs4284742", "DEFA1"))
```

Accepted query terms are variant and gene identifiers of the form: 

+ Rsid : rs + number e.g. "rs4284742"
+ reference:chr:pos e.g. "hg19:19:45412079" (Allowed references: hg19/GRCh37, hg38/GRCh38; accepted chromosomes are 1-22)
+ Gene symbol consisting of letters and numbers according to  [https://www.genenames.org/about/guidelines/]( https://www.genenames.org/about/guidelines/)


There are also various parameters that can be specified in addition to the query:

+ corr: Linkage disequilibrium based on 1000Genomes Phase 3 European. Optional value between 0.1 and 1. Default 	value is 0.8.

	```R
	get_qtls("rs4284742", 0.6)
	```

+ max_terms: Number of queries made at a time. The default value is 5. It is recommended to not set the value higher than 5. 


	```R
	get_qtls("rs4284742", max_terms = 4)
	```

+ ld_method: There are two methods. Default method is "r2". The other opportunity is to use "dprime".


	```R
	get_qtls("rs4284742", ld_method = "dprime")
	```

If the retained object should be a GenomicRanges::GRanges object than another 
parameter can be used. First set parameter return_obj on "grange". Then the 
reference position can either be the standard value "hg_19" or "hg_38".



```R
get_qtls("rs4284742", return_obj = "grange", ref_version = "hg38")
```

### Column meta information
The column description of the received dataframe can be accessed by calling:

```R
df = get_qtls("rs4284742")
comment(df)
```

### Try out online
If you want to try out the R package online, there is an example **Google Colaboratory project** at

https://colab.research.google.com/drive/1i1sjQHCjaw2wYzVBnXQ9iaghnk-jSU95#scrollTo=5Hi6sCe7SPFb

The link leads you to the project and allows read access. To run the project, make a private copy or open the project in playground mode and sign in to Google. 


## Authors
Matthias Munz [![](https://img.shields.io/twitter/follow/_matmu?label=Follow&style=social)](https://img.shields.io/twitter/follow/_matmu?label=Follow&style=social)\
Julia Remes\
University of Lübeck, Germany


## Citation
Please cite the following article when using **Qtlizer**:

**Munz M**, Wohlers I, Simon E, Busch H, Schaefer A<sup>\*</sup> and Erdmann J <sup>\*</sup> (2018) Qtlizer: comprehensive QTL annotation of GWAS results. ***bioRxiv***

[![](https://img.shields.io/badge/doi-https%3A%2F%2Fdoi.org%2F10.1101%2F495903%20-green.svg)](https://doi.org/10.1101/495903)
[![](https://img.shields.io/badge/Altmetric-17-green.svg)](https://www.altmetric.com/details/52777590)


## License
GNU General Public License v3.0

