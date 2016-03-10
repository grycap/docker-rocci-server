#!/bin/bash
#
# https://github.com/grycap/docker-rocci-server
#
# Copyright (C) GRyCAP - I3M - UPV 
# Developed by Carlos A. caralla@upv.es
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
FROM ubuntu:12.04

# Install according to https://wiki.egi.eu/wiki/rOCCI:ROCCI-server_Admin_Guide
RUN apt-get -y update && apt-get install -y wget && apt-key adv --fetch-keys http://repository.egi.eu/community/keys/APPDBCOMM-DEB-PGP-KEY.asc && cd /etc/apt/sources.list.d && wget http://repository.egi.eu/community/software/rocci.server/1.1.x/releases/repofiles/debian-wheezy-amd64.list && apt-get -y update ; apt-get install -y occi-server

# Install the CAs
RUN apt-get -y update ; apt-get install -y wget && wget -q -O - https://dist.eugridpma.info/distribution/igtf/current/GPG-KEY-EUGridPMA-RPM-3 | apt-key add - && echo "deb http://repository.egi.eu/sw/production/cas/1/current egi-igtf core" > /etc/apt/sources.list.d/EGI.list && apt-get -y update ;  apt-get install -y ca-policy-egi-core

# Install the ONE cli
RUN wget -q -O- http://downloads.opennebula.org/repo/Ubuntu/repo.key | apt-key add - && echo "deb http://downloads.opennebula.org/repo/4.12/Ubuntu/14.04/ stable opennebula" > /etc/apt/sources.list.d/opennebula.list && apt-get -y update ; apt-get -y install opennebula-tools

# Integration with VOMS
RUN apt-get install -y gridsite

# -------------------------------------------------------------------
# Install the bootstrapper (files from https://github.com/grycap/docker-rocci-server/)
# -------------------------------------------------------------------

ADD ./start-node /opt/docker-boot/
ADD ./conf.d /etc/docker-boot/conf.d/
ENTRYPOINT [ "/opt/docker-boot/start-node" ]

# Setting up the occi site, configured and the configuration for ONE
ADD ./customfiles/occi-ssl /etc/apache2/sites-available/
RUN rm -f /etc/occi-server/backends/opennebula/fixtures/resource_tpl/*
ADD ./customfiles/resource_tpl /etc/occi-server/backends/opennebula/fixtures/resource_tpl/

# Setting up the LSC files
ADD ./customfiles/vomsdir /etc/grid-security/vomsdir/

# We'll expose the 11443 port, that is used for rocci
EXPOSE 11443
