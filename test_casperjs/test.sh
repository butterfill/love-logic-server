#!/bin/bash

echo slimerjs ex_create
casperjs --engine=slimerjs test ex_create.coffee 
echo
echo ---
echo phantomjs ex_create
casperjs test ex_create.coffee 

echo 
echo ---
echo slimerjs ex_TorF
casperjs --engine=slimerjs test ex_TorF.coffee 
echo 
echo ---
echo phantomjs ex_TorF
casperjs test ex_TorF.coffee 

echo 
echo ---
echo slimerjs : casperjs --engine=slimerjs test ex_tt.coffee 
casperjs --engine=slimerjs test ex_tt.coffee 
echo 
echo ---
echo phantomjs : casperjs test ex_tt.coffee 
casperjs test ex_tt.coffee 

