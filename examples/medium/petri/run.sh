#!/bin/sh
echo cleaning the petri box..
rm -Rf box/*
mkdir -p box
echo inseminating..
cp bootstrap.egg.js box/0_0_0_0.egg.js
echo warming system..
coffee petri.coffee
