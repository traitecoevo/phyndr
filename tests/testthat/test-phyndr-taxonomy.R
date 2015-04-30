context("phyndr")

## This is how the data were generated:
if (FALSE) {
  families <- c("Araucariaceae", "Cephalotaxaceae", "Cupressaceae",
                "Pinaceae", "Podocarpaceae", "Taxaceae")
  taxize::tpl_get("tpl", families)

  files <- dir("tpl", full.names=TRUE)
  dat <- do.call("rbind", lapply(files, read.csv, stringsAsFactors=FALSE))
  dat <- dat[!duplicated(paste(dat$Genus, dat$Species)),
             c("Species", "Genus", "Family")]
  write.csv(dat[c("Species", "Genus", "Family")], "pinales.csv",
            row.names=FALSE)

  ## A set of species to use:
  set.seed(1)
  i <- sort(sample(nrow(dat), 60))
  extra <- match(c("Larix_griffithii", "Tsuga_jeffreyi"), dat$gs)
  i <- sort(c(i, extra))
  writeLines(dat$gs[i], "pinales_sub.txt")
}

## Not really a test, but it works!
test_that("regression", {
  phy <- read.tree("pinales.tre")
  data_species <- readLines("pinales_sub.txt")

  phy2 <- phyndr_genus(phy, data_species)

  expect_that(phy2, is_a("phyndr"))
  expect_that(phy2, is_a("phylo"))

  expect_that(length(phy2$clades[["genus::Tsuga"]]), equals(1))
  expect_that(length(phy2$clades[["genus::Larix"]]), equals(1))
  expect_that(length(phy2$clades[["genus::Cedrus"]]), equals(0))

  expect_that(all(names(phy2$clades) %in% phy2$tip.label), is_true())

  expect_that(length(phy2$tip.label), equals(24))

  if (FALSE) {
    col <- setNames(rep("black", length(phy2$tip.label)), phy2$tip.label)
    col[names(phy2$clades)] <-
      ifelse(viapply(phy2$clades, length) > 0L, "blue", "red")
    plot(phy2, type="fan", no.margin=TRUE, cex=.5, tip.color=col)
  }
})

test_that("taxonomy", {
  phy <- read.tree("pinales.tre")
  data_species <- readLines("pinales_sub.txt")

  dat <- read.csv("pinales.csv", stringsAsFactors=FALSE)
  rownames(dat) <- paste(dat$Genus, dat$Species, sep="_")
  dat <- dat[c("Genus", "Family")]

  ## Some species that aren't in the lookup but are in the tree:
  extra <- setdiff(phy$tip.label, rownames(dat))
  extra_genus <- split_genus(extra)
  tmp <- dat[match(extra_genus, dat$Genus), ]
  rownames(tmp) <- extra
  dat2 <- rbind(dat, tmp)

  phy2 <- phyndr_taxonomy(phy, data_species, dat2)
  expect_that(length(phy2$tip.label), equals(20))
  expect_that(length(phy2$clades), equals(2))
})
