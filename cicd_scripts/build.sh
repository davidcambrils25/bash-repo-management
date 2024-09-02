#!/bin/bash

SSH_USER=$1
HOST=$2

# Define the variables to be modified
DEVROOT_NEW=$3
CURRPROJ_NEW=$4
UXBUILD_NEW="$4/UXBUILD"

SED_CMD1="sed -i 's|^export DEVROOT=.*|export DEVROOT=\"$DEVROOT_NEW\"|' ~/.bashrc"
SED_CMD2="sed -i 's|^export CURRPROJ=.*|export CURRPROJ=\"$CURRPROJ_NEW\"|' ~/.bashrc"
SED_CMD3="sed -i 's|^export UXBUILD=.*|export UXBUILD=\"$UXBUILD_NEW\"|' ~/.bashrc"

ssh -i ~/.ssh/github-runner $SSH_USER@$HOST "
$SED_CMD1 && $SED_CMD2 && $SED_CMD3
"

ssh -i ~/.ssh/github-runner $SSH_USER@$HOST 'source ~/.bashrc && \
cd ${DEVROOT}/LinuxBuild && \
. ./setenv && CardDemo && env && . ./fixdir && pwd && \
cd ${DEVROOT}/LinuxBuild && . ./compile all'
