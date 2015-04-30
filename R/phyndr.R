##' Most simple minded version of phyndr that works on genera only
##'
##' The algorithm:
##'
##' 1: drop genera if there is a species match for that genus, but
##' don't drop the actual matches.
##'
##' 2: work out which genera can be collapsed to a single tip due to
##' monophyly.
##'
##' 2a. For each genus, determine if they are monophyletic
##'
##' 2b. Then, for genera that are not monophyletic determine which can
##' be made monophyletic by dropping groups that are not represented
##' in the data set.
##'
##' 2c. Collapse each genus down, dropping only genera that are
##' required to achieve monophyly.
##'
##' 3. For each collapsed node we'll mangle the name to "genus::name"
##' and then make a list of suitable species in the tree and data set;
##' for now stored as \code{clades}.
##'
##' @title Phyndr genus
##' @param phy An ape phylogeny
##' @param data_species A vector of species names for which we have
##' trait data.  Species names in both the tree and in this vector
##' must be separated with underscores, not with spaces.
##' @export
phyndr_genus <- function(phy, data_species) {
  phy_genus <- split_genus(phy$tip.label)
  data_genus <- split_genus(data_species)

  ## Drop genera if there is a species match for that genus, but don't
  ## drop the actual matches.
  match_s <- phy$tip.label %in% data_species
  match_g <- phy_genus %in% unique(phy_genus[match_s])
  to_drop <- match_g & !match_s

  phy2 <- drop_tip(phy, phy$tip.label[to_drop])

  ## These are genera in the tree which did not match any species:
  phy_genus_msg <- unique(phy_genus[!match_g])

  ## Of these, these are the ones that have no data, so we don't want to
  ## go crazy with them.
  phy_genus_msg_nodata <- setdiff(phy_genus_msg, data_genus)
  ## and ones with data:
  phy_genus_msg_data <- intersect(phy_genus_msg, data_genus)

  ## Test missing genera to detemine which are monophyletic:
  ## TODO: this is a logical and should be a character
  phy_genus_msg_data_mono <-
    vlapply(phy_genus_msg_data, is_monophyletic_group, phy_genus, phy)

  ## Then, of the ones that aren't, which can be fixed?
  check <- phy_genus_msg_data[!phy_genus_msg_data_mono]
  problems <- lapply(check, find_paraphyletic, phy_genus, phy)
  can_fix <- vlapply(problems, function(x) all(x %in% phy_genus_msg_nodata))
  phy_genus_msg_data_fixable <- check[can_fix]

  ## Then, of the things with no data and which we don't drop above
  phy_genus_msg_nodata_mono <- logical(length(phy_genus_msg_nodata))
  names(phy_genus_msg_nodata_mono) <- phy_genus_msg_nodata
  check <- setdiff(phy_genus_msg_nodata, problems)
  phy_genus_msg_nodata_mono[check] <-
    vlapply(check, is_monophyletic_group, phy_genus, phy)

  genera_collapse <- c(names(which(phy_genus_msg_data_mono)),
                       phy_genus_msg_data_fixable,
                       names(which(phy_genus_msg_nodata_mono)))
  genera_drop <- unname(unlist(problems[can_fix]))

  tmp <- split(phy$tip.label, phy_genus)
  to_drop <- c(unlist(lapply(tmp[genera_collapse],
                             function(x) x[-1]), use.names=FALSE),
               unlist(tmp[genera_drop], use.names=FALSE))

  relabel <- vcapply(tmp[genera_collapse], function(x) x[[1]])
  names(relabel) <- sprintf("genus::%s", names(relabel))

  stopifnot(all(to_drop %in% phy2$tip.label))

  phy2 <- drop_tip(phy2, to_drop)
  phy2$tip.label[match(relabel, phy2$tip.label)] <- names(relabel)

  ## Now, assemble the list of plausible matches:
  tmp <- split(data_species, data_genus)
  clades <- tmp[sub("^genus::", "", names(relabel))]
  names(clades) <- names(relabel)

  phy2$clades <- clades
  class(phy2) <- c("phyndr", class(phy2))
  phy2
}

## Generalise the approach a bit by using a set of taxonomic lookups.
## This will replace the above function with something that
## *generates* the taxonomy by assuming genera if it's not given/is
## NULL.
##
## There are two sources of data needed here: one is the nested set of
## taxonomy (e.g., genus/family/order) and the other is to connect
## from the *species names* to genus.
##
## Assumption is that the rownames of taxonomy includes all species
## names that are in phy and data_species, then each column we have
## increasing taxonomic nesting.

##' Taxonomic method of phyndr that works with generalised sets of
##' taxonomic information.  Requires a nested set of taxonomic classes
##' (e.g, genus, family, order, etc) but does not assume that these
##' classes are necessarily monophyletic.
##' @title Phyndr taxonomic
##' @param phy An ape phylogeny
##' @param data_species A vector of species names for which we have
##' trait data.  Species names in both the tree and in this vector
##' must be separated with underscores, not with spaces.
##' @param taxonomy A data.frame with taxonomic information.  Row
##' names must be present and must list every species in \code{phy}
##' and every species in \code{data_species}.  One or more columns
##' must be present; the first column is the lowest (finest) taxonomic
##' grouping and the last column is the highest (coarsest) taxonomic
##' grouping.  The names are arbitrary but will be used in creating
##' mangled names in the resulting phylogeny.
##' @export
phyndr_taxonomy <- function(phy, data_species, taxonomy) {
  ## TODO: check
  ##   - taxonomy is a data.frame
  ##   - has row labels
  ##   - has unique column labels
  ##   - has at least one column
  ##   - has a tree structure?
  msg <- setdiff(phy$tip.label, rownames(taxonomy))
  if (length(msg) > 0L) {
    stop("Species in phy missing taxonomic information: ",
         pastec(msg))
  }
  msg <- setdiff(data_species, rownames(taxonomy))
  if (length(msg) > 0L) {
    stop("Species in data_species missing taxonomic information: ",
         pastec(msg))
  }

  ## This is the recursive exit condition:
  if (ncol(taxonomy) < 1L) {
    return(phy)
  }
  ## Nothing can be done here:
  if (all(phy$tip.label %in% data_species)) {
    return(phy)
  }

  phy_g <- taxonomy[phy$tip.label, 1, drop=TRUE]
  dat_g <- taxonomy[data_species,  1, drop=TRUE]

  ## I don't think we want to run the whole way down the taxonomy
  ## straight away here.
  ##
  ## If there are unmatched species in the same genus as things that
  ## have data already, those get discarded from the tree as there's
  ## nothing that we can do.  We do keep other genera though, even if
  ## they're in a family that we have matches for so that implies that
  ## we don't roll back more than the first taxonomic grouping.
  match_s <- phy$tip.label %in% data_species

  ## On the second way around here we have to be more careful; most
  ## tips are actually ok by now.
  ## This one is wrong because it's against the wrong tree.  Here we
  ## need to know what group things belong to.  That means updating
  ## all the book-keeping so that's a pain.  Easiest way would be to
  ## append rows to the table and rematch.
  match_g <- phy_g %in% unique(phy_g[match_s])
  to_drop <- match_g & !match_s

  phy2 <- drop_tip(phy, phy$tip.label[to_drop])

  ## These are groups in the tree which did not match any species:
  phy_g_msg <- unique(phy_g[!match_g])

  ## Of these, these are the ones that have no data, so we don't want to
  ## go crazy with them.
  phy_g_msg_nodata <- setdiff(phy_g_msg, dat_g)
  ## and ones with data:
  phy_g_msg_data <- intersect(phy_g_msg, dat_g)

  ## Test missing genera to detemine which are monophyletic:
  phy_g_msg_data_is_mono <-
    vlapply(phy_g_msg_data, is_monophyletic_group, phy_g, phy)
  phy_g_msg_data_mono <- phy_g_msg_data[phy_g_msg_data_is_mono]

  ## Then, of the ones that aren't, which can be fixed?
  check <- phy_g_msg_data[!phy_g_msg_data_is_mono]
  problems <- lapply(check, find_paraphyletic, phy_g, phy)
  can_fix <- vlapply(problems, function(x) all(x %in% phy_g_msg_nodata))
  phy_g_msg_data_fixable <- check[can_fix]

  ## Then, of the things with no data and which we don't drop above
  phy_g_msg_nodata_is_mono <- logical(length(phy_g_msg_nodata))
  names(phy_g_msg_nodata_is_mono) <- phy_g_msg_nodata
  check <- setdiff(phy_g_msg_nodata, problems)
  phy_g_msg_nodata_is_mono[check] <-
    vlapply(check, is_monophyletic_group, phy_g, phy)
  phy_g_msg_nodata_mono <- phy_g_msg_nodata[phy_g_msg_nodata_is_mono]

  g_collapse <- c(phy_g_msg_data_mono,
                  phy_g_msg_data_fixable,
                  phy_g_msg_nodata_mono)
  g_drop <- unname(unlist(problems[can_fix]))

  tmp <- split(phy$tip.label, phy_g)
  to_drop <- c(unlist(lapply(tmp[g_collapse],
                             function(x) x[-1]), use.names=FALSE),
               unlist(tmp[g_drop], use.names=FALSE))

  relabel <- vcapply(tmp[g_collapse], function(x) x[[1]])
  names(relabel) <- sprintf("%s::%s", names(taxonomy)[[1]], names(relabel))

  taxonomy_extra <- taxonomy[match(g_collapse, taxonomy[[1]]), -1, drop=FALSE]
  rownames(taxonomy_extra) <- names(relabel)
  if (nrow(taxonomy_extra) > 0L) {
    taxonomy2 <- rbind(taxonomy[, -1, drop=FALSE], taxonomy_extra)
  } else {
    taxonomy2 <- taxonomy[, -1, drop=FALSE]
  }

  phy2 <- drop_tip(phy2, to_drop)
  phy2$tip.label[match(relabel, phy2$tip.label)] <- names(relabel)

  ## Now, assemble the list of plausible matches:
  tmp <- split(data_species, dat_g)
  clades <- setNames(tmp[g_collapse], names(relabel))

  data_species2 <- c(data_species,
                     names(clades)[viapply(clades, length) > 0L])

  phy2$clades <- c(phy2$clades, clades)
  phy2$clades <- phy2$clades[names(phy2$clades) %in% phy2$tip.label]

  if (!inherits(phy2, "phyndr")) {
    class(phy2) <- c("phyndr", class(phy2))
  }

  ## Let's recurse!
  phyndr_taxonomy(phy2, data_species2, taxonomy2)
}
