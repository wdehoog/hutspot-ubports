---
title: Searching
parent: Operating
nav_order: 3
layout: default
---
## Searching
Enter text in the search field and press the Enter key.

### What to Search
The app can search for Albums, Artists, Playlists and Tracks. Select the category from the select box.

### Wildcards
Spotify web-api search supports the '*' wildcard (max. 2). It does not seem to search for substrings so if for example you search for 'Gubai' you will not find 'Gubaidulina'. When searching for 'Gubai_' you will find her.

Hutspot will append a '*' to the search string if not yet present to make searching easier but what if you want to search for a specific string? Then you don't want the wildcard to be added. So only if no wildcard is present in the query and no dash and no quote wildcard character is added at the end.

### Field Filters
Spotify web-api search supports the use of field filters. Hutspot checks for *album*, *artist*, *genre*, *track* and *year*. If one of these filters is present no wildcard will be added.
An example of using these field filters:
```
artist:shosta* album:symph*
```

For more information on query possibilities and syntax see the [Spotify Web-API Reference](https://developer.spotify.com/documentation/web-api/reference/search/search/).
