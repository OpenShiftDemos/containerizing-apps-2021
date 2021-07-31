#!/bin/bash

read -p "This script is to jump over the previous labs, is that really what you want to do? [y/N] " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    sudo subscription-manager repos --enable=ansible-2-for-rhel-8-x86_64-rpms
    sudo yum install -y ansible
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    ansible-playbook -i "localhost," -c local $DIR/jump-to-here-playbook.yml
fi
