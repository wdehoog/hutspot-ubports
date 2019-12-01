---
title: Spotify Player on your phablet
nav_order: 4
layout: default
---
### Spotify Player on your UBports phone
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

### Remark
I tried to crossbuild spotifyd with it's pulseaudio backend but it fails. If you know how to fix that please let me know.
