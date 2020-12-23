Hutspot is currently an unconfined app. This is due to implementing the Mpris2 interface and using a powerd DBus method to prevent the phone from suspending while playing audio.

If you want to run it as a confined one you need to add two policy groups to you system and to the ``hutspot.apparmor`` file.

```
{
    "template": "unconfined",
    "policy_version": 16.04,
    "policy_groups": [
        "audio",
        "content_exchange_source",
        "content_exchange",
        "networking",
        "webview",
        "hold_off_suspend",
        "mpris2"
    ]
}

```

Make your file system writable and

```
sudo cp hold_off_suspend /usr/share/apparmor/easyprof/policygroups/ubuntu/16.04
sudo cp mpris2 /usr/share/apparmor/easyprof/policygroups/ubuntu/16.04
```

and reboot. And remember you will have to repeat these changes after a UBports update.
