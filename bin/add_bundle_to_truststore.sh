#!/bin/bash
#Created by Sam Gleske
#Mon Jul 18 11:28:57 2016 -0700

#DESCRIPTION:
#Get the P7B certificate bundle and split it into separate files.  Import all
#certificates as trusted authorities into the Java truststore.

#DEVELOPMENT ENVIRONMENT:
#GNU bash, version 4.4.0(1)-release (x86_64-apple-darwin15.6.0)
#curl 7.43.0 (x86_64-apple-darwin15.0) libcurl/7.43.0 SecureTransport zlib/1.2.5
#GNU Awk 4.1.3, API: 1.1

#USAGE:
#  export JAVA_HOME=/path/to/java/home
#  ./add_bundle_to_truststore.sh http://www.example.com/certificates.p7b

################################################################################
# USER CONFIGURABLE ENVIRONMENT VARS

JAVA_HOME="${JAVA_HOME:-}"
P7B_CERT_BUNDLE="${P7B_CERT_BUNDLE:-$1}"

# THE FOLLOWING VARS ARE AUTODETECTED IF NOT SET

#java truststore
TRUSTSTORE_LOCATION="${TRUSTSTORE_LOCATION:-}"
#java truststore password
TRUSTSTORE_PASSWORD="${TRUSTSTORE_PASSWORD:-changeit}"
#keytool command path
KEYTOOL="${KEYTOOL:-}"

################################################################################

#exit on ERR
set -e

if [ -z "${JAVA_HOME}" ]; then
  echo '$JAVA_HOME environment variable not set.'
  exit 1
fi

if [ -z "${P7B_CERT_BUNDLE}" ]; then
  echo '$P7B_CERT_BUNDLE environment variable not set.'
  echo 'Alternatively the first argument of script can be the P7B bundle URL.'
  exit 1
fi

P7B_STATUS=$(curl -siIL -w "%{http_code}\\n" -o /dev/null "${P7B_CERT_BUNDLE}")
if [ ! "200" = "${P7B_STATUS}" ]; then
  echo "URL ${P7B_CERT_BUNDLE} returned HTTP status ${P7B_STATUS}"
  exit 1
fi
unset P7B_STATUS

#detect truststore locations or allow user to override TRUSTSTORE_LOCATION var
TRUSTSTORE_LOCATIONS=(
  "${JAVA_HOME}/lib/security/cacerts"
  "${JAVA_HOME}/jre/lib/security/cacerts"
)
for x in $(eval "echo {1..${#TRUSTSTORE_LOCATIONS[@]}}"); do
  [ -f "${TRUSTSTORE_LOCATION}" ] && break
  index=$((x-1))
  TRUSTSTORE_LOCATION="${TRUSTSTORE_LOCATIONS[$index]}"
done

if [ ! -f "${TRUSTSTORE_LOCATION}" ]; then
  echo "Could not find suitable truststore '${TRUSTSTORE_LOCATION}'."
  exit 1
fi

if [ ! -w "${TRUSTSTORE_LOCATION}" ]; then
  echo "Truststore not writeable '${TRUSTSTORE_LOCATION}'."
  echo "Perhaps try: sudo -E $0 $@"
  exit 1
fi
if [ ! -w "${TRUSTSTORE_LOCATION%/*}" ]; then
  echo "Truststore directory not writeable '${TRUSTSTORE_LOCATION%/*}'."
  echo "Aborting because we can't create a backup."
  exit 1
fi

[ ! -e "${TRUSTSTORE_LOCATION}.bak" ] && (
  echo "Making backup copy '${TRUSTSTORE_LOCATION}.bak'."
  cp "${TRUSTSTORE_LOCATION}" "${TRUSTSTORE_LOCATION}.bak"
) || echo "Backup already exists '${TRUSTSTORE_LOCATION}.bak'."

#detect proper keytool version
KEYTOOL_LOCATIONS=(
  "${JAVA_HOME}"/bin/keytool
  "${JAVA_HOME}"/jre/bin/keytool
)
for x in $(eval "echo {1..${#KEYTOOL_LOCATIONS[@]}}"); do
  [ -x "${KEYTOOL}" ] && break
  #try to detect proper keytool
  index=$((x-1))
  KEYTOOL="${KEYTOOL_LOCATIONS[$index]}"
done
if [ ! -x "${KEYTOOL}" ]; then
  echo "Could not find suitable keytool '${KEYTOOL}'."
  exit 1
fi

#create a temporary working directory
TEMPDIR=$(mktemp -d)
pushd "${TEMPDIR}"
#cleanup on error
function on_err() {
  echo '^^ command above has non-zero exit code.'
  popd &> /dev/null
  [ -d "${TEMPDIR%/}" ] && rm -rf "${TEMPDIR%/}"
}
trap on_err ERR

#this should create separate PEM files for each certificate in the bundle.
curl "${P7B_CERT_BUNDLE}" |
openssl pkcs7 -inform DER -outform PEM -print_certs |
awk 'BEGIN {filename="default"}; \
     /^subject/ {subject=$0; gsub(" ", "", subject); gsub(/^.*CN=/, "", subject); filename=subject}; \
     {print > filename ".pem"}'

echo "Keystore: '${TRUSTSTORE_LOCATION}'"
#Now to add them to our java trust store
for x in *.pem;do
  if "${KEYTOOL}" -list -storepass "${TRUSTSTORE_PASSWORD}" -keystore "${TRUSTSTORE_LOCATION}" -alias "${x%.pem}" &> /dev/null; then
    echo "${x%.pem} already exists in keystore"
    continue
  fi

  echo "Importing... ${x}"
  "${KEYTOOL}" -noprompt -import -trustcacerts -storepass "${TRUSTSTORE_PASSWORD}" -keystore "${TRUSTSTORE_LOCATION}" -alias "${x%.pem}" -file "${x}"
done

#clean up downloaded certificates
popd &> /dev/null
[ -d "${TEMPDIR%/}" ] && rm -rf "${TEMPDIR%/}"
