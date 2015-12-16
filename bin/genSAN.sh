#!/bin/bash
#Created by Sam Gleske
#Wed Dec 16 03:54:10 EST 2015
#Mac OS X 10.11.2
#Darwin 15.2.0 x86_64
#GNU bash, version 4.3.11(1)-release (x86_64-apple-darwin13.2.0)
#OpenSSL 0.9.8zg 14 July 2015

#DESCRIPTION:
#  Generate the private key and CSR using this script.
#  Supports subject alternative names.

#USAGE:
#  Genearte a cert for one domain:
#    ./genSAN.sh example.com
#  Generate a cert for two domains:
#    ./genSAN.sh example.com alt.example.com

function usage() {
cat <<EOF
genSAN.sh domain1 [domain2 ...]

DESCRIPTION:
  Generate SSL SAN certificates.

OPTIONS:
  -h,--help      show help
  -y,-q,--quiet  suppress overwrite prompt
  -d,--dedup     don't duplicate CN to SAN entry

Additional domain arguments are treated as subject alternative names.
EOF
}

ask=true
dedup=false
server=""
SANs=()
while [ "$#" -gt '0' ]; do
  case $1 in
    -h|--help)
      usage
      exit 1
      ;;
    -y|-q|--quiet)
      ask=false
      shift
      ;;
    -d|--dedup)
      dedup=true
      shift
      ;;
    *)
      if [ -z "${server}" ]; then
        server="$1"
      else
        SANs+=("$1")
      fi
      shift
      ;;
  esac
done

#build the SAN list
if ${dedup}; then
  SANconf=""
else
  SANconf="DNS:${server}"
fi
for x in ${SANs[*]}; do
  SANconf="${SANconf},DNS:${x}"
done

#
# Subject and SSL conf
#

SUBJ="${SUBJ:-/C=US/ST=California/L=Garden Grove/O=Example Corp/OU=Example Team/CN=}"

SSLconf="[ req ]
distinguished_name  = req_distinguished_name
req_extensions = v3_req

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = ${SANconf#,}

[ req_distinguished_name ]"

#
# Generate private key and CSR
# If provided more than one domain then generate a SAN cert
#

if ${ask} && [ -e "${server}.key" ]; then
  read -p "${server}.key already exists.  Overwrite? [y/N]: " answer
  if [ ! "${answer}" = 'y' -a ! "${answer}" = 'yes' ]; then
    echo 'User aborted.'
    exit 1
  fi
fi

if [ -n "${SANs[0]}" ]; then
  #generate SAN cert
  openssl req -new \
              -config  <( echo "${SSLconf}" ) \
              -newkey rsa:2048 \
              -sha256 -nodes \
              -keyout ${server}.key \
              -out ${server}.csr -text \
              -subj "${SUBJ}${server}"
else
  openssl req -new \
              -newkey rsa:2048 \
              -sha256 -nodes \
              -keyout ${server}.key \
              -out ${server}.csr -text \
              -subj "${SUBJ}${server}"
fi
