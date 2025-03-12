#!/usr/bin/env python3
# Created by Sam Gleske
# MIT Licensed
#
# Converts shellcheck JSON feedback into a markdown comment with hyperlinks to
# GitHub code.
#
# Environment variables which change the behavior of this script.
#     ERROR_LEVEL (set value between 1-4)
#
# ERROR_LEVEL=1 ; exit non-zero only if errors found
# ERROR_LEVEL=2 ; exit non-zero if warnings or errors found
# ERROR_LEVEL=3 ; exit non-zero if warning, info, or error found
# ERROR_LEVEL=4 ; exit non-zero if any findings at all
#
# You can modify the behavior of shellcheck with `.shellcheckrc`.
#     https://github.com/koalaman/shellcheck/blob/d3001f337aa3f7653a621b302261f4eac01890d0/shellcheck.1.md#rc-files
#
# Before running examples set the following environment variables.  Note that
# the CHANGE_URL usually populates from a GitHub pull request within Jenkins so
# this script will auto-trim the PR from the end of the URL.
#     export HEAD_LONG_COMMIT="$(git rev-parse HEAD)"
#     export CHANGE_URL=https://github.com/org/repo/
#
# EXAMPLE for one script and exit non-zero on any shellcheck issue found.
# ERROR_LEVEL=1-4 ; default 1
#
#     shellcheck -fjson setup.sh | ERROR_LEVEL=4 shellcheck-to-markdown.py
#
# EXAMPLE for one script and exit non-zero only on errors found
#
#     shellcheck -fjson somescript.sh | shellcheck-to-markdown.py
#
# EXAMPLE for multiple scripts
#
#     find * -type f -name '*.sh' -print0 | \
#      xargs -0 -n1 -I{} \
#        /bin/bash -c 'shellcheck -f json1 {} | yq '"'"'.comments'"'"' -P | sed "/^\\[\\]\$/d"' | \
#          yq -o json | \
#            shellcheck-to-markdown.py > shellcheck_comment.md


import json
import os
import re
import sys

# error on any shellcheck issues
error_levels = ["error", "warning", "info", "style"]
desired_error_level = int(
    os.getenv("ERROR_LEVEL")
    if os.getenv("ERROR_LEVEL") is not None
    and bool(re.fullmatch("^[1-4]$", os.getenv("ERROR_LEVEL")))
    else "1"
)
error_levels = error_levels[:desired_error_level]

# load shellcheck JSON results
shellcheck_results = json.load(sys.stdin)
if shellcheck_results is None or len(shellcheck_results) == 0:
    print(":white_check_mark: No shellcheck issues found")
    # No feedback found and JSON null means no results returned
    sys.exit(0)

if os.getenv("CHANGE_URL") is None or os.getenv("HEAD_LONG_COMMIT") is None:
    print("ERROR: CHANGE_URL or HEAD_LONG_COMMIT environment variable not defined.")
    sys.exit(1)

see_also = {}
REPO_URL = re.sub("pull/[0-9]+$", "", os.getenv("CHANGE_URL"))
COMMIT = os.getenv("HEAD_LONG_COMMIT")

print(
    """\
# Links to lines

This is feedback surfaced by shellcheck.
"""
)

file = {"name": "", "contents": []}

exit_code = 0
for feedback in shellcheck_results:
    if not isinstance(feedback, dict):
        continue
    if feedback["code"] not in see_also:
        short_desc = (
            feedback["message"][:33]
            if len(feedback["message"]) > 33
            else feedback["message"]
        )
        see_also[feedback["code"]] = (
            "[SC%d](https://www.shellcheck.net/wiki/SC%d) -- `%s`..."
            % (feedback["code"], feedback["code"], short_desc)
        )
    if feedback["file"] != file["name"]:
        file["name"] = feedback["file"]
        with open(feedback["file"], "r") as f:
            file["contents"] = f.readlines()
        print("### %s\n" % file["name"])
    print(
        """\
* [%s line %d](%sblob/%s/%s#L%d) -- `%s`

  ```bash
  %s\
  %s
  ```
          """.strip()
        % (
            feedback["file"],
            feedback["line"],
            REPO_URL,
            COMMIT,
            feedback["file"],
            feedback["line"],
            feedback["message"],
            "  \n".join(file["contents"][feedback["line"] - 1 : feedback["endLine"]]),
            (
                " " * (feedback["column"] - 1)
                + "^"
                + ("-" * (feedback["endColumn"] - feedback["column"] - 2))
                + "^ SC"
                + str(feedback["code"])
                + " ("
                + feedback["level"]
                + "): "
                + feedback["message"]
            ),
        )
    )
    print("")
    if feedback["level"] in error_levels:
        exit_code = 1

print(
    """\
# See also
"""
)

for key, value in sorted(see_also.items(), key=lambda item: item[0]):
    print("* " + value)

sys.exit(exit_code)
