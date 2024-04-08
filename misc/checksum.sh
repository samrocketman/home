#!/bin/bash

set -euo pipefail

cd ~/git/github/home/misc

download-utilities.sh --update
download-utilities.sh --checksum -I Darwin:arm64 -I Darwin:x86_64 -I Linux:aarch64 -I Linux:x86_64
