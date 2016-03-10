# rOCCI in a Docker
[rOCCI](https://wiki.egi.eu/wiki/rOCCI:ROCCI-server_Admin_Guide) is a mechanism to interact with IaaS deployments such as ONE. It may be difficult to install, but it also may need specific versions of libraries.
It seems that it is a very specific deployment and can be isolated from the IaaS deployment.

This is a project that enables to create a rOCCI server in a Docker container, and this server is connected to a OpenNebula backend.

Please read the Use Case section, as some variables are a bit tricky.

## Usage
You can simply clone this repository, customize your variables and create your docker image from the Dockerfile that is included in the repository. Then you can launch the docker container using the _start-rocci-server_ script.

### Customization
1) You have to modify the _customfiles/occi-ssl_ file to adapt it to your deployment. In particular, you have to adjust the variables related to _OpenNebula_ credentials:

```bash
ROCCI_SERVER_ONE_XMLRPC
ROCCI_SERVER_ONE_USER
ROCCI_SERVER_ONE_PASSWD
ROCCI_SERVER_ONEUSER_AUTOCREATE_HOOK_VO_NAMES
```

If you set the ONE_XMLRPC variable in the environment (as it is set in _start-rocci-server_), you won't need to modify the ROCCI_SERVER_ONE_XMLRPC (you should just leave the [[ONE_XMLRPC]] keyword and it will be substituted
at boot time).

2) You need to provide the appropriate _hostcert.pem_ and _hostkey.pem_ files for your server.

3) You need to adjust the variables in the _start-rocci-server_ script. Their names are self-explained. Please pay special attention to the HOSTNAME variable.

4) Create the docker image
```bash
$ docker build -t ubuntu:occi1.1 .
```

5) Start your server
```bash
$ ./start-rocci-server
```

## Use case
I have the server _opennebula.my.local.dns_ that is my OpenNebula front-end. I have a user _rocci_, created according to the instructions in https://wiki.egi.eu/wiki/rOCCI:ROCCI-server_Admin_Guide

_ASSUMPTIONS_: This use case assumes that you have Docker installed in _opennebula.my.local.dns_ and you will run the rocci server in the same server than the OpenNebula frontend. You can detach this architecture and
use this container just adapting the settings.

```bash
$ su - oneadmin
$ oneuser create rocci '<actual_password_edited_out>' --driver server_cipher
$ oneuser chgrp rocci oneadmin
```

And I want to offer OpenNebula by rOCCI means.

1) I will clone the repository

```bash
$ git clone https://github.com/grycap/docker-rocci-server
$ cd docker-rocci-server
```

2) I will get a certificate for my server, and I will put the key and the certificate in the folder _/etc/grid-security/_
```bash
$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/grid-security/hostkey.pem -out /etc/grid-security/hostcert.pem <<< cat << EOT
ES
Spain
Valencia
UPV
GRyCAP
opennebula.my.local.dns
.
EOT
```

Pay attention to the name used for the server certificate, because I want that the endpoint for rOCCI will be https://opennebula.my.local.dns:11443 and the apache server inside the container has to
deliver the certificate corresponding to the hostname in the endpoint.

_NOTE_: Obviously you can use your certificates signed by an external CA, instead of the self signed certificates.

3) Now I will edit the _customfiles/occi-ssl_ file and I will set the following values:
```bash
    SetEnv ROCCI_SERVER_ONE_XMLRPC  [[ONE_XMLRPC]]
    SetEnv ROCCI_SERVER_ONE_USER    rocci
    SetEnv ROCCI_SERVER_ONE_PASSWD  <actual_password_edited_out>
    
    SetEnv ROCCI_SERVER_HOOKS                 oneuser_autocreate
    SetEnv ROCCI_SERVER_AUTHN_STRATEGIES      voms
    SetEnv ROCCI_SERVER_ONEUSER_AUTOCREATE_HOOK_VO_NAMES            "fedcloud.egi.eu"
```
In particular, I'm setting the password for the rocci user in OpenNebula, I want that the users are created in ONE if they show a valid VOMS certificate from VO _fedcloud.egi.eu_. And I want the server to use only voms authentication.

_NOTE_: you are advised to use your own mechanisms for authentication (e.g. perun or others).

*) In my particular case I do not need to create the lsc files for the fedcloud VO as they are shipped in this package, but in case that I want to support other VOs I should include the corresponding folders in _customfiles/vomsdir_.

*) Moreover, according to https://wiki.egi.eu/wiki/rOCCI:ROCCI-server_Admin_Guide you should create the corresponding groups in OpenNebula.

4) Now I can create the docker image:
```bash
$ docker build -t ubuntu:rocci1.1 .
```

Note that I am setting the name _ubuntu:rocci1.1_ for the docker image.

5) At this moment I need to edit the file _start-rocci-server_, and I will set the following values:

```bash
HOSTNAME=opennebula.my.local.dns
HOSTCERT_PATH=/etc/grid-security/hostcert.pem
HOSTKEY_PATH=/etc/grid-security/hostkey.pem
ONEAUTH_PATH=/var/lib/one/.one/
DOCKERIMAGE=ubuntu:rocci1.1
```

I have set the same name as the OpenNebula front-end for the hostname (as I want the rOCCI endpoint https://opennebula.my.local.dns:11443) and I have set the path for the hostkey and hostcert obtained in step 2. Moreover
I have set the name for the docker image set in step 4.

6) Finally I can start the rOCCI server
```bash
$ ./start-rocci-server
```