#!/usr/bin/env bash

vagrant halt
vagrant destroy -f
rm -rf .vagrant/
rm vm01.vbox.local.dev-192.168.100.101.txt
ls -al

exit 0
