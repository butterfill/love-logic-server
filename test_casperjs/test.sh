#!/bin/bash

echo casperjs test page_courses.coffee --engine=$1
casperjs test ./page_courses.coffee --engine=$1

echo 
echo ---
echo casperjs test ex_q.coffee --engine=$1
casperjs test ex_tt.coffee --engine=$1

echo 
echo ---
echo casperjs --engine=$1 test ex_create.coffee 
casperjs test ex_create.coffee --engine=$1 

echo 
echo ---
echo casperjs test ex_TorF.coffee --engine=$1
casperjs test ex_TorF.coffee --engine=$1

echo 
echo ---
echo casperjs test ex_tt.coffee --engine=$1
casperjs test ex_tt.coffee --engine=$1

echo 
echo ---
echo casperjs test visit_key_pages.coffee --engine=$1
casperjs test visit_key_pages.coffee --engine=$1
