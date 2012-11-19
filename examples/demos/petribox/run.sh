#!/bin/sh
echo cleaning the petri box..
mkdir -p box
rm -Rf box/*
coffee petri.coffee
