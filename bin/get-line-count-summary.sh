#!/bin/bash

#Created by Sam Gleske
#Tue Oct 26 17:03:28 EDT 2021
#DESCRIPTION:
#    Summarize line count results from a bare repository archive.

awk -F, $'
BEGIN {
  x=0;y=0
};
{
  x+=$3
};
$2 == "yes" {
  y+=$3
};
END {
  printf "%s %\'d\\n%s %\'d\\n", "Total LoC:", x, "Jervis projects LoC:", y
}'
