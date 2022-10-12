#!/bin/bash

#         o   ^__^
#          o  (oo)\_______
#             (__)\       )\/\
#                 ||----w |
#                 ||     ||

#######################################################################################################################################

echo "`date +"%m/%d/%y_%H:%M:%S"` : < LOOK'S GOOD! >"

#######################################################################################################################################

echo "`date +"%m/%d/%y_%H:%M:%S"` : < Checking for new SSL/TLS certs... >"
export CRT="${CRT:=nginx-selfsigned.crt}"
export KEY="${KEY:=nginx-selfsigned.key}"

if [ -f "/etc/nginx/certs/$CRT" ]
then
    echo "`date +"%m/%d/%y_%H:%M:%S"` : < Updating SSL/TLS certs... >"
    cp /etc/nginx/certs/$CRT /etc/ssl/certs/$CRT
fi

if [ -f "/etc/nginx/private/$KEY" ]
then
    echo "`date +"%m/%d/%y_%H:%M:%S"` : < Updating SSL/TLS key... >"
    cp /etc/nginx/private/$KEY /etc/ssl/private/$KEY
fi

echo "`date +"%m/%d/%y_%H:%M:%S"` : < Done >"

#######################################################################################################################################

echo "`date +"%m/%d/%y_%H:%M:%S"` : < Double checking SSL/TLS for Nginx... >"
cd /etc/nginx/conf.d
# CRT - double check that the file exists
#export CRT="${CRT:=nginx-selfsigned.crt}"
if [ -f "/etc/ssl/certs/$CRT" ]
then
    # set crt file in the nginx.conf file
    sed -i "/ssl_certificate \//c\\\tssl_certificate \/etc\/ssl\/certs\/$CRT;" myapp.conf
fi
# KEY - double check that the file exists
#export KEY="${KEY:=nginx-selfsigned.key}"
if [ -f "/etc/ssl/private/$KEY" ]
then
    # set key file in the nginx.conf file
    sed -i "/ssl_certificate_key \//c\\\tssl_certificate_key \/etc\/ssl\/private\/$KEY;" myapp.conf
fi
echo "`date +"%m/%d/%y_%H:%M:%S"` : < Done >"

#######################################################################################################################################

echo "`date +"%m/%d/%y_%H:%M:%S"` : < Here is the content of /etc/nginx/nginx.conf >"
ls -l /etc/nginx/nginx.conf
cat /etc/nginx/nginx.conf
echo "`date +"%m/%d/%y_%H:%M:%S"` : < Here is the content of /etc/nginx/conf.d/myapp.conf >"
ls -l /etc/nginx/conf.d/myapp.conf
cat /etc/nginx/conf.d/myapp.conf
echo "`date +"%m/%d/%y_%H:%M:%S"` : < Done >"

#######################################################################################################################################

echo "`date +"%m/%d/%y_%H:%M:%S"` : < Starting Nginx... >"
nginx -g 'daemon off;' &
nginx -s reload &
sleep 10
echo "`date +"%m/%d/%y_%H:%M:%S"` : < Done >"

#######################################################################################################################################

echo "`date +"%m/%d/%y_%H:%M:%S"` : < Recovering Notebooks... >"
if ! [ -z "$(ls -A /persisted_notebook)" ]
then
    cp -f -p -r /persisted_notebook/. /home/jovyan/
fi
echo "`date +"%m/%d/%y_%H:%M:%S"` : < Done >"

#######################################################################################################################################

echo "`date +"%m/%d/%y_%H:%M:%S"` : < Searching for complementary startup script... >"
if [ -s /data/start.me.up.before.you.go.go.sh ]
then
    cp -f -p /data/start.me.up.before.you.go.go.sh /home/jovyan/start.me.up.before.you.go.go.sh
fi
echo "`date +"%m/%d/%y_%H:%M:%S"` : < Done >"

#######################################################################################################################################

echo "`date +"%m/%d/%y_%H:%M:%S"` : < Running complementary startup script... >"
sh /home/jovyan/start.me.up.before.you.go.go.sh
echo "`date +"%m/%d/%y_%H:%M:%S"` : < Done >"

#######################################################################################################################################

echo "`date +"%m/%d/%y_%H:%M:%S"` : < Launching cron... >"
cron
echo "`date +"%m/%d/%y_%H:%M:%S"` : < Done >"

#######################################################################################################################################

cd ${HOME}/work

echo "`date +"%m/%d/%y_%H:%M:%S"` : < Dumb init... >"

exec dumb-init $@
