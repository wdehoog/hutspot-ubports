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

Various actions can be triggered by clicking on an item or using the context menu (long press).


### Various
 * Player Area: at the bottom from most pages is the Player Area which allows you to play/pause the music. There is a Home button to go back to the main menu and when you click on the image you open the Playing page.
 * Device Page: A list is shown of known play devices. The current one is highlighted. Using the context menu (long press) you select another device.
 * The Playing page shows what is currently playing and contains various player controls.


### History
It seems that Spotify does not update the Recently Used list for tracks started using the web-api. Hutspot keeps track of the Albums, Artists and Playlists you visited.


## Indicator Panel
Since Hutspot implements the [Mpris2](https://specifications.freedesktop.org/mpris-spec/latest/) interface you can use the player controls on the Indicator Panel to command it.


