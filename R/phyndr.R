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
