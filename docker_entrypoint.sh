#!/bin/bash

export HOST_IP=$(ip -4 route list match 0/0 | awk '{print $3}')

#properties emission
echo 'version: 2' > /root/start9/stats.yaml
echo 'data:' >> /root/start9/stats.yaml
PASS=$(yq e ".master-password" /root/start9/config.yaml)
yq -n e ".masterPassword = \"$PASS\"" > /root/accounts.yaml
NUM_ACCOUNTS=$(yq e ".accounts | length" /root/start9/config.yaml)
for i in $(seq 0 $(($NUM_ACCOUNTS-1)))
do
	TYPE=$(yq e ".accounts[$i].connection-settings.type" /root/start9/config.yaml)
	NAME=$(yq e ".accounts[$i].name" /root/start9/config.yaml)
	ACCOUNT_PASS=$(yq e ".accounts[$i].password" /root/start9/config.yaml)
	if [[ $ACCOUNT_PASS -ne "null" ]]
	then
		yq -i e ".accounts[$i].password = $ACCOUNT_PASS" /root/accounts.yaml
		echo "  $NAME Password:"
		echo "    value: \"$ACCOUNT_PASS\"" >> /root/start9/stats.yaml
	else
		echo "  $NAME Password: \"$PASS\"" >> /root/start9.yaml
	fi
	echo '    type: string' >> /root/start9/stats.yaml
	echo "    description: Password to use with the account \"$NAME\"" >> /root/start9/stats.yaml
	echo '    copyable: true' >> /root/start9/stats.yaml
	echo '    qr: false' >> /root/start9/stats.yaml
	echo '    masked: true' >> /root/start9/stats.yaml
	if [[ $TYPE -eq "internal" ]]
	then
		URL="$(yq e ".accounts[$i].connection-settings.address" /root/start9/config.yaml)":10009
		yq -i e ".accounts[$i] = {\"name\":\"$NAME\", \"serverUrl\":\"$URL\", \"certificatePath\":\"/root/start9/public/lnd/tls.cert\", \"macaroonPath\":\"/root/start9/public/lnd/admin.macaroon\" }" /root/accounts.yaml
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
echo ACCOUNT_CONFIG_PATH=/root/accounts.yaml > .env.local
exec npm start
