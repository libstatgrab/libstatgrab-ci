#!/bin/sh

if [ X`whoami` != Xroot ]; then
	echo "This will need to run as root."
	exit 1
fi

# Should contain a line like:
# FACTER_gitlab_runner_registration_token='xxxxx' export FACTER_gitlab_runner_registration_token 
. ./secrets.sh

FACTER_ci_dir=`pwd` export FACTER_ci_dir

puppet apply --modulepath puppet/modules puppet/manifest.pp
