FROM ubuntu:18.04
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

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y less vim gnupg2

COPY grase-repo_1.7_all.deb /tmp/
COPY graseselections /tmp/

RUN debconf-set-selections /tmp/graseselections
RUN dpkg -i /tmp/grase-repo_1.7_all.deb
RUN sed -i 's/\/packages/\/nightly.packages/' /etc/apt/sources.list.d/grasehotspot.list


ADD http://nightly.packages.grasehotspot.org/dists/purewhite/Release /tmp/
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y php php-cli mysql-client wget iproute2 apache2 libapache2-mod-php dbconfig-common php-mysql dbconfig-no-thanks php-intl
#RUN /etc/init.d/mysql start && DEBIAN_FRONTEND=noninteractive apt-get install -y grase-www-portal grase-conf-freeradius coova-chilli
COPY artifacts/ /tmp/artifacts/
RUN DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/artifacts/*.deb

RUN echo 'RedirectMatch ^/$ https://devdemo.grasehotspot.org/grase/radmin/' > /etc/apache2/conf-available/index-redirect.conf
RUN a2enconf index-redirect

# This is only needed until dbconfig-common handles it
RUN echo 'DATABASE_URL=mysql://grase:grase@mysql:3306/radius' > /usr/share/grase/symfony4/.env.local
RUN echo 'APP_ENV=prod' >> /usr/share/grase/symfony4/.env.local

COPY start /root/

CMD /root/start
# TODO lots of this can be split into multiple images with docker-compose now
EXPOSE 80

