# Thunderhub

## Configuration

The Master Password setting will be the password you use to log into all of the accounts you set up for Thunderhub.
If you set an account specific password, that will override the master password for that account.

Thunderhub's config will automatically load the configuration for the LND node running on your Embassy, however it
can take an external LND node either via manual configuration or an [LNDConnect](https://github.com/LN-Zap/lndconnect/blob/master/lnd_connect_uri.md) URL.

## Limitations

- It is currently not possible to connect to external LND nodes on a ".onion" address.

## Notes

All of your funds and data reside within LND, Thunderhub is *just* an interface to interact with your LND node.
As such it is safe to uninstall and reinstall Thunderhub as you please without fear of loss. Additionally, to ensure
safety of your funds you must back up your LND node, not Thunderhub.
