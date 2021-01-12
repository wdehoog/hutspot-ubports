---
title: Recommendations
parent: Operating
nav_order: 4
layout: default
---
## Recommendations
The Recommended page allows to manage Recommendation Sets which allows Spotify to recommend tracks. A Recommendation Set can consist of Seeds (Artists, Tracks, Genres) and Attributes. Hutspot can have multiple of these Sets.

A Recommendation Set must be linked to a playlist. This playlist will get the recommeded tracks when you want to play them.

The '+' on the Page Header adds a new Set to the list.

Click on a Set to Edit it.

Press and Hold a Set to get the context menu which allows to:

 * Refresh Tracks of the Linked Playlist
 * Link the Set to a Playlist
 * Rename The Set
 * Edit the Set
 * Delete The Set

For more see the [Spotify WebAPI docs](https://developer.spotify.com/documentation/web-api/reference/browse/get-recommendations/).


### Export/Import
The current Recommendation Sets (name, linked Playlist, Seeds and Attributes) are saved in- and loaded from the configuration file. They can also be exported (saved) and imported (loaded). This is done using the Content-Hub mechanism. Selecting the FileManager as the source or destination allows you to use previously saved data. Note that this does not save the recommended tracks but only the (maximum five) Seeds and Attributes. (This option is probably not very useful but I wanted to see how Content-Hub works.)

Use the buttons on the Page Header to start these actions.

## Recommended
This page is used to edit the seeds and attribtes of a Recommendation Set.

The api allows to specify a total of five seeds (Artists, Tracks or Genres). Hutspot allows to add Artists and Tracks using the context menu on an Artist or Track. This can only be done on other pages then the Recommended page where the list can contain Artists or Tracks. The Genres can be added on this page using the Tag-button on the page header.

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
To play the recommended tracks use the linked Playlist. You can also add the current recommendations to another playlist. Use the import-button on the page header to do this.


### Various
 * There is a refresh button on the page header to get new recommendations based on the current seeds and attributes.
 * There is also a Reset button to remove the Seeds and set the Attributes back to their default value.
