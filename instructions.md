# ThunderHub

## Configuration

The Master Password setting will be the password you use to log into all the accounts you set up for ThunderHub.
If you set an account-specific password, that will override the master password for that account.

ThunderHub's configuration will automatically load the settings for the LND node running on your StartOS server. However, it can also connect to an external LND node either via manual configuration or an [LNDConnect](https://github.com/LN-Zap/lndconnect/blob/master/lnd_connect_uri.md) URL.

## Limitations

- It is currently not possible to connect to external LND nodes on a ".onion" address.

## Notes

All of your funds and data reside within LND. ThunderHub is *just* an interface to interact with your LND node.
As such, it is safe to uninstall and reinstall ThunderHub as you please without fear of loss. Additionally, to ensure 
the safety of your funds, you must back up your LND node, not ThunderHub.