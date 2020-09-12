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


if [ "${1:-}" = restart ]; then
  docker rm -f tor-socks-proxy
fi

if docker ps -a | grep tor-socks-proxy; then
  docker start tor-socks-proxy
  echo 'Started existing proxy.'
  exit
fi

docker run -d --restart=always --name tor-socks-proxy \
  -p 127.0.0.1:9150:9150/tcp \
  -p 127.0.0.1:53:53/udp \
  peterdavehello/tor-socks-proxy:latest

echo 'Started a new proxy.'
