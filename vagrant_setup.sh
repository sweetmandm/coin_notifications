#!/bin/sh

if [ "$(which ansible-playbook)" = "" ] || [ "$(which vagrant)" = "" ]; then
  echo "Error - please make sure you have vagrant and ansible installed."
  exit 1
fi

vagrant up && \
  ansible-playbook -i ansible/hosts ansible/playbook.yml -l dev
