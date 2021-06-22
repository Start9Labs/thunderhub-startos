#!/bin/bash

export HOST_IP=$(ip -4 route list match 0/0 | awk '{print $3}')

cat /root/start9/config.yaml
echo first
PASS=$(yq e ".master-password" /root/start9/config.yaml)
echo second
yq -n e ".masterPassword = \"$PASS\"" > /root/accounts.yaml
NUM_ACCOUNTS=$(yq e ".accounts | length" /root/start9/config.yaml)
echo $NUM_ACCOUNTS Accounts
for i in $(seq 0 $(($NUM_ACCOUNTS-1)))
do
	TYPE=$(yq e ".accounts[$i].connection-settings.type" /root/start9/config.yaml)
	if [[ $TYPE -eq "internal" ]]
	then
		echo 1
		NAME=$(yq e ".accounts[$i].name" /root/start9/config.yaml)
		echo 2
		URL="$(yq e ".accounts[$i].connection-settings.address" /root/start9/config.yaml)":10009
		echo 3
		yq -i e ".accounts[$i] = {\"name\":\"$NAME\", \"serverUrl\":\"$URL\", \"certificatePath\":\"/root/start9/public/lnd/tls.cert\", \"macaroonPath\":\"/root/start9/public/lnd/admin.macaroon\" }" /root/accounts.yaml
		echo 4
		ACCOUNT_PASS=$(yq e ".accounts[$i].password" /root/start9/config.yaml)
		echo 5
		echo $ACCOUNT_PASS
		if [[ $ACCOUNT_PASS -ne "null" ]]
		then
			echo 6
			yq -i e ".accounts[$i].password = $ACCOUNT_PASS" /root/accounts.yaml
			echo 7
		fi
		echo 8
	elif [[ $TYPE -eq "external" ]]
	then
		echo "Account $i is external"
	elif [[ $TYPE -eq "lndconnect" ]]
	then
		echo "Account $i is lndconnect"
	fi
done
cat /root/accounts.yaml
echo "DONE"
export ACCOUNT_CONFIG_PATH=/root/accounts.yaml
exec sleep 1000000
