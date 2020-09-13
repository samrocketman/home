#!/bin/bash
#Sam Gleske
#Ubuntu 18.04.5 LTS
#Linux 5.4.0-42-generic x86_64
#Sat Sep 12 18:23:10 EDT 2020
#DESCRIPTION
#    Start a SOCKS5 proxy on localhost:9150 which routes through the TOR onion
#    network.  Also starts a DNS server on localhost:53 (UDP).
#
#    https://github.com/PeterDaveHello/tor-socks-proxy
#
#    The following is a recommended crontab to start TOR automatically and
#    change the TOR endpoint every 5 minutes.
#CRONTAB(5)
#    */5 * * * * start_tor_socks_proxy.sh restart
#    @reboot start_tor_socks_proxy.sh

function helpdoc() {
cat <<'EOF'
SYNOPSIS
    $0 [-f] [-c CODE] [restart]

BASIC OPTIONS
  -f or --strict-firewall
    TOR will only make outbound connections over ports 443 or 80 when
    connecting to the onion network.

  restart
    Will kill an already running TOR docker container before starting.  Without
    this option, an already running TOR docker container will make this command
    a no-op.

OPTIONS WITH ARGUMENTS
  -c CODE or --country CODE
    Provide a country CODE to restrict TOR exit notes just to that country.
    Useful if you want to restrict your traffic to be coming from a specific
    country.  If you're looking for a compromise between anonymity and speed,
    then restricting exit nodes to your own country is more performant than no
    restriction.
EOF
  exit 1
}

stopproxy=false
country=""
strict_firewall=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    restart)
      stopproxy=true
      shift
      ;;
    --country|-c)
      if [ -z "${country:-}" ]; then
        country="$2"
      else
        country+=",$2"
      fi
      shift
      shift
      ;;
    --strict-firewall|-f)
      strict_firewall=true
      shift
      ;;
    *)
      helpdoc
      ;;
  esac
done

while read c; do
  echo $c
  if [ -z "${country_config:-}" ]; then
    country_config="{${c}}"
  else
    country_config+=",{${c}}"
  fi
done <<< "$(tr ',' '\n' <<< "${country}")"

if [ true = "${stopproxy}" ]; then
  docker rm -f tor-socks-proxy
fi

if docker ps -a | grep tor-socks-proxy; then
  docker start tor-socks-proxy
  echo 'Started existing proxy.'
  exit
fi

# https://2019.www.torproject.org/docs/tor-manual.html.en
# MiddleNodes is an experimental option and may be removed.
docker run -d --restart=always --name tor-socks-proxy \
  -p 127.0.0.1:9150:9150/tcp \
  -p 127.0.0.1:53:53/udp \
  --init \
  peterdavehello/tor-socks-proxy:latest \
  /bin/sh -exc "
echo > /etc/tor/torrc2
if [ '${strict_firewall}' = true ]; then
  echo 'FascistFirewall 1' >> /etc/tor/torrc2
  echo 'ReachableAddresses *:80,*:443' >> /etc/tor/torrc2
fi
if [ -n '${country_config}' ]; then
  echo 'GeoIPExcludeUnknown 1' >> /etc/tor/torrc2
  echo 'ExitNodes ${country_config}' >> /etc/tor/torrc2
  echo 'MiddleNodes ${country_config}' >> /etc/tor/torrc2
fi
/usr/bin/tor  --defaults-torrc /etc/tor/torrc -f /etc/tor/torrc2
"


echo 'Started a new proxy.'
