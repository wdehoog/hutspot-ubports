---
title: Recommended
parent: Operating
nav_order: 4
layout: default
---

## Recommended
The Recommended page allows to get recommended tracks from Spotify. These recommendations can be based on Artists, Tracks, Genres and Attributes. For more see the [Spotify WebAPI docs](https://developer.spotify.com/documentation/web-api/reference/browse/get-recommendations/).

The api allows to specify a total of five seeds (Artists, Tracks or Genres). Hutspot allows to add Artists and Tracks using the context menu on an Artist or Track. The Genres can be added on the Recommended page using the Tag-button on the page header.

The Attributes can be specified to be used or not using the checkbox. The chevron allows to show/hide the sliders used to modify the Attribute values.

Currently Hutspot supports the following attributes

 * tempo
 * energy
 * danceability
 * instrumentalness
 * speechiness
 * acousticness
 * liveness
 * positiveness
 * popularity

### Playlist
To play the recommended tracks Hutspot can add them to a playlist named "Recommendations [hutspot]". Use the import-button on the page header to do this.

### Various
 * There is a refresh button on the page header to get new recommendations based on the current seeds and attributes.