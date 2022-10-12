#!/bin/bash

# while [ 1 ]
# do
#   echo DOUDOU > /dev/null
#   sleep 20
# done

sleep 1
kinit -kt /etc/security/keytabs/tdp_user.keytab tdp_user@REALM.TDP
sleep 1
touch /home/jovyan/touch.test
