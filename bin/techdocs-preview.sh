#!/bin/bash
# Created by Sam Gleske
# Wed Apr  2 11:56:47 EDT 2025
# GNU bash, version 3.2.57(1)-release (arm64-apple-darwin23)
# Python 3.13.1

set -euo pipefail
# set SKIP_NEXUS=1 if you don't want to download from Nexus on VPN.
TECHDOCS_HOST="${TECHDOCS_HOST:-127.0.0.1}"
TECHDOCS_PORT="${TECHDOCS_PORT:-8000}"
TECHDOCS_WEBSOCKET_PORT="${TECHDOCS_WEBSOCKET_PORT:-8484}"
export TECHDOCS_HOST TECHDOCS_PORT TECHDOCS_WEBSOCKET_PORT

cleanup_on() {
  if grep -F '# --- remove preview' mkdocs.yml > /dev/null; then
    echo mkdocs.yml restored. >&2
    awk '$0 == "# --- remove preview" { exit }; {print}' mkdocs.yml > "${TMP_DIR}"/restore.yml
    mv "${TMP_DIR}"/restore.yml mkdocs.yml
  fi
  # delete tmp as last step
  rm -rf "${TMP_DIR}"
}

TMP_DIR="$(mktemp -d)"
mkdir "${TMP_DIR}/site"
export TMP_DIR
trap cleanup_on EXIT

install_techdocs() (
  if [ -d ~/.techdocs/python3 ]; then
    exit
  fi
  mkdir -p ~/.techdocs
  python3 -m venv ~/.techdocs/python3
  # shellcheck disable=SC1090
  source ~/.techdocs/python3/bin/activate
  pip install \
    mkdocs-techdocs-core==1.5.3 \
    mkdocs-same-dir==0.1.3 \
    mkdocs-gen-files==0.5.0 \
    mkdocstrings==0.28.2 \
    mkdocstrings-python==1.16.2 \
    griffe==1.6.0

  # live-edit
  pip install websockets==16.0 mkdocs-live-edit-plugin==0.3.1
  patch_live_edit_plugin
)

# Fix mkdocs-live-edit-plugin bug: config_scheme uses Type(string) instead of Type(str).
# string is the string module, not a type - causes "isinstance() arg 2 must be a type" on Python 3.13.
patch_live_edit_plugin() {
  # shellcheck disable=SC1090
  source ~/.techdocs/python3/bin/activate
  python3 -c "
import pathlib
try:
    import live.plugin
    path = pathlib.Path(live.plugin.__file__)
    text = path.read_text()
    if 'Type(string,' in text:
        path.write_text(text.replace('Type(string,', 'Type(str,'))
        print('Patched mkdocs-live-edit-plugin: Type(string) -> Type(str)', file=__import__('sys').stderr)
except Exception as e:
    print(f'Could not patch live-edit plugin: {e}', file=__import__('sys').stderr)
" 2>/dev/null || true
}

open_url() (
  {
    if type -P nc &> /dev/null; then
      count=0
      until {
        nc -vz "${TECHDOCS_HOST}" "${TECHDOCS_PORT}" &> /dev/null ||
          [ "$count" -gt 5 ]
      }; do
        sleep 1
        count="$(( count + 1 ))"
      done
    else
      sleep 5
    fi
  } && open http://"${TECHDOCS_HOST}:${TECHDOCS_PORT}"/
)
serve() (
  # shellcheck disable=SC1090
  source ~/.techdocs/python3/bin/activate
  [ -n "${LIVE_EDIT:-}" ] && patch_live_edit_plugin
  mkdocs_config > "${TMP_DIR}"/mkdocs.yml
  mv "${TMP_DIR}"/mkdocs.yml ./
  TMPDIR="${TMP_DIR}" mkdocs serve \
    -f mkdocs.yml \
    -a "${TECHDOCS_HOST}:${TECHDOCS_PORT}" \
    -t material \
    --livereload \
    --open \
    "$@"
)
build() (
  # shellcheck disable=SC1090
  source ~/.techdocs/python3/bin/activate
  mkdocs_config | \
    mkdocs build -f - -t material "$@"
)

# Work around bugs
# https://github.com/EddyLuten/mkdocs-live-edit-plugin/issues/18
# https://github.com/backstage/mkdocs-monorepo-plugin/issues/151
# https://github.com/EddyLuten/mkdocs-live-edit-plugin/issues/3 - MacOS: websockets_host=127.0.0.1 avoids IPv6 ::1 bind failure
liveedit_or_techdocs_plugin() {
  if [ -n "${LIVE_EDIT:-}" ]; then
cat <<EOF
  - live-edit:
      websockets_host: ${TECHDOCS_HOST}
      websockets_port: ${TECHDOCS_WEBSOCKET_PORT}

# https://github.com/backstage/mkdocs-techdocs-core/blob/main/techdocs_core/core.py
# emulate techdocs-core to avoid monorepo plugin
markdown_extensions:
  - toc:
      permalink: true
  - pymdownx.blocks.admonition:
      types: [ "new", "settings", "note", "abstract", "info", "tip", "success", "question", "warning", "failure", "danger", "bug", "example", "quote" ]
  - pymdownx.blocks.details:
      types: [ {"name": "details-new", "class": "new"}, {"name": "details-settings", "class": "settings"}, {"name": "details-note", "class": "note"}, {"name": "details-abstract", "class": "abstract"}, {"name": "details-info", "class": "info"}, {"name": "details-tip", "class": "tip"}, {"name": "details-success", "class": "success"}, {"name": "details-question", "class": "question"}, {"name": "details-warning", "class": "warning"}, {"name": "details-failure", "class": "failure"}, {"name": "details-danger", "class": "danger"}, {"name": "details-bug", "class": "bug"}, {"name": "details-example", "class": "example"}, {"name": "details-quote", "class": "quote"} ]
  - pymdownx.blocks.tab:
      alternate_style: true
  - pymdownx.caret
  - pymdownx.critic
  - pymdownx.emoji:
      emoji_generator: !!python/name:pymdownx.emoji.to_svg
  - pymdownx.inlinehilite
  - pymdownx.magiclink
  - pymdownx.mark
  - pymdownx.smartsymbols
  - pymdownx.snippets
  - pymdownx.highlight:
      linenums: true
      pygments_lang_class: true
  - pymdownx.extra
  - pymdownx.betterem:
      smart_enable: all
  - pymdownx.tasklist:
      custom_checkbox: true
  - pymdownx.tilde
  - markdown_inline_graphviz
  - plantuml_markdown
  - mdx_truly_sane_lists
EOF
  else
cat <<EOF
  - techdocs-core:
      use_material_search: true
      use_pymdownx_blocks: true
EOF
  fi
}

mkdocs_config() {
cat <<EOF
$(cat mkdocs.yml)
# --- remove preview
# https://github.com/backstage/mkdocs-techdocs-core/blob/58da52411a8f55e9afdc11dd9694897534058310/README.md#mkdocs-plugins-and-extensions
# https://github.com/backstage/mkdocs-techdocs-core/blob/58da52411a8f55e9afdc11dd9694897534058310/techdocs_core/core.py#L101-L201
plugins:
  - search:
      pipeline:
        - stemmer
        - stopWordFilter
        - trimmer
$(liveedit_or_techdocs_plugin)
EOF
}

#
# MAIN
#
if [ -n "${SKIP_NEXUS:-}" ]; then
  unset pip
fi
case "${1:-}" in
  -h|--help|help)
    cat<<'EOF'
SYNOPSIS
  techdocs-preview.sh
  techdocs-preview.sh install
  techdocs-preview.sh build --help
  techdocs-preview.sh build [additional mkdocs options]
  techdocs-preview.sh serve --help
  techdocs-preview.sh serve static
  techdocs-preview.sh serve [additional mkdocs options]

DESCRIPTION
  Run techdocs or create a techdocs preview using a lightweight python
  environment.

  With no options "serve" is the default and a browser link will be opened.

  techdocs-preview.sh serve static
    Disables live-edit plugin and instead relies on mkdocs-techdocs-core plugin.
EOF
    exit
    ;;
esac
install_techdocs
#if [ "$#" = 0 ]; then
#  open_url &
#fi
if [ "${1:-}" = install ]; then
  install_techdocs
elif [ "${1:-}" = build ]; then
  shift
  build "$@"
else
  if [ "${1:-}" = serve ]; then
    shift
  fi
  if [ "${1:-}" = static ]; then
    shift
  else
    export LIVE_EDIT=1
  fi
  serve "$@"
fi
