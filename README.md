# phyndr

[![Build Status](https://travis-ci.org/richfitz/phyndr.png?branch=master)](https://travis-ci.org/richfitz/phyndr)

Biologists are increasingly using curated, public data sets to conduct phylogenetic comparative analyses. Unfortunately, there is often a mismatch between species for which there is phylogenetic data and those for which other data is available. As a result, researchers are commonly forced to either drop species from analyses entirely or else impute the missing data.

In this package we have implemented a simple solution to increase the overlap while avoiding potential the biases introduced by imputing data.  If some external topological or taxonomic information is available, this can be used to maximize the overlap between the data and the phylogeny. The algorithms in `phyndr` replace a species lacking data with a species  that has data. This swap can be made because for those two species, all phylogenetic relationships are exactly equivalent.

This project was developed by [Matthew Pennell](www.mwpennell.com), [Rich FitzJohn](http://richfitz.github.io), and [Will Cornwell](http://willcornwell.org).

## Installation
The easiest way to install `phyndr` is to use [`devtools`](https://github.com/hadley/devtools)
```
install.packages("devtools")
devtools::install_github("richfitz/phyndr")
```
Eventually, this will be moved to CRAN but for now it is only available on github.
