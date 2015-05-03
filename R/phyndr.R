##' Number of possible distinct trees that can be generated from a
##' phyndr set.
##' @title Number of distinct trees
##' @param phy A phyndr phylogeny
##' @export
phyndr_n_distinct <- function(phy) {
  prod(viapply(phy$clades, length))
}
