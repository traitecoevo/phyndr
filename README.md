# phyndr

[![Build Status](https://travis-ci.org/richfitz/phyndr.png?branch=master)](https://travis-ci.org/richfitz/phyndr)

# Algorithms

## Topological tree

All nodes (including tips) can be "complete" or "incomplete"; incomplete nodes are nodes that do not include data that maps *directly* to a species in the chronogram, while complete nodes do.  This is because we don't swap out species that have trait data, even if they are swappable (we are not trying to generate *all possible* sets of mappings, but simply use as much trait data as possible).

All nodes (including tips) have a "candidate set" of possible tips; these are species with trait data that can go with a given tip.  We store these at nodes where we might prune the tree down to that node.

* Drop all species from the chronogram that are not in either the data or in the topological tree as these tips are not saveable.
* Drop species from the topological tree that are not in the data or the chronogram as they are not informative.
* Flag all tips that have trait data as "complete", and all other tips and nodes as "incomplete".
* Initialise a "candidate set" for each tip and internal node;
  - for tips that have data, the candidate set is the species name
  - for tips without data, the candidate set is the clade within the topo tree that includes the tip and does not include any other species in the chronogram
* In post-order traversal, for each node:
  - if any descendant tip/node is complete then this node is complete; the candidate set remains empty.
  - otherwise:
    - compute the descendants of this node within the chronogram
    - compute the MRCA of these descendants in the topo tree
    - compute the descendants of that node within the topo tree
    - if any topo descendant is complete, label this node complete
    - otherwise grow the candidate set to include the descendant nodes candidate set, and then clear the descendant node candidate sets.
  - This process leaves all species that can be used (are in the union of the chronogram and the data set) in exactly one candidate set, and every node will be complete.
* Drop all tips with an empty candidate set
