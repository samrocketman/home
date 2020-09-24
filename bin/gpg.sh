#!/bin/bash
#Created by Sam Gleske
#Sun Sep 20 8:15pm EDT 2020
#DESCRIPTION
#    Encrypts individual files using gpg.  Can also perform signatures,
#    signature validation, and cleanup.  This script is intended to provide
#    confidentiality and integrity of encrypted files.
#
#    PLEASE NOTE: While the files are encrypted, the names are kept original so
#    it is possible for someone to infer the contents based on name.

set -eo pipefail

# global arrays and variables
remove_files="false"
overwrite_file=false
recipient_list="${recipient_list:-}"
keyring_file=""
verifying_public_key=""
parallel=""
declare -a gpg_opts=()
declare -a files=()
declare -a find_args=()
declare -a opt_find_args=()
declare -a find_ignore_files=('.gpg' 'sha1sum.txt' '.checksumrequired' '.sig')
declare -a passthrough_opts=()

function helpdoc() {
cat <<'EOF'
SYNOPSIS
  gpg.sh MODE_OPTION [-o] [--rm] [-i] [-r] FILES...

DESCRIPTION
  Encrypts individual files using gpg.  Can also perform signatures,
  signature validation, and cleanup.  This script is intended to provide
  confidentiality and identity-based integrity of encrypted files using digital
  signatures.

  PLEASE NOTE: While the files are encrypted, the names are kept original so
  it is possible for someone to infer the contents based on name.

  You must pass in one mode option.  FILES can be files or directories.

REQUARED ARGUMENTS:
  FILES
    A list of files provided to perform an operation.  The list can include
    regular files or directories.

MODE OPTIONS:
  -e or --encrypt
    encrypt mode.  Will encrypt individual files.

  -d or --decrypt
    encrypt mode.  Will decrypt individual files.

  -s or --sign
    sign mode.  Will digitally sign individual gpg files.

  -v FINGERPRINT or --verify FINGERPRINT
    verify mode.  Will verify every gpg file is signed by the provided
    FINGERPRINT.

  -p or --find-plain-files
    find_plain_files mode.  Will search a directory of mixed encrypted and
    plain text content.  It will find and print all plain (unencrypted) files.
    It will not print gpg encrypted files, gpg signature files, or hashed files
    like sha1sum.txt (legacy way of validating integrity before using
    signatures).

DESTRUCTIVE OPTIONS:
  -o or --overwrite-file
    Performs a destructive operation.  Varies depending on the mode.  The
    following is --overwrite-file behavior by mode it affects.  The default
    behavior without this option is to exit with an error since a file exists.
    | MODE             | BEHAVIOR                                              |
    | ---------------- | ----------------------------------------------------- |
    | encrypt          | If a gpg file exists of the same name as the file to  |
    |                  | be encrypted, then the gpg file will be overwritten.  |
    | decrypt          | If a plaintext file (without .gpg extention) exists,  |
    |                  | then it will be overwritten.                          |
    | sign             | When gpg encrypted files are signed and a file of the |
    |                  | same name (extension .gpg.sig) exists, then it will   |
    |                  | be overwritten.                                       |

  --rm or --remove
    Performs a destructive operation.  Varies depending on the mode.  The
    following is --remove behavior by mode it affects.  The default behavior
    without this option is to leave files behind.
    | MODE             | BEHAVIOR                                              |
    | ---------------- | ----------------------------------------------------- |
    | encrypt          | Removes original plain text files after it is gpg     |
    |                  | encrypted.                                            |
    | decrypt          | Removes encrypted gpg and sig file after it is        |
    |                  | decrypted.                                            |
    | find_plain_files | Deletes all of the plain files found.  Useful if      |
    |                  | you've encrypted a directory and forgot to remove the |
    |                  | originals.                                            |


OTHER OPTIONS:
  -r FINGERPRINT or --recipient FINGERPRINT
    A recipient to encrypt the contents of a file to a specified gpg key
    FINGERPRINT.  There can by many recipients that can decrypt the same set of
    files.  This option can be specified multiple times for multiple
    recipients.  Additionally, a space-separated list of fingerprints can be
    provided in the recipient_list environment variable.

  -i PATTERN or --ignore-path-pattern PATTERN
    The find command is used to search paths for encrypting files.  You can
    partially exclude paths using this option.  For testing patterns, use the
    --find-plain-files mode option to print a list of files to be encrypted
    when the ignore pattern is applied.

    For example, to exclude files within `./foo` directory is the following
    command example.

      gpg.sh --find-plain-files -i './foo/*' .
      gpg.sh --encrypt -i './foo/*' .

  -P NUMBER or --parallel NUMBER
    Launches NUMBER parallel processes when performing an operation.  By
    default it is double the number of CPUs or 8 if nproc utility is not
    available.
EOF
}

function set_mode() {
  if [ -n "${mode}" ]; then
    echo "ERROR: mode is already '${mode}' so cannot set '$1'" >&2
    exit 1
  fi
  mode="$2"
}

function parse_args() {
  while (( $# )); do
    case "$1" in
      --)
        break
        ;;
      -i|--ignore-path-pattern)
        opt_find_args+=( -path "${2}" -prune -o )
        passthrough_opts+=( "$1" "$2" )
        shift 2
        ;;
      --rm|--remove)
        remove_files=true
        passthrough_opts+=( "$1" )
        shift
        ;;
      -r|--recipient)
        # add
        gpg_opts+=( -r "$2" )
        passthrough_opts+=( "$1" "$2" )
        shift 2
        ;;
      -o|--overwrite-file)
        overwrite_file=true
        passthrough_opts+=( "$1" )
        shift
        ;;
      -e|--encrypt)
        set_mode "$1" encrypt
        shift
        ;;
      -f|--encrypt-file)
        set_mode "$1" encrypt_file
        shift
        ;;
      -d|--decrypt)
        set_mode "$1" decrypt
        shift
        ;;
      --decrypt-file)
        set_mode "$1" decrypt_file
        shift
        ;;
      -s|--sign)
        set_mode "$1" sign
        shift
        ;;
      --sign-file)
        set_mode "$1" sign_file
        shift
        ;;
      -v|--verify)
        verifying_public_key="$2"
        set_mode "$1" verify
        shift 2
        ;;
      -k|--keyring)
        set_mode "$1" verify_file
        keyring_file="${2}"
        shift 2
        ;;
      -p|--find-plain-files)
        set_mode "$1" find_plain_files
        shift
        ;;
      -P|--parallel)
        parallel="$2"
        shift 2
        ;;
      --help)
        helpdoc
        exit 1
        ;;
      *)
        files=( "$1" )
        shift
        ;;
    esac
  done
  # add the remaining arguments to files list
  if [ "$#" -gt 0 ]; then
    files+=( "$@" )
  fi
}

function encrypt_file() {
  if [ ! -f "$1" ]; then
    echo "WARNING: ${1} is not a file so skipping." >&2
    return
  fi
  if [ "${overwrite_file}" = false -a -f "${1}.gpg" ]; then
    echo "ERROR: '${1}.gpg' exists." >&2
    exit 1
  fi
  gpg "${gpg_opts[@]}" --output - -e "${1}" > "${1}.gpg"
  if [ "${remove_files}" = true ]; then
    rm -f "$1"
    echo "Encrypted '${1}' and removed original." >&2
  else
    echo "Encrypted '${1}' to '${1}.gpg'" >&2
  fi
}

function decrypt_file() {
  if [ ! -f "$1" ]; then
    echo "WARNING: ${1} is not a file so skipping." >&2
    return
  fi
  if [ "${overwrite_file}" = false -a -f "${1%.gpg}" ]; then
    echo "ERROR: '${1%.gpg}' exists." >&2
    exit 1
  fi
  gpg --output - -d "${1}" 2> /dev/null > "${1%.gpg}"
  if [ "${remove_files}" = true ]; then
    rm -f "$1" "$1.sig"
    echo "Decrypted '${1}'.  Removed encrypted file and signature." >&2
  else
    echo "Decrypted '${1}'." >&2
  fi
}

function sign_file() {
  if [ ! -f "$1" ]; then
    echo "WARNING: ${1} is not a file so skipping." >&2
    return
  fi
  if [ "${overwrite_file}" = false -a -f "${1}.sig" ]; then
    echo "ERROR: '${1}.sig' exists." >&2
    exit 1
  fi
  gpg -s --output - --detach-sig "${1}" > "${1}.sig"
  echo "Signed '${1}'"
}

function verify_file() {
  if [ ! -f "$1" ]; then
    echo "WARNING: ${1} is not a file so skipping." >&2
    return
  fi
  if [ ! -f "${keyring_file}" ]; then
    echo "ERROR: Keyring file '${keyring_file}' does not exist." >&2
    exit 1
  fi
  if ! gpg --no-default-keyring --keyring "${keyring_file}" \
    --trustdb-name "${keyring_file%keyring}trustdb" \
    --trust-model always --verify "${1}.sig" "${1}" &> /dev/null; then
    echo "FAILED SIGNATURE: '${1}'"
    exit 1
  fi
  echo "Verified '${1}'"
}

#
# MAIN
#

for x in "${find_ignore_files[@]}"; do
  find_args+=( -path "*${x}" -prune -o )
done

for x in ${recipient_list}; do
  gpg_opts+=( -r "$x" )
done

trap '[ ! -d "${TMP_DIR:-}" ] || rm -rf "${TMP_DIR}"' EXIT
parse_args "$@"

if [ -z "${parallel}" ] && type -P nproc &> /dev/null; then
  # parallel is 2x CPU
  parallel="$(( $(nproc)*2 ))"
else
  parallel="${parallel:-8}"
fi
if ! grep '^[0-9]\+$' &> /dev/null <<< "${parallel}"; then
  echo 'ERROR: --parallel option must be a number.'
  exit 1
fi
case "${mode}" in
  encrypt)
    echo "Overwrite encrypted files: ${overwrite_files}"
    echo "Remove original plaintext files: ${remove}"
    echo "Parallel processes: ${parallel}"
    find "${files[@]}" "${find_args[@]}" "${opt_find_args[@]}" -type f -print0 | \
      xargs -0 -n1 "-P${parallel}" -- "$0" -f "${passthrough_opts[@]}"
    ;;
  encrypt_file)
    for x in "${files[@]}"; do
      encrypt_file "${x}"
    done
    ;;
  decrypt)
    echo "Overwrite plaintext files: ${overwrite_files}"
    echo "Remove original encrypted files and signatures: ${remove}"
    echo "Parallel processes: ${parallel}"
    find "${files[@]}" "${opt_find_args[@]}" -type f -name '*.gpg' -print0 | \
      xargs -0 -n1 "-P${parallel}" -- "$0" --decrypt-file "${passthrough_opts[@]}"
    ;;
  decrypt_file)
    for x in "${files[@]}"; do
      decrypt_file "${x}"
    done
    ;;
  sign)
    echo "Parallel processes: ${parallel}"
    echo "Overwrite signature files: ${overwrite_files}"
    find "${files[@]}" "${opt_find_args[@]}" -type f -name '*.gpg' -print0 | \
      xargs -0 -n1 "-P${parallel}" -- "$0" --sign-file "${passthrough_opts[@]}"
    ;;
  sign_file)
    for x in "${files[@]}"; do
      sign_file "${x}"
    done
    ;;
  verify)
    echo "Parallel processes: ${parallel}"
    TMP_DIR="$(mktemp -d)"
    gpg --export "$verifying_public_key" | \
      gpg --no-default-keyring --keyring "${TMP_DIR}/keyring" \
      --trustdb-name "${keyring_file%keyring}trustdb" \
      --trust-model always --import
    passthrough_opts+=( -k "${TMP_DIR}/keyring" )
    find "${files[@]}" "${opt_find_args[@]}" -type f -name '*.gpg' -print0 | \
      xargs -0 -n1 "-P${parallel}" -- "$0" "${passthrough_opts[@]}"
    echo 'SUCCESS: All gpg files verified against provided fingerprint.'
    ;;
  verify_file)
    for x in "${files[@]}"; do
      verify_file "$x"
    done
    ;;
  find_plain_files)
    if [ "${remove_files}" = true ]; then
      find "${files[@]}" "${find_args[@]}" "${opt_find_args[@]}" -type f -exec rm -f {} +
    else
      find "${files[@]}" "${find_args[@]}" "${opt_find_args[@]}" -type f -print
    fi
    ;;
  *)
    echo 'gpg.sh ERROR: Not enough options to perform operation.' >&2
    exit 2
  ;;
esac
