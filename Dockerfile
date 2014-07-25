FROM debian:wheezy
MAINTAINER Tim White

# If host is running squid-deb-proxy on port 8000, populate
# /etc/apt/apt.conf.d/30proxy
# By default, squid-deb-proxy 403s unknown sources, so apt shouldn't proxy
# ppa.launchpad.net
RUN route -n | awk '/^0.0.0.0/ {print $2}' > /tmp/host_ip.txt
RUN echo "HEAD /" | nc `cat /tmp/host_ip.txt` 8000 | grep squid-deb-proxy \
  && (echo "Acquire::http::Proxy \"http://$(cat /tmp/host_ip.txt):8000\";" > /etc/apt/apt.conf.d/30proxy) \
  || echo "No squid-deb-proxy detected on docker host"

COPY sources.list /etc/apt/sources.list
COPY grase-repo_1.5_all.deb /tmp/

RUN dpkg -i /tmp/grase-repo_1.5_all.deb
RUN sed -i 's/\/packages/\/nightly.packages/' /etc/apt/sources.list.d/grasehotspot.list

RUN apt-get update
RUN apt-get install -y grase-www-portal

EXPOSE 80

