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
# ERROR_LEVEL=2 ; exit non-zero if warnings or errors found (this is default)
# ERROR_LEVEL=3 ; exit non-zero if warning, info, or error found
# ERROR_LEVEL=4 ; exit non-zero if any findings at all
#
# You can modify the behavior of shellcheck with `.shellcheckrc`.
#     https://github.com/koalaman/shellcheck/blob/d3001f337aa3f7653a621b302261f4eac01890d0/shellcheck.1.md#rc-files
#
# The following environment variables are auto-detected when running from a git
# repository.  You can override them if needed:
#     HEAD_LONG_COMMIT - defaults to `git rev-parse HEAD`
#     CHANGE_URL - defaults to upstream or origin remote URL converted to HTTPS
#
# Note that CHANGE_URL usually populates from a GitHub pull request within
# Jenkins so this script will auto-trim the PR from the end of the URL.
#
# EXAMPLE for one script and exit non-zero on any shellcheck issue found.
# ERROR_LEVEL=1-4 ; default 2
#
#     shellcheck -fjson setup.sh | ERROR_LEVEL=4 shellcheck-to-markdown.py
#
# EXAMPLE for one script which exits non-zero if errors or warnings found.
#
#     shellcheck -fjson somescript.sh | shellcheck-to-markdown.py
#
# EXAMPLE for multiple scripts.
#
#     find * -type f -name '*.sh' -print0 | \
#      xargs -0 -n1 -I{} \
#        /bin/bash -c 'shellcheck -f json1 {} | yq ".comments" -P | sed "/^\\[\\]\$/d"' | \
#          yq -o json | \
#            shellcheck-to-markdown.py > shellcheck_comment.md
#
# EXAMPLE search repository faster than find for all scripts in git repo.
#
#    git diff --name-only --diff-filter=AM "$(git rev-list --max-parents=0 HEAD)" HEAD '*.sh' | \
#      tr '\n' '\0' | \
#        xargs -0 -n1 -I{} \
#          /bin/bash -c 'shellcheck -f json1 {} | yq ".comments" -P | sed "/^\\[\\]\$/d"' | \
#            yq -o json | \
#              shellcheck-to-markdown.py > shellcheck_comment.md
#
# EXAMPLE really fast only review scripts changed in a pull request.
# Note CHANGE_TARGET is set during Jenkins pull request builds.
#
#    git diff --name-only --diff-filter=AM "$(git merge-base origin/"$CHANGE_TARGET" HEAD)" HEAD '*.sh' | \
#      tr '\n' '\0' | \
#        xargs -0 -n1 -I{} \
#          /bin/bash -c 'shellcheck -f json1 {} | yq ".comments" -P | sed "/^\\[\\]\$/d"' | \
#            yq -o json | \
#              shellcheck-to-markdown.py > shellcheck_comment.md

import json
import os
import re
import subprocess
import sys


def run_git_command(args):
    """Run a git command and return the output, or None if it fails."""
    try:
        result = subprocess.run(
            ["git"] + args,
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def git_remote_url_to_https(git_url):
    """Convert a git remote URL to https://github.com/org/repo format."""
    if git_url is None:
        return None

    # Remove .git suffix if present
    git_url = re.sub(r"\.git$", "", git_url)

    # Handle SSH format: git@github.com:org/repo
    ssh_match = re.match(r"^git@([^:]+):(.+)$", git_url)
    if ssh_match:
        host, path = ssh_match.groups()
        return f"https://{host}/{path}"

    # Handle git:// protocol: git://github.com/org/repo
    git_proto_match = re.match(r"^git://([^/]+)/(.+)$", git_url)
    if git_proto_match:
        host, path = git_proto_match.groups()
        return f"https://{host}/{path}"

    # Handle https:// or http:// - already in correct format
    if re.match(r"^https?://", git_url):
        return git_url

    return None


def get_head_commit():
    """Get HEAD commit hash from environment or git."""
    commit = os.getenv("HEAD_LONG_COMMIT")
    if commit:
        return commit
    return run_git_command(["rev-parse", "HEAD"])


def get_repo_url():
    """Get repository URL from environment or git remotes."""
    change_url = os.getenv("CHANGE_URL")
    if change_url:
        return change_url

    # Try upstream remote first, then fall back to origin
    for remote in ["upstream", "origin"]:
        remote_url = run_git_command(["config", f"remote.{remote}.url"])
        if remote_url:
            https_url = git_remote_url_to_https(remote_url)
            if https_url:
                return https_url

    return None

# error on any shellcheck issues
ERROR_LEVEL_DEFAULT = "2"
error_levels = ["error", "warning", "info", "style"]
desired_error_level = int(
    os.getenv("ERROR_LEVEL")
    if os.getenv("ERROR_LEVEL") is not None
    and bool(re.fullmatch("^[1-4]$", os.getenv("ERROR_LEVEL")))
    else ERROR_LEVEL_DEFAULT
)
error_levels = error_levels[:desired_error_level]

# load shellcheck JSON results
shellcheck_results = json.load(sys.stdin)
if shellcheck_results is None or len(shellcheck_results) == 0:
    print(":white_check_mark: No shellcheck issues found")
    # No feedback found and JSON null means no results returned
    sys.exit(0)

COMMIT = get_head_commit()
CHANGE_URL = get_repo_url()

if CHANGE_URL is None or COMMIT is None:
    print("ERROR: Could not determine repository URL or HEAD commit.")
    print("  Set CHANGE_URL and HEAD_LONG_COMMIT environment variables, or run from a git repository.")
    sys.exit(1)

see_also = {}
REPO_URL = re.sub("pull/[0-9]+$", "", CHANGE_URL)
# Ensure REPO_URL ends with a trailing slash for URL construction
if not REPO_URL.endswith("/"):
    REPO_URL += "/"

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

print(
    """
You can ignore shellcheck rules or enable optional features by utilizing
[shellcheck directives][scd].  Either by creating a `.shellcheckrc` file or a
shellcheck directive comment right next to the line of code you want behaviors
ignored.

[scd]: https://www.shellcheck.net/wiki/Directive"""
)

sys.exit(exit_code)
