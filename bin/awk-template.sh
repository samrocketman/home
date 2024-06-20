#!/bin/bash
# Created by Sam Gleske
# Wed Jun 19 10:34:56 AM EDT 2024
# Pop!_OS 22.04 LTS
# Linux 6.6.10-76060610-generic x86_64
# GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)
# DESCRIPTION
#     Substitute file templates that need inline contents from other files.
#
# TEMPLATE USAGE
#     Within a file add a line like the following
#
#         # AWK /path/to/file some description of file
#
#     The above line will be replaced with the contents of the /path/to/file
#     and indenting will be preserved.
#
# USAGE
#     Stream substitution:
#
#         awk-template.sh < /some/template > /write/out/file
#
#     Multiple file substitution where the files contain .awk-template in the
#     name.
#
#         awk-template.sh somefile.awk-template another-file.awk-template.yaml
set -eo pipefail
# Substitutes a stream with an awk template.

if type -P gawk; then
  awk() { gawk "$@"; }
fi

awk_script() {
cat <<'EOF'
$1 == "#" && $2 == "AWK" {
  spaces = $0
  gsub("^[^ \t].*$", "", spaces)
  cmd = "cat "$3
  while(cmd | getline) {
    print spaces$0
  }
  next
};
{
  print $0
}
EOF
}

substitute_with_awk() {
  awk "$(awk_script)"
}

stderr() {
  if [ "$#" -gt 0 ]; then
    echo "$*" >&2
  else
    cat >&2
  fi
}

if [ "$#" -gt 0 ]; then
  # check args
  errors=0
  for x in "$@"; do
    if [ ! -f "$x" ]; then
      stderr "ERROR: '$x' does not exist."
      errors="$((errors + 1))"
    fi
    if [ "$x" = "${x/.awk-template/}" ]; then
      stderr "ERROR: '$x' must contain '.awk-template' in the file name."
      errors="$((errors + 1))"
    fi
  done
  if [ "$errors" -gt 0 ]; then
    stderr "$errors errors were encountered."
    exit 1
  fi
  for x in "$@"; do
    substitute_with_awk < "$x" > "${x/.awk-template/}"
  done
else
  substitute_with_awk
fi
