#!/bin/sh -v
git checkout lib
cake build
cake build:parser
