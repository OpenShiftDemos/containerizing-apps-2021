#!/bin/bash

export GUID=$(echo $WORKSHOP_VARS | jq -r ".guid")
export SSH_USER=$(echo $WORKSHOP_VARS | jq -r ".user")
export SSH_PASSWORD=$(echo $WORKSHOP_VARS | jq -r ".password")
export SSH_HOST=$(echo $WORKSHOP_VARS | jq -r ".ssh_host")
export OS_API=$(echo $WORKSHOP_VARS | jq -r ".openshift_api_url")
export OS_CONSOLE=$(echo $WORKSHOP_VARS | jq -r ".openshift_console_url")