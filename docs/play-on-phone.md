---
title: Spotify Player on your phablet
nav_order: 4
layout: default
---

## Librespot
[Librespot](https://github.com/librespot-org/librespot) is a Spotify Connect player written in Rust. Hutspot has som extra functionality to use Librespot and reuse it's authorization data.

This is how I use it.

Librespot can save the credentials and reuse them later. To create them run once on the command line:

```
librespot -n Phablet --cache ~/.cache/hutspot.wdehoog/hutspot.wdehoog/ -u <yourusername>
```

you will be prompted for your password. The credentials will be saved in the specified cache directory in a file called ``credentials.json``. Note: if this directory is accessible by ``hutspot`` it can use the credentials to register itself with other players. Ofcourse ``~/.cache/hutspot.wdehoog/hutspot.wdehoog/`` is such a directory.

When launching Librespot and specifying the same cache directory the credentials will be loaded:

```
librespot -n Phablet --device-type smartphone -b 320 --backend alsa --device pulse --cache ~/.cache/hutspot.wdehoog/hutspot.wdehoog/
```

I have a script that launches Librespot with the correct settings and setup an ``upstart`` job to start/stop it.
The file is ``/home/phablet/.config/upstart/librespot.conf`` and contains:

```
description "Librespot"

exec /home/phablet/librespot/launch.sh
```

As you see the script and the Librespot executable are located in ``/home/phablet/librespot/``.

The contents of launch.sh is:

```
#!/bin/sh

export PULSE_PROP='media.role=multimedia'

LIBRESPOT_DIR=/home/phablet/librespot

$LIBRESPOT_DIR/librespot -n Phablet --device-type smartphone -b 320 --enable-volume-normalisation --backend alsa --device pulse --cache ~/.cache/hutspot.wdehoog/hutspot.wdehoog/
```

If everything is setup correctly you can now do ``start librespot`` and ``stop librespot`` to start/stop the service. Hutspot can do this as well.

## Spotifyd 
One option is to install [spotifyd](https://github.com/Spotifyd/spotifyd/releases) on your phone. For example I use 0.2.19 from  spotifyd-2019-10-06-armv6-slim.zip on by opo. 

This version does not have the pulseaudio backend. It will still work but you will have to take care of setting an environment variable in order for the volume controls to work:

```
#!/bin/sh

export PULSE_PROP='media.role=multimedia'
./spotifyd
```

The easiest way to set it up is creating a config file as described in the [README from spotifyd](https://github.com/Spotifyd/spotifyd).


A problem is the audio getting choppy due to the phone being suspended when the display goes dark. Currently this is solved using a DBus call to `powerd` (requestSysState) by Hutspot when it is playing a track. If Hutspot crashes or quits it might not have notified `powerd` but powerd takes care of that (says [wiki](https://wiki.ubuntu.com/powerd).

### Config file
Spotifyd expects it's config file in ~/.config/spotifyd/spotifyd.conf'. It can be overriden though (`--config-path`).
Mine contains:

```
username = xxxxx
password = xxxxx

backend = alsa
device = pulse
control = pulse
mixer = Master
volume_controller = alsa

device_name = Phablet
bitrate = 320
cache_path = /home/phablet/.cache/spotifyd
no_audio_cache = true

volume_normalisation = true
normalisation_pregain = -10
zeroconf_port = 1234

```

I have put my spotify credentials in the config file. This is not mandatory. The Spotifyd website mentions other ways of authentication.

### Remarks
I tried to crossbuild spotifyd with it's pulseaudio backend but it fails. If you know how to fix that please let me know.


## Raspotify
[Raspotify](https://github.com/dtcooper/raspotify) is Librespot build for the RaspberryPI. I tested version 0.15.0 and started it from the console with:

```
librespot -n Phablet --device-type smartphone -b 320 -u <yourusername> --enable-volume-normalisation
```

you will be prompted for your password.

### Librespot-java

I also tried [Librespot-java](https://github.com/librespot-org/librespot-java) using jre/jkd from Oracle and OpenJDK but this makes the my phone reboot instantly.
