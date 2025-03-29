#!/bin/bash
# Created by Sam Gleske
# MIT Licensed Copyright 2025 Sam Gleske
# https://github.com/samrocketman/home/blob/main/bin/codeowners.sh
# Wed Mar 24 21:16:02 EDT 2025
# Pop!_OS 22.04 LTS
# Linux 6.9.3-76060903-generic x86_64
# GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)
# git version 2.34.1
# mawk: 1.3.4 (awk version)
# yq (https://github.com/mikefarah/yq/) version v4.45.1
# codeowners 1.2.1 (https://github.com/hmarr/codeowners)
#
# DESCRIPTION
#   This script will produce a human and machine readable version of CODEOWNERS
#   ownership of a project.  It relies on `yq` and `codeonwers` CLI.
#
#   Converts output of codeowners CLI into YAML.  The YAML has two root keys.
#     - overall_approvers (optional; commented out if no overall approvers)
#     - codeowners_by_file (possibly null if no files provided)
#
#   This script will create a codeowners.yaml file and determine overall
#   approvers.
#
#   This script will exit non-zero if no CODEOWNERS is available.  This is the
#   behavior of codeowners CLI.
#
# EXAMPLES
#
#   Get CODEOWNERS of current branch compared to origin/main
#     codeowners.sh
#
#   Get files to evaluate with CODEOWNERS from stdin
#     git diff --name-only HEAD~1 HEAD | bin/codeowners.sh -
#
#   Manually provide comparison ref for CODEOWNERS instead of origin/main.
#     codeowners.sh upstream/main
#     CODEOWNERS_REMOTE=upstream/main codeowners.sh
#
#   Evaluate specific files or paths for CODEOWNERS ownership.
#     codeowners.sh "some file" "another file"


set -euo pipefail

get_remote() {
  if [ -n "${CODEOWNERS_REMOTE:-}" ]; then
    echo "${CODEOWNERS_REMOTE}"
  elif [ -n "${CHANGE_TARGET:-}" ]; then
    echo "origin/${CHANGE_TARGET}"
  elif git show-ref refs/remotes/origin/main &> /dev/null; then
    echo "origin/main"
  elif git show-ref refs/remotes/origin/master &> /dev/null; then
    echo "origin/master"
  else
    echo 'ERROR: set CODEOWNERS_REMOTE to git ref for comparison.' >&2
    echo 'Attempted to detect origin/{main,master} but no refs found.' >&2
    exit 1
  fi
}

codeowners_awk_script() {
cat <<'EOF'
BEGIN {
    FS="\t"
    print "codeowners_by_file:"
};
{
    print "  - file: \""$1"\"\n    reviewers:";
    for(i=2; i<=NF; i++) {
        print "      - \""$i"\"";
    }
}
EOF
}

get_all_approvers_from_yaml() {
  yq '.codeowners_by_file[].reviewers | .[]' \
    | LC_ALL=C sort -u \
    | grep -vF '(anyone_with_write_access)'
}

# This searches codeowners.yaml for overall approvers.
approver_can_approve_every_file() {
  local anyone_with_write_access approver_can_approve can_approve_all_files
  approver_can_approve='(.reviewers | any_c(. == "'"$1"'"))'
  anyone_with_write_access='(.reviewers | any_c(. == "(anyone_with_write_access)"))'
  can_approve_all_files="all_c(${approver_can_approve} or ${anyone_with_write_access})"

  # For each file, check if the provided approve can approver everything.
  # If so, the approver is considered an "overall approver".
  yq ".codeowners_by_file | ${can_approve_all_files}" "$TMP_DIR"/codeowners.yaml
}

get_codeowners_yaml_with_overall_approvers() {
  local overall_approvers
  overall_approvers=()
  while read -r approver; do
    if [ "$(approver_can_approve_every_file "$approver")" = true ]; then
      overall_approvers+=( "$approver" )
    fi
  done <<< "$(get_all_approvers_from_yaml < "$TMP_DIR"/codeowners.yaml)"
  if [ -n "${overall_approvers:-}" ]; then
    echo 'overall_approvers:' > "$TMP_DIR"/overall.yaml
    local x
    for x in "${overall_approvers[@]}"; do
      echo "  - ${x}" >> "$TMP_DIR"/overall.yaml
    done
  else
    echo '# overall_approvers: There are no overall approvers from CODEOWNERS.' > "$TMP_DIR"/overall.yaml
  fi
  cat "$TMP_DIR"/overall.yaml "$TMP_DIR"/codeowners.yaml
}

changed_files() {
  if [ "$read_stdin" = true ]; then
    cat
  else
    git diff \
      --name-only \
      "$(git merge-base "$(get_remote)" HEAD)" HEAD
  fi
}

codeowners_to_tsv() {
  # https://github.com/hmarr/codeowners/blob/b0f609d21eb672b5cb2973f47a80210185102504/cmd/codeowners/main.go#L117
  # codeowners always has a minimum of two spaces between file and groups
  # codeowners does not offer alternate formatting
  # this function is to account for spaces in file names... hopefully, there are
  # no files with two spaces in their name...
  sed 's/   *\([@(]\)/\t\1/g' | awk 'BEGIN {FS="\t";OFS="\t"};{gsub(" ", "\t", $2);}{print $0}'
}

codeowners_to_yaml() {
  sed 's/(unowned)/(anyone_with_write_access)/g' | \
  codeowners_to_tsv | awk "$(codeowners_awk_script)"
}

#
# MAIN
#
export CODEOWNERS_REMOTE TMP_DIR read_stdin
read_stdin=false
TMP_DIR="$(mktemp -d)"
trap '[ ! -d "$TMP_DIR" ] || rm -r "$TMP_DIR"' EXIT
if [ "$#" -gt 0 ] && [ "$1" = '-' ]; then
  read_stdin=true
  shift
fi
if [ "$#" -gt 0 ] && git show-ref "$1" &> /dev/null; then
  CODEOWNERS_REMOTE="$1"
  shift
fi
(
  if [ "$#" -eq 0 ]; then
    changed_files | tr '\n' '\0' | xargs -0 codeowners | codeowners_to_yaml
  else
    codeowners "$@" | codeowners_to_yaml
  fi
) > "$TMP_DIR"/codeowners.yaml
get_codeowners_yaml_with_overall_approvers
