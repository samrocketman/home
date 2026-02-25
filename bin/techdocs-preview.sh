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
  pip install websockets==16.0 git+https://github.com/samrocketman/mkdocs-live-edit-plugin
)

serve() (
  # shellcheck disable=SC1090
  source ~/.techdocs/python3/bin/activate
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
  - techdocs-core:
      use_material_search: true
      use_pymdownx_blocks: true
  - live-edit:
      user_docs_dir: "${PWD}/docs"
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
  techdocs-preview.sh serve [additional mkdocs options]

DESCRIPTION
  Run techdocs or create a techdocs preview using a lightweight python
  environment.

  With no options "serve" is the default and a browser link will be opened.
EOF
    exit
    ;;
esac
install_techdocs
if [ "${1:-}" = install ]; then
  install_techdocs
elif [ "${1:-}" = build ]; then
  shift
  build "$@"
else
  if [ "${1:-}" = serve ]; then
    shift
  fi
  serve "$@"
fi
