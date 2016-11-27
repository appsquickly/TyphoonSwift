#!/bin/bash


rm -rf Packages/*

swift package generate-xcodeproj

find ./Packages/ -name .git | xargs rm -rf
