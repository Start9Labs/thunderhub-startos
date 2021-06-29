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
	echo Account $i
	TYPE=$(yq e ".accounts[$i].connection-settings.type" /root/start9/config.yaml)
	echo $TYPE
	NAME=$(yq e ".accounts[$i].name" /root/start9/config.yaml)
	ACCOUNT_PASS=$(yq e ".accounts[$i].password" /root/start9/config.yaml)
	if [[ "$ACCOUNT_PASS" != "null" ]] && [[ "$ACCOUNT_PASS" != "~" ]]
	then
		yq -i e ".accounts[$i].password = $ACCOUNT_PASS" /root/accounts.yaml
		echo "  $NAME Password:"
		echo "    value: \"$ACCOUNT_PASS\"" >> /root/start9/stats.yaml
	else
		echo "  $NAME Password:" >> /root/start9/stats.yaml
		echo "    value: \"$PASS\"" >> /root/start9/stats.yaml
	fi
	echo '    type: string' >> /root/start9/stats.yaml
	echo "    description: Password to use with the account \"$NAME\"" >> /root/start9/stats.yaml
	echo '    copyable: true' >> /root/start9/stats.yaml
	echo '    qr: false' >> /root/start9/stats.yaml
	echo '    masked: true' >> /root/start9/stats.yaml
	if [[ "$TYPE" == "internal" ]]
	then
		echo INTERNAL
		URL="$(yq e ".accounts[$i].connection-settings.address" /root/start9/config.yaml)":10009
		yq -i e ".accounts[$i] = {\"name\":\"$NAME\", \"serverUrl\":\"$URL\", \"certificatePath\":\"/root/start9/public/lnd/tls.cert\", \"macaroonPath\":\"/root/start9/public/lnd/admin.macaroon\" }" /root/accounts.yaml
	elif [[ "$TYPE" == "external" ]]
	then
		echo EXTERNAL
		URL=$(yq e ".accounts[$i].connection-settings.addressext" /root/start9/config.yaml):$(yq e ".accounts[$i].connection-settings.port" /root/start9/config.yaml)
		CERT=$(yq e ".accounts[$i].connection-settings.certificate" /root/start9/config.yaml)
		MACAROON=$(yq e ".accounts[$i].connection-settings.macaroon" /root/start9/config.yaml)
		yq -i e ".accounts[$i] = {\"name\":\"$NAME\", \"serverUrl\":\"$URL\", \"certificate\":\"$CERT\", \"macaroon\":\"$MACAROON\" }" /root/accounts.yaml
	elif [[ "$TYPE" == "lndconnect" ]]
	then
		echo LNDCONNECT
		LNDCONNECT=$(yq e ".accounts[$i].connection-settings.lndconnect-url" /root/start9/config.yaml)
		URL=$(echo $LNDCONNECT | cut -c 14- | cut -d '?' -f 1)
		PARAMS=$(echo $LNDCONNECT | cut -d '?' -f 2)
		if [[ $(echo $PARAMS | cut -c 1-4) == "cert" ]]
		then
			CERT_RAW=$(echo $PARAMS | cut -d '&' -f 1 | cut -c 6-)
			PAD=$($(for (( c=0; c < $((3 - $(echo $CERT_RAW | awk '{print length}') % 3)); c++)); do echo -n '='; done) | sed 's/===$//g')
			echo "PAD = $PAD"
			CERT=$(echo "-----BEGIN CERTIFICATE-----$(echo $CERT_RAW$PAD | base64 -d | base64 -w 64)-----END CERTIFICATE-----" | base64 | tr -d '\n')
			MACAROON=$(echo $PARAMS | cut -d '&' -f 2 | cut -c 10-)
			yq -i e ".accounts[$i] = {\"name\":\"$NAME\", \"serverUrl\":\"$URL\", \"certificate\":\"$CERT\", \"macaroon\":\"$MACAROON\" }" /root/accounts.yaml
		elif [[ $(echo $PARAMS | cut -c 1-8) == "macaroon" ]]
		then
			CERT_RAW=$(echo $PARAMS | cut -d '&' -f 1 | cut -c 6-)
			PAD=$(echo $((3 - $(echo $CERT_RAW | awk '{print length}') % 3)) | sed 's/===$//g')
			echo "PAD = $PAD"
			CERT=$(echo "-----BEGIN CERTIFICATE-----$(echo $CERT_RAW$PAD | base64 -d | base64 -w 64)-----END CERTIFICATE-----" | base64 | tr -d '\n')
			MACAROON=$(echo $PARAMS | cut -d '&' -f 2 | cut -c 10-)
			yq -i e ".accounts[$i] = {\"name\":\"$NAME\", \"serverUrl\":\"$URL\", \"certificate\":\"$CERT\", \"macaroon\":\"$MACAROON\" }" /root/accounts.yaml
		else
			echo "INVALID LNDCONNECT URL: Certificate or Macaroon is incorrectly formatted"
			exit
		fi
	fi
done
cat /root/accounts.yaml
echo ACCOUNT_CONFIG_PATH=/root/accounts.yaml > .env.local
echo TOR_PROXY_SERVER="socks://$HOST_IP:9050" >> .env.local
echo LOG_LEVEL='debug' >> .env.local
exec npm start
