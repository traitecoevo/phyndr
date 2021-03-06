% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/phyndr_taxonomy.R
\name{phyndr_taxonomy}
\alias{phyndr_genus}
\alias{phyndr_taxonomy}
\title{Phyndr taxonomic}
\usage{
phyndr_taxonomy(phy, data_species, taxonomy)

phyndr_genus(phy, data_species)
}
\arguments{
\item{phy}{An ape phylogeny}

\item{data_species}{A vector of species names for which we have
trait data.  Species names in both the tree and in this vector
must be separated with underscores, not with spaces.}

\item{taxonomy}{A data.frame with taxonomic information.  Row
names must be present and must list every species in \code{phy}
and every species in \code{data_species}.  One or more columns
must be present; the first column is the lowest (finest) taxonomic
grouping and the last column is the highest (coarsest) taxonomic
grouping.  The names are arbitrary but will be used in creating
mangled names in the resulting phylogeny.}
}
\description{
Taxonomic method of phyndr that works with generalised sets of
taxonomic information.  Requires a nested set of taxonomic classes
(e.g, genus, family, order, etc) but does not assume that these
classes are necessarily monophyletic.  \code{phyndr_genus} does
this for the genus level only but attempts to automatically detect
genera from the tree (assuming that tips are all genus/species
pairs, with genus and species separated by either an underscore or
space).
}
\details{
The algorithm (not including recursion and substitute whatever
taxonomic level for genus).

1: drop genera if there is a species match for that genus, but
don't drop the actual matches.

2: work out which genera can be collapsed to a single tip due to
monophyly.

2a. For each genus, determine if they are monophyletic

2b. Then, for genera that are not monophyletic determine which can
be made monophyletic by dropping groups that are not represented
in the data set.

2c. Collapse each genus down, dropping only genera that are
required to achieve monophyly.

3. For each collapsed node we'll mangle the name to "genus::name"
and then make a list of suitable species in the tree and data set;
for now stored as \code{clades}.
}

