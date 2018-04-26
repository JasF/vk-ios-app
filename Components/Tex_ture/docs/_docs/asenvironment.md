---
title: A_SEnvironment
layout: docs
permalink: /docs/asenvironment.html
prevPage: asvisibility.html
nextPage: asrunloopqueue.html
---

`A_SEnvironment` is a performant and scalable way to enable upward and downward propagation of information throughout the node hierarchy. It stores a variety of critical “environmental” metadata, like the trait collection, interface state, hierarchy state, and more. 

Any object that conforms to the `<A_SEnvironment>` protocol can propagate specific states defined in an `A_SEnvironmentState` up and/or down the A_SEnvironment tree. To define how merges of States should happen, specific merge functions can be provided.

Compared to UIKit, this system is very efficient and one of the reasons why nodes are much lighter weight than UIViews. This is achieved by using simple structures to store data rather than creating objects. For example, `UITraitCollection` is an object, but `A_SEnvironmentTraitCollection` is just a struct. 

This means that whenever a node needs to query something about its environment, for example to check its [interface state](http://texturegroup.org/docs/intelligent-preloading.html#interface-state-ranges), instead of climbing the entire tree or checking all of its children, it can go to one spot and read the value that was propogated to it. 

A key operating principle of A_SEnvironment is to update values when new subnodes are added or removed. 

A_SEnvironment powers many of the most valuable features of Tex_ture. **There is no public API available at this time.**
