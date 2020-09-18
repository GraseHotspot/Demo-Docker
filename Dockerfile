FROM debian:jessie
MAINTAINER Tim White

#COPY sources.list /etc/apt/sources.list


#RUN apt-get update; apt-get install -y -q netcat-openbsd
# If host is running squid-deb-proxy on port 8000, populate
# /etc/apt/apt.conf.d/30proxy
# By default, squid-deb-proxy 403s unknown sources, so apt shouldn't proxy
# ppa.launchpad.net
#RUN route -n | awk '/^0.0.0.0/ {print $2}' > /tmp/host_ip.txt
#RUN echo "HEAD /" | nc $(cat /tmp/host_ip.txt) 8000 | grep squid-deb-proxy \
#  && (echo "Acquire::http::Proxy \"http://$(cat /tmp/host_ip.txt):8000\";" > /etc/apt/apt.conf.d/30proxy) \
#  || echo "No squid-deb-proxy detected on docker host"

## We know we run the proxy, so hard code it
#RUN /sbin/ip route | awk '/default/ { print "Acquire::http::Proxy \"http://"$3":8000\";" }' > /etc/apt/apt.conf.d/30proxy

# Some Environment Variables
#ENV    DEBIAN_FRONTEND noninteractive

COPY grase-repo_1.8_all.deb /tmp/
COPY graseselections /tmp/

RUN debconf-set-selections /tmp/graseselections
RUN dpkg -i /tmp/grase-repo_1.8_all.deb
RUN sed -i 's/\/packages/\/nightly.packages/' /etc/apt/sources.list.d/grasehotspot.list
#RUN echo deb http://localpackages/$GRASERELEASE/ purewhite main > /etc/apt/sources.list.d/grasehotspot.list

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server less vim

ADD http://nightly.packages.grasehotspot.org/dists/purewhite/Release /tmp/
RUN apt-get update
RUN /etc/init.d/mysql start && DEBIAN_FRONTEND=noninteractive apt-get install -y grase-www-portal grase-conf-freeradius coova-chilli

RUN echo 'RedirectMatch ^/$ https://demo.grasehotspot.org/grase/radmin/' > /etc/apache2/conf-enabled/index-redirect.conf

COPY start /root/
COPY demo.sql /root/
COPY overflowdata.sql /root/

CMD /root/start

EXPOSE 80

