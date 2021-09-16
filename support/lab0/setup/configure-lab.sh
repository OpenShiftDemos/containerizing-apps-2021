#!/bin/bash

echo "" > ~/envfile

export GUID=$(echo $WORKSHOP_VARS | jq -r ".guid")
echo "export GUID=$GUID" >> ~/envfile

export SSH_USER=$(echo $WORKSHOP_VARS | jq -r ".user")
echo "export SSH_USER=$SSH_USER" >> ~/envfile

export SSH_PASSWORD=$(echo $WORKSHOP_VARS | jq -r ".password")
echo "export SSH_PASSWORD=$SSH_PASSWORD" >> ~/envfile

export SSH_HOST=$(echo $WORKSHOP_VARS | jq -r ".ssh_host")
echo "export SSH_HOST=$SSH_HOST" >> ~/envfile

export OS_API=$(echo $WORKSHOP_VARS | jq -r ".openshift_api_url")
echo "export OS_API=$OS_API" >> ~/envfile

export OS_CONSOLE=$(echo $WORKSHOP_VARS | jq -r ".openshift_console_url")
echo "export OS_CONSOLE=$OS_CONSOLE" >> ~/envfile

echo "export OS_REGISTRY=default-route-openshift-image-registry.${OS_CONSOLE#[[:alpha:]]*.}" >> ~/envfile

export OS_USER=$(echo $WORKSHOP_VARS | jq -r ".openshift_username")
echo "export OS_USER=$OS_USER" >> ~/envfile