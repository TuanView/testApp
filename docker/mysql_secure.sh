#!/bin/bash

# This script is to run the mysql_secure_installation in batch mode.
# The 'mysql_secure_installation' is used to be called in the 
#   install-dependencies.sh
# after install mariaDB. It requires to init/setup the password .
#
# Here we set the root password is 'secret'

service mysql start
mysql_secure_installation << EOF

y
secret
secret
y
y
y
y
EOF

