split_genus <- function(str) {
  str_split <- strsplit(str, "[_ ]+")
  vcapply(str_split, "[[", 1L)
}

is_monophyletic_group <- function(group, table, phy) {
  is.monophyletic(phy, phy$tip.label[table == group])
}

## Find the things that make a group non-monophyletic
##' @importFrom diversitree get.descendants
find_paraphyletic <- function(group, table, phy) {
  tips <- phy$tip.label[table == group]
  mrca <- ape::getMRCA(phy, tips)
  desc <- diversitree::get.descendants(mrca, phy, tips.only=TRUE)
  setdiff(table[desc], group)
}
