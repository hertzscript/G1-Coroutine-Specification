#!/bin/bash
cd ./src
for mdfile in *.md
do
	touch "../dist/${mdfile%.md}.html"
	npm run --silent spec-md ./src/${mdfile} > "../dist/${mdfile%.md}.html"
done