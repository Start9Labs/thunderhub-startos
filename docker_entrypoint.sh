#!/bin/bash

export HOST_IP=$(ip -4 route list match 0/0 | awk '{print $3}')

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
	if [[ "$TYPE" == "internal" ]]
	then
		URL=lnd.embassy:10009
		yq -i e ".accounts[$i] = {\"name\":\"$NAME\", \"serverUrl\":\"$URL\", \"certificatePath\":\"/mnt/lnd/tls.cert\", \"macaroonPath\":\"/mnt/lnd/admin.macaroon\" }" /root/accounts.yaml
		while ! test -f /mnt/lnd/tls.cert
		do
			"Waiting for LND cert to be generated..."
			sleep 1
		done
	elif [[ "$TYPE" == "external" ]]
	then
		URL=$(yq e ".accounts[$i].connection-settings.addressext" /root/start9/config.yaml):$(yq e ".accounts[$i].connection-settings.port" /root/start9/config.yaml)
		CERT=$(yq e ".accounts[$i].connection-settings.certificate" /root/start9/config.yaml)
		MACAROON=$(yq e ".accounts[$i].connection-settings.macaroon" /root/start9/config.yaml)
		yq -i e ".accounts[$i] = {\"name\":\"$NAME\", \"serverUrl\":\"$URL\", \"certificate\":\"$CERT\", \"macaroon\":\"$MACAROON\" }" /root/accounts.yaml
	elif [[ "$TYPE" == "lndconnect" ]]
	then
		LNDCONNECT=$(yq e ".accounts[$i].connection-settings.lndconnect-url" /root/start9/config.yaml)
		URL=$(echo -n $LNDCONNECT | cut -c 14- | cut -d '?' -f 1)
		PARAMS=$(echo -n $LNDCONNECT | cut -d '?' -f 2)
		if [[ $(echo -n $PARAMS | cut -c 1-4) == "cert" ]]
		then
			CERT_POS=1
			MACAROON_POS=2
		elif [[ $(echo $PARAMS | cut -c 1-8) == "macaroon" ]]
		then
			CERT_POS=2
			MACAROON_POS=1
		else
			echo "INVALID LNDCONNECT URL: Certificate or Macaroon is incorrectly formatted"
			exit
		fi
		CERT_RAW=$(echo -n $PARAMS | cut -d '&' -f $CERT_POS | cut -c 6- | tr '_-' '/+' | tr -d '\n')
		CERT_PAD=$(printf '=%.0s' $(seq 1 $((4 - $(echo -n $CERT_RAW | awk '{print length}') % 4))) | sed 's/====$//g')
		CERT=$(echo -en "-----BEGIN CERTIFICATE-----\n$(echo -n $CERT_RAW$CERT_PAD | base64 -d | base64 -w 64)\n-----END CERTIFICATE-----" | base64 | tr -d '\n')
		MACAROON_RAW=$(echo -n $PARAMS | cut -d '&' -f $MACAROON_POS | cut -c 10- | tr '_-' '/+' | tr -d '\n')
		MACAROON_PAD=$(printf '=%.0s' $(seq 1 $((4 - $(echo -n $MACAROON_RAW | awk '{print length}') % 4))) | sed 's/====$//g')
		MACAROON=$MACAROON_RAW$MACAROON_PAD
		yq -i e ".accounts[$i] = {\"name\":\"$NAME\", \"serverUrl\":\"$URL\", \"certificate\":\"$CERT\", \"macaroon\":\"$MACAROON\" }" /root/accounts.yaml
	fi
	echo ACCOUNT PASS
	echo $ACCOUNT_PASS
	if [[ "$ACCOUNT_PASS" != "null" ]] && [[ "$ACCOUNT_PASS" != "~" ]]
	then
		echo "  $NAME Password:" >> /root/start9/stats.yaml
		echo "    value: \"$ACCOUNT_PASS\"" >> /root/start9/stats.yaml
		yq -i e ".accounts[$i].password = \"$ACCOUNT_PASS\"" /root/accounts.yaml
	else
		echo "  $NAME Password:" >> /root/start9/stats.yaml
		echo "    value: \"$PASS\"" >> /root/start9/stats.yaml
	fi
	echo '    type: string' >> /root/start9/stats.yaml
	echo "    description: Password to use with the account \"$NAME\"" >> /root/start9/stats.yaml
	echo '    copyable: true' >> /root/start9/stats.yaml
	echo '    qr: false' >> /root/start9/stats.yaml
	echo '    masked: true' >> /root/start9/stats.yaml
done
echo ACCOUNT_CONFIG_PATH=/root/accounts.yaml > .env.local
echo TOR_PROXY_SERVER="socks://$HOST_IP:9050" >> .env.local
echo LOG_LEVEL='debug' >> .env.local
exec npm start
