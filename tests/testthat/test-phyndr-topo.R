context("phyndr_topo")

test_that("phyndr_topo", {
  phy <- read.tree("Conifer-timetree.tre")
  topo <- read.tree("pinales_topotree.tre")

  set.seed(1)
  keep <- sample(phy$tip.label, 100)
  phy <- drop_tip(phy, setdiff(phy$tip.label, keep))

  set.seed(1)
  data_species <- sample(union(phy$tip.label, topo$tip.label), 200)

  res <- phyndr_topo(phy, data_species, topo)
  expect_that(length(res$tip.label), equals(44))
})
