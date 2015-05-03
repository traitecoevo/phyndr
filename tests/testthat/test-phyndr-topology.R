context("phyndr_topology")

test_that("phyndr_topology", {
  phy <- read.tree("Conifer-timetree.tre")
  topology <- read.tree("pinales_topotree.tre")

  set.seed(1)
  keep <- sample(phy$tip.label, 100)
  phy <- drop_tip(phy, setdiff(phy$tip.label, keep))

  set.seed(1)
  data_species <- sample(union(phy$tip.label, topology$tip.label), 200)

  res <- phyndr_topology(phy, data_species, topology)
  expect_that(length(res$tip.label), equals(44))

  expect_that(res$clades, is_a("list"))
  expect_that(phyndr_n_distinct(res), equals(208))
})
