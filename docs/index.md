---
title: Introduction
nav_order: 1
layout: default
---
#  Welcome to the Hutspot Documentation
Hutspot is a Spotify controller for UBports. It uses the [Spotify web-api](https://developer.spotify.com/documentation/web-api/). Playing is done on an 'connect' device. It requires a premium Spotify account. 

Main features:

 * Browse Albums/Artists/Playlists
 * Search Albums/Artists/Playlists/Tracks
 * Support for Genres & Moods
 * Follow/Unfollow, Save/Unsave
 * Discover and control Connect Devices
 * Control Play/Pause/Next/Previous/Volume/Shuffle/Replay/Seek
 * Create and Edit Playlists

It does not support saving tracks nor offline playing


## Developing
You can build it with [clickable](http://clickable.bhdouglass.com/en/latest/).

I tried to crossbuild spotifyd with the pulseaudio backend but it fails. If you know how to fix that please let me know.


Please report any problems or requests in the [Github Issue Tracker](https://github.com/wdehoog/hutspot-ubports/issues)

### Thanks
 * Spotify for web api
 * JMPerez for [spotify-web-api-js](https://github.com/JMPerez/spotify-web-api-js)
 * pipacs for [O2](https://github.com/pipacs/o2)
 * librespot-org for [Librespot](https://github.com/librespot-org/librespot)
 * Maciej Janiszewski: co-author of Hutspot for SailfishOS

### License
O2 and spotify-web-api-js have their own license. For Hutspot it is MIT. Some parts are LGPL and/or BSD.

Due to the issues with detecting Spotify capable players this app is not 'plug and play'. Don't use it unless you are willing to mess around.

### Donations
Sorry but I do not accept any donations. I do appreciate the gesture but it is a hobby that I am able to do because others are investing their time as well.

If someone wants to show appreciation for my  work by a donation then I suggest to help support UBports.

