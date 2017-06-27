######################################
#
#  Dockerfile for Kannel base image
#
######################################

FROM ubuntu:16.04
MAINTAINER JD Irausquin "jdirausquin@yakuq.net"
ENV REFRESHED_AT 2017-06-26

# Expose port 10300 and 13013
EXPOSE 13000 13013


# Install dependencies and packages
RUN apt-get update
RUN apt-get -y install gcc libxml2-dev make wget
RUN apt-get -y install libssl-dev libssh-dev
RUN mkdir /usr/local/src/m4
RUN mkdir /usr/local/src/bison
# M4 install: required by Bison
RUN wget https://ftp.gnu.org/gnu/m4/m4-1.4.17.tar.gz -O /usr/local/src/m4-1.4.17.tar.gz
RUN tar xzvf /usr/local/src/m4-1.4.17.tar.gz -C /usr/local/src/m4/ && cd /usr/local/src/m4/m4-1.4.17/ && ls -l && ./configure && make && make install
# Bison 2.5.1 install: YACC error
RUN wget https://ftp.gnu.org/gnu/bison/bison-2.5.1.tar.gz -O /usr/local/src/bison-2.5.1.tar.gz
RUN tar xzvf /usr/local/src/bison-2.5.1.tar.gz -C /usr/local/src/bison && cd /usr/local/src/bison/bison-2.5.1/ && ./configure && make && make install

# Install MySQL
#RUN apt-get -y install mysql-server-5.7 libmysql++-dev

# Installation
RUN mkdir -p /usr/local/src/kannel
RUN mkdir /usr/local/src/kannel/gateway-1.4.4
#ADD build.sh /usr/local/src/kannel/gateway-1.4.4/build.sh
#RUN chmod +x /usr/local/src/kannel/gateway-1.4.4/build.sh
RUN cd /usr/local/src/kannel && wget http://www.kannel.org/download/1.4.4/gateway-1.4.4.tar.gz -O /usr/local/src/kannel/gateway-1.4.4.tar.gz
RUN tar xzvf /usr/local/src/kannel/gateway-1.4.4.tar.gz -C /usr/local/src/kannel/ && cd /usr/local/src/kannel/gateway-1.4.4/ && ./configure --prefix=/usr/local/kannel --enable-debug --enable-assertions --with-defaults=speed --enable-start-stop-daemon --enable-ssl --enable-pam && make && make bindir=/usr/local/kannel install

# Compile & Install
RUN cd /usr/local/src/kannel/gateway-1.4.4 && make && make bindir=/usr/local/kannel install

# After we have Kannel installed, we have to copy basic configuration files to /etc/location
RUN mkdir /etc/kannel
RUN cp /usr/local/src/kannel/gateway-1.4.4/gw/smskannel.conf /etc/kannel/kannel.conf
RUN cp /usr/local/src/kannel/gateway-1.4.4/debian/kannel.default /etc/default/kannel

## Also we have to create log directory.
RUN mkdir /var/log/kannel
RUN chmod 755 /var/log/kannel
## Optional, we can create this directory to store messages if we set store-type variable to spool. This basically means 
RUN mkdir /var/log/kannel/storedmsg

# Kannel execution
## Once Kannel was successfully installed, we execute the following commands in order to
## bring it up:
RUN /usr/local/kannel/sbin/bearerbox -v 0 /etc/kannel/kannel.conf &
RUN /usr/local/kannel/sbin/smsserverbox -v 0 /etc/kannel/kannel.conf &
ENTRYPOINT ["/bin/bash"]
