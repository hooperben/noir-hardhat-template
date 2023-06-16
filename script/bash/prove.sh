#!/bin/sh

circuitsDir="circuits/$1"

cd "$circuitsDir"
nargo prove "$1" 
