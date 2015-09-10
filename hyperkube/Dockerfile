FROM resin/rpi-raspbian:wheezy

RUN apt-get update
RUN apt-get -yy -q install iptables ca-certificates

COPY hyperkube /hyperkube
