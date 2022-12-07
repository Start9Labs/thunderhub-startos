import { compat, types as T } from "../deps.ts";

export const getConfig: T.ExpectedExports.getConfig = compat.getConfig({
    "master-password": {
      "type": "string",
      "name": "Master Password",
      "description":
        "The password for any account that does not specify its own password",
      "nullable": false,
      "default": {
        "charset": "a-z,A-Z,0-9",
        "len": 22,
      },
      "masked": true,
    },
    "accounts": {
      "type": "list",
      "subtype": "object",
      "name": "Accounts",
      "description": "List of LND instances to manage",
      "range": "[1,*)",
      "spec": {
        "unique-by": "connection-settings",
        "display-as": "{{name}}",
        "spec": {
          "name": {
            "type": "string" as const,
            "name": "Account Name",
            "description": "Name of this account in the login list",
            "nullable": false,
            "warning":
              'Do not use the name "Master" here or the properties menu will confuse you.\n',
          },
          "connection-settings": {
            "type": "union" as const,
            "name": "Connection Settings",
            "tag": {
              "id": "type",
              "name": "Type",
              "description":
                "- Internal: The LND service installed to your Embassy\n- External: An LND node running on a different device\n- LNDConnect: An LNDConnect URL\n",
              "variant-names": {
                "internal": "Internal",
                "external": "External Manual",
                "lndconnect": "External LNDConnect",
              },
            },
            "default": "internal",
            "variants": {
              "internal": {},
              "external": {
                "addressext": {
                  "type": "string" as const,
                  "name": "Public Address",
                  "description":
                    "The public address of your LND node, NOTE that external tor nodes do not work yet.",
                  "nullable": false,
                },
                "port": {
                  "type": "number" as const,
                  "name": "Port",
                  "description": "The gRPC port of your LND node",
                  "nullable": false,
                  "range": "[0,65535]",
                  "integral": true,
                  "default": 10009,
                },
                "macaroon": {
                  "type": "string" as const,
                  "name": "Admin Macaroon",
                  "description":
                    "Base64 encoded admin macaroon from your LND node",
                  "nullable": false,
                  "pattern": "^[a-zA-Z0-9/+]+[=]{0,2}$",
                  "pattern-description": "Must be a valid base64 string",
                },
                "certificate": {
                  "type": "string" as const,
                  "name": "TLS Certificate",
                  "description":
                    "Base64 encoded tls certificate from your LND node",
                  "nullable": false,
                  "pattern": "^[a-zA-Z0-9/+]+[=]{0,2}$",
                  "pattern-description": "Must be a valid base64 string",
                },
              },
              "lndconnect": {
                "lndconnect-url": {
                  "type": "string" as const,
                  "name": "LNDConnect URL",
                  "description": "LNDConnect URL for your external LND node",
                  "nullable": false,
                  "pattern":
                    "^lndconnect://(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9]):[1-9][0-9]{0,4}[?](cert=[a-zA-Z0-9\\-_]+&macaroon=[a-zA-Z0-9\\-_]+|macaroon=[a-zA-Z0-9\\-_]+&cert=[a-zA-Z0-9\\-_]+)$",
                  "pattern-description": "Must be a valid LNDConnect URL",
                },
              },
            },
          },
          "password": {
            "type": "string" as const,
            "name": "Password",
            "description":
              "Account specific password to use in place of the master password, if left blank you must log into this account using the master password",
            "nullable": true,
            "masked": true,
          },
        },
      },
      "default": [
        {
          "name": "Embassy LND",
          "connection-settings": {
            "type": "internal",
            "address": null,
          },
        },
      ],
    },
});