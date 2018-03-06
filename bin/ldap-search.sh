#!/bin/bash
#Created by Sam Gleske
#Mon Aug 10 15:33:31 EDT 2015
#Mac OSX 10.9.5
#Darwin 13.4.0 x86_64
#GNU bash, version 3.2.53(1)-release (x86_64-apple-darwin13)
#ldapsearch: @(#) $OpenLDAP: ldapsearch 2.4.28 (Mar 18 2015 17:48:51) $

#DESCRIPTION
#  Search LDAP for a username using ldapsearch.

#hardcore safe scripting
set -euf -o pipefail

#override the following environment variables in your ~/.bash_profile
args=()
ldap_server="${ldap_server:-ldaps://ldap.example.com:636}"
binddn="${binddn:-uid=someuser,ou=people,dc=example,dc=com}"
basedn="${basedn:-}"
ldap_passwd="${ldap_passwd:-CHANGEME}"
ldap_scope="${ldap_scope:-}"

#process args
[ -z "${basedn}" ] || args+=(-b "${basedn}")
[ -z "${ldap_scope}" ] || args+=(-s "${ldap_scope}")

[ "${ldap_passwd}" = CHANGEME ] || args+=(-W)

#firstname="$1"
#lastname="$2"
#uid="$3"
set +u
eval "filter=\"${ldap_filter:-'(&(cn=*${1}*) (sn=*${2}*) (uid=*${3}*))'}\""
set -u
ldapsearch -x -H "${ldap_server}" -D "${binddn}" "${args[@]:-}" "${filter}"
