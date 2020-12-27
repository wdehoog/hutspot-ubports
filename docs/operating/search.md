---
title: Searching
parent: Operating
nav_order: 3
layout: default
---
## Searching
Enter text in the search field or select one from the drop-down list and press the Enter key.

### What to Search
The app can search for Albums, Artists, Playlists and Tracks. Select the category from the select box.

### Wildcards
Spotify web-api search supports the '\*' wildcard (max. 2). Hutspot will append a '\*' to the search string if not yet present to make searching easier. If you want to search for a specific string you don't want the wildcard to be added. Therefore it is only added if no wildcard, or underscore or double quote character is present in the query.

### Field Filters
Spotify web-api search supports the use of *field filters*. Hutspot checks for *album*, *artist*, *genre*, *track* and *year*. If one of these filters is present in the query string no wildcard will be added (so you will have to add them yourself).
An example of using these field filters:
```
artist:shosta* album:symph*
```

For more information on query possibilities and syntax see the [Spotify Web-API Reference](https://developer.spotify.com/documentation/web-api/reference/search/search/).

### Manage Search History
The button on the page header opens a new page with the Query History list. Swiping an item to the right will show a button which allows to delete the item. The button on the page header allows to delete all items.  