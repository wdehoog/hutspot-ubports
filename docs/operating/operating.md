---
title: Operating
nav_order: 3
layout: default
has_children: true
has_toc: false
permalink: operating
---
## Operating

### Authorization 
At startup authorization is done using a webview or external browser window. The tokens are saved so a next startup might not need a new login. Still this webview/browser window might appear. When authorization is successful you can then switch to the app.


### Lists
Hutspot loads items per set using a configured number (max. 50). When there are more results available the next set will be loaded when the list is scrolled to it's end.

Various actions can triggered using the context menu (long press) of a List Item.


### Player Queue
The Spotify Web-API does not support a player queue. Therefore Hutspot uses it's own special queue playlist. This special *Queue Playlist* is used for :

 * When you want to play or queue a single track
 * When you want to play a list of recommended tracks

The name of the playlist to use can be configured in the Settings. It's default value is 'Hutspot Queue'.

### Various
 * Device Page: A list is shown of known play devices. The current one is highlighted. Using the context menu (long press) you select another device.
 * The Playing page shows what is currently playing and contains various player controls.

## Indicator Panel
Since Hutspot implements the [Mpris2](https://specifications.freedesktop.org/mpris-spec/latest/) interface you can use the player controls on the Indicator Panel to command it.


