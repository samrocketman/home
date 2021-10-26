#!/bin/bash
#Created by Sam Gleske
#Tue Oct 26 17:03:28 EDT 2021
#DESCRIPTION:
#    Gets the repository name assuming the current working directory is a bare
#    repository.

pwd | sed -e 's#.*/##' -e 's/\.git$//'
