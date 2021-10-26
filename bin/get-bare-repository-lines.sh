#!/bin/bash
#Created by Sam Gleske
#Tue Oct 26 17:03:28 EDT 2021
#DESCRIPTION:
#    Walks through a directory containing an archive of bare Git repositories.
#    It will output the repository name, if it has Jervis integration, aand how
#    many lines of code.
#NOTE:
#    You can further restrict lines  of code to file types by setting the
#    environment variable SOURCE_FILE_TYPES

export PATH=/usr/local/bin:"$PATH"
cd "$1"
for x in *.git;do
  (
    cd "$x"
    echo "$(get-repo-name.sh),$(is-jervis-repo.sh),$(get-repository-lines-added.sh "${SOURCE_FILE_TYPES:-}")"
  )
done
