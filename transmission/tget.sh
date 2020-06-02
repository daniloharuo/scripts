#!/bin/bash

openssl version &> /dev/null
if [ $? -ne 0 ]; then
  echo "openssl not found."
  exit
fi

jq --version &> /dev/null
if [ $? -ne 0 ]; then
  echo "jq not found. Try brew install jq"
  exit
fi

tget_protocol="http"
tget_host="192.168.1.11"
tget_port="9091"
tget_route="/transmission/rpc"
tget_url="$tget_protocol://$tget_host:$tget_port$tget_route"
tget_user=$(openssl rsautl -decrypt -inkey ~/.ssh/id_rsa -in ~/.personal_secret | grep username | awk '{print $2}')
tget_pass=$(openssl rsautl -decrypt -inkey ~/.ssh/id_rsa -in ~/.personal_secret | grep password | awk '{print $2}')
tget_session=$(curl -s $tget_url -u $tget_user:$tget_pass | sed 's/.*<code>//g;s/<\/code>.*//g')

curl -s -u $tget_user:$tget_pass $tget_url -H "$tget_session" -d '{"arguments": {"fields": [ "name", "percentDone", "status", "eta", "rateDownload", "rateUpload" ]},"method": "torrent-get"}' | jq
