#!/bin/bash

############ Steps ###############


# http://www.openssl.org/docs/fips/UserGuide-2.0.pdf
# http://iase.disa.mil/pki-pke/Pages/admin.aspx and see "Web Servers"
# This section built using https://powhatan.iiie.disa.mil/pki-pke/landing_pages/downloads/unclass-rg-public-key-enabling-apache-v2-4_07092015.pdf

sudo apt install dos2unix unzip aria2 build-essential curl git

# useful packages if on a barebones machine:
sudo apt install man-db vim ufw htop iotop iftop bash-completion unattended-upgrades

###############################################################################
# FIPS #
###############################################################################

# Creeate src folder to keep track of all source files of following steps
cd
mkdir src
cd src

# Navigate to: https://www.openssl.org/source/

aria2c -x5 https://www.openssl.org/source/openssl-fips-2.0.12.tar.gz
aria2c -x5 https://www.openssl.org/source/openssl-fips-2.0.12.tar.gz.sha256
aria2c -x5 https://www.openssl.org/source/openssl-fips-2.0.12.tar.gz.asc
aria2c -x5 https://www.openssl.org/source/openssl-fips-2.0.12.tar.gz.sha1

gunzip openssl-fips-2.0.12.tar.gz
tar xvf openssl-fips-2.0.12.tar

cd openssl-fips-2.0.12

./config
make
sudo make install

cd
###############################################################################
# OpenSSL #
###############################################################################

# Navigate to: https://www.openssl.org/source/
cd src

aria2c -x5 https://www.openssl.org/source/openssl-1.0.2h.tar.gz
aria2c -x5 https://www.openssl.org/source/openssl-1.0.2h.tar.gz.sha256
aria2c -x5 https://www.openssl.org/source/openssl-1.0.2h.tar.gz.asc
aria2c -x5 https://www.openssl.org/source/openssl-1.0.2h.tar.gz.sha1

gunzip openssl-1.0.2h.tar.gz
tar xvf openssl-1.0.2h.tar

cd openssl-1.0.2h

./config --with-fipslibdir=/usr/local/ssl/fips-2.0/lib/ --prefix=/usr
make depend
sudo make install

cd

###############################################################################
# DoD Certs #
###############################################################################

cd src

aria2c -x5 http://iasecontent.disa.mil/pki-pke/Certificates_PKCS7_v4.1u6_DoD.zip

unzip Certificates_PKCS7_v4.1u6_DoD.zip

cd Certificates_PKCS7_v4.1u6_DoD

openssl pkcs7 -in Certificates_PKCS7_v4.1u6_DoD.pem.p7b -print_certs -out DoD_CAs.pem

# if no complaints about fips after following commmand, then the fips stuff above worked
openssl x509 -in DoD_PKE_CA_chain.pem -subject -issuer -fingerprint -noout
openssl smime -verify -in Certificates_PKCS7_v4.1u6_DoD.sha256 -inform DER -CAfile DoD_PKE_CA_chain.pem | dos2unix | sha256sum -c

# strip the email certs from the ca chain
cd ~/git
git clone https://github.com/rarawls/strip_from_certchain.git
chmod +x strip_from_certchain/strip_from_certchain.py

cd src/Certificates_PKCS7_v4.1u6_DoD
~/git/strip_from_certchain/strip_from_certchain.py EMAIL DoD_CAs.pem

###############################################################################
# DoD Certificate Revocation Lists (CRL)  #
###############################################################################

# TODO: CRL? and automate it: http://iase.disa.mil/pki-pke/interoperability/Pages/index.aspx (see "CRLAutoCache for Linux 2.05 - NIPRNet *PKI" under "interoperability tools")
# https://powhatan.iiie.disa.mil/pki-pke/downloads/unclass-crlautocache_linux_2-05_nipr.tar.gz

# More info @
# https://wiki.nps.edu/display/~mcgredo/Apache+Configuration+for+CAC+Card+Authentication

###############################################################################
# FIPS Apache #
###############################################################################

# TODO: Make/Install FIPS-enabled Apache
# See https://wiki.openssl.org/index.php/FIPS_Library_and_Apache

###############################################################################
# SSL/TLS/HTTPS Hardening #
###############################################################################

# TODO: Automate
# Pick secure protocols - great resources below
# https://wiki.mozilla.org/Security/Server_Side_TLS
# https://mozilla.github.io/server-side-tls/ssl-config-generator/
# https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=apache-2.4.7&openssl=1.0.2h&hsts=yes&profile=modern

# Now check your config for safety:
# https://www.ssllabs.com/ssltest/

###############################################################################
# DoD-Signed Certificate
###############################################################################

# TODO: Obtain DoD SSL Certificate
# TODO: Validate? ->
#		* http://iase.disa.mil/pki-pke/interoperability/Pages/index.aspx
#		* http://www.dtic.mil/whs/directives/corres/pdf/852002p.pdf
#		* http://www.dtic.mil/whs/directives/corres/pdf/852003p.pdf


###############################################################################
# Other Sources to Reference #
###############################################################################

# FIPS-140

###############################################################################
# Other References
###############################################################################

# https://httpd.apache.org/docs/2.4/mod/mod_log_config.html
# https://httpd.apache.org/docs/2.4/mod/mod_authz_core.html
# https://httpd.apache.org/docs/2.4/mod/mod_ssl.html
# https://httpd.apache.org/docs/2.4/howto/auth.html
# https://httpd.apache.org/docs/2.4/howto/access.html
# http://www.modssl.org/docs/2.8/ssl_reference.html#table4

# http://www.dwheeler.com/essays/apache-cac-configuration.html
