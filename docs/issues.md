---
title: Issues
nav_order: 6
layout: default
---
## Main Issues

Please report any problems or requests in the [Github Issue Tracker](https://github.com/wdehoog/hutspot-ubports/issues)


#### Device Discovery
The list of devices to play music on is managed by Spotify so Spotify needs to know the device exists. The official apps and applications discover new devices using zeroconf and some http requests. Hutspot cannot do this.

#### Network Disconnections
Hutspot cannot detect network disconnections of your phone.

#### No Player Queue
The Spotify Web-API does not support a player queue. You will have to use Playlists to have some of sort of queue functionality.

#### Playlist Snapshots
When you play a playlist you are in fact playing a specific snapshot of that playlist. This means that any modification to that playlist will not be reflected in the list being Played. For example added tracks will not show up until the playlist is restarted.

As Hutspot uses a playlist for playing seperate tracks this is a problem. Currently Hutspot, when reaching the end of the last track, tries to determine if the playlist has been modified and then to load the fresh snapshot and continue with the new tracks. Unfortunately this is not working correctly.