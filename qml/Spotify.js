/**
 * Code copied from https://github.com/JMPerez/spotify-web-api-js
 */


.pragma library

var _baseUri = 'https://api.spotify.com/v1';
var _accessToken = null;
var _username = null;
var _debug = false;

var scopes_array = [
  "user-library-modify",
  "user-follow-modify",
  "streaming",
  "playlist-read-collaborative",
  "playlist-read-private",
  "playlist-modify-private",
  "playlist-modify-public",
  "user-read-recently-played",
  "user-read-private",
  "user-read-email",
  "user-modify-playback-state",
  "user-read-playback-position",
  "user-read-playback-state",
  "user-read-currently-playing",
  "user-library-read",
  "user-follow-read",
  "user-top-read",
];
var _scope = scopes_array.join(" ");

var tokenLostCallback = null;

//
// Request Stuff
//

function _extend() {
  var args = Array.prototype.slice.call(arguments);
  var target = args[0];
  var objects = args.slice(1);
  target = target || {};
  objects.forEach(function(object) {
    for (var j in object) {
      if (object.hasOwnProperty(j)) {
        target[j] = object[j];
      }
    }
  });
  return target;
}


function _buildUrl(url, parameters) {
  var qs = '';
  for (var key in parameters) {
    if (parameters.hasOwnProperty(key)) {
      var value = parameters[key];
      qs += encodeURIComponent(key) + '=' + encodeURIComponent(value) + '&';
    }
  }
  if (qs.length > 0) {
    // chop off last '&'
    qs = qs.substring(0, qs.length - 1);
    url = url + '?' + qs;
  }
  return url;
}

function _performRequest(requestData, callback) {
  var req = new XMLHttpRequest();
    var type = requestData.type || 'GET';
    //console.log(_buildUrl(requestData.url, requestData.params));
    req.open(type, _buildUrl(requestData.url, requestData.params));
    if (_accessToken) {
      req.setRequestHeader('Authorization', 'Bearer ' + _accessToken);
    }
    if (requestData.contentType) {
      req.setRequestHeader('Content-Type', requestData.contentType)
    }

    req.onreadystatechange = function() {
      if (req.readyState === 4) {
        if(_debug) {
            console.log("onreadystatechange status:" + req.status + ", " + req.responseText) 
            _debug = false  
        }
        var data = null;
        try {
          data = req.responseText ? JSON.parse(req.responseText) : '';
        } catch (e) {
          console.error(e);
        }

        if (req.status >= 200 && req.status < 300) {
          callback(null, data, req.status);
        } else {
          callback(data.error);
          if(data.error) {
            console.error("_performRequest: " + data.error.status + ": " + data.error.message);
            // not sure what text they will use but for now it works
            if(data.error.status == 401
               && data.error.message == "The access token expired"
               && tokenLostCallback != null)
              tokenLostCallback()
          }
        }
      }
    }

    if (type === 'GET') {
      req.send(null);
    } else {
      var postData = null
      if (requestData.postData) {
        postData = requestData.contentType === 'image/jpeg' ? requestData.postData : JSON.stringify(requestData.postData)
      }
      req.send(postData);
    }
}

function _checkParamsAndPerformRequest(requestData, options, callback, optionsAlwaysExtendParams) {
  var opt = {};
  var cb = null;

  if (typeof options === 'object') {
    opt = options;
    cb = callback;
  } else if (typeof options === 'function') {
    cb = options;
  }

  // options extend postData, if any. Otherwise they extend parameters sent in the url
  var type = requestData.type || 'GET';
  if (type !== 'GET' && requestData.postData && !optionsAlwaysExtendParams) {
    requestData.postData = _extend(requestData.postData, opt);
  } else {
    requestData.params = _extend(requestData.params, opt);
  }
  return _performRequest(requestData, cb);
}

//
// Spotify API
//

/**
 * Fetches information about the current user.
 * See [Get Current User's Profile](https://developer.spotify.com/web-api/get-current-users-profile/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getMe(options, callback) {
  var requestData = {
    url: _baseUri + '/me'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches current user's saved tracks.
 * See [Get Current User's Saved Tracks](https://developer.spotify.com/web-api/get-users-saved-tracks/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getMySavedTracks(options, callback) {
  var requestData = {
    url: _baseUri + '/me/tracks'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Adds a list of tracks to the current user's saved tracks.
 * See [Save Tracks for Current User](https://developer.spotify.com/web-api/save-tracks-user/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} trackIds The ids of the tracks. If you know their Spotify URI it is easy
 * to find their track id (e.g. spotify:track:<here_is_the_track_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function addToMySavedTracks(trackIds, options, callback) {
  var requestData = {
    url: _baseUri + '/me/tracks',
    type: 'PUT',
    postData: trackIds
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Remove a list of tracks from the current user's saved tracks.
 * See [Remove Tracks for Current User](https://developer.spotify.com/web-api/remove-tracks-user/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} trackIds The ids of the tracks. If you know their Spotify URI it is easy
 * to find their track id (e.g. spotify:track:<here_is_the_track_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function removeFromMySavedTracks(trackIds, options, callback) {
  var requestData = {
    url: _baseUri + '/me/tracks',
    type: 'DELETE',
    //postData: trackIds gives: 400 missing payload
    params: {
         ids: trackIds.join(',')
    }
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Checks if the current user's saved tracks contains a certain list of tracks.
 * See [Check Current User's Saved Tracks](https://developer.spotify.com/web-api/check-users-saved-tracks/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} trackIds The ids of the tracks. If you know their Spotify URI it is easy
 * to find their track id (e.g. spotify:track:<here_is_the_track_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function containsMySavedTracks(trackIds, options, callback) {
  var requestData = {
    url: _baseUri + '/me/tracks/contains',
    params: { ids: trackIds.join(',') }
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Get a list of the albums saved in the current Spotify user's "Your Music" library.
 * See [Get Current User's Saved Albums](https://developer.spotify.com/web-api/get-users-saved-albums/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getMySavedAlbums(options, callback) {
  var requestData = {
    url: _baseUri + '/me/albums'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Save one or more albums to the current user's "Your Music" library.
 * See [Save Albums for Current User](https://developer.spotify.com/web-api/save-albums-user/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} albumIds The ids of the albums. If you know their Spotify URI, it is easy
 * to find their album id (e.g. spotify:album:<here_is_the_album_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function addToMySavedAlbums(albumIds, options, callback) {
  var requestData = {
    url: _baseUri + '/me/albums',
    type: 'PUT',
    postData: albumIds
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Remove one or more albums from the current user's "Your Music" library.
 * See [Remove Albums for Current User](https://developer.spotify.com/web-api/remove-albums-user/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} albumIds The ids of the albums. If you know their Spotify URI, it is easy
 * to find their album id (e.g. spotify:album:<here_is_the_album_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function removeFromMySavedAlbums(albumIds, options, callback) {
  var requestData = {
    url: _baseUri + '/me/albums',
    type: 'DELETE',
    //postData: albumIds gives: 400 missing payload
    params: {
         ids: albumIds.join(',')
    }
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Check if one or more albums is already saved in the current Spotify user's "Your Music" library.
 * See [Check User's Saved Albums](https://developer.spotify.com/web-api/check-users-saved-albums/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} albumIds The ids of the albums. If you know their Spotify URI, it is easy
 * to find their album id (e.g. spotify:album:<here_is_the_album_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function containsMySavedAlbums(albumIds, options, callback) {
  var requestData = {
    url: _baseUri + '/me/albums/contains',
    params: { ids: albumIds.join(',') }
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

function getMySavedShows(options, callback) {
  var requestData = {
    url: _baseUri + '/me/shows'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

function addToMySavedShows(showIds, options, callback) {
  var requestData = {
    url: _baseUri + '/me/shows',
    type: 'PUT',
    params: {
         ids: showIds.join(',')
    }
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

function removeFromMySavedShows(showIds, options, callback) {
  var requestData = {
    url: _baseUri + '/me/shows',
    type: 'DELETE',
    params: {
         ids: showIds.join(',')
    }
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Get the current user’s top artists based on calculated affinity.
 * See [Get a User’s Top Artists](https://developer.spotify.com/web-api/get-users-top-artists-and-tracks/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getMyTopArtists(options, callback) {
  var requestData = {
    url: _baseUri + '/me/top/artists'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Get the current user’s top tracks based on calculated affinity.
 * See [Get a User’s Top Tracks](https://developer.spotify.com/web-api/get-users-top-artists-and-tracks/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getMyTopTracks(options, callback) {
  var requestData = {
    url: _baseUri + '/me/top/tracks'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Get tracks from the current user’s recently played tracks.
 * See [Get Current User’s Recently Played Tracks](https://developer.spotify.com/web-api/web-api-personalization-endpoints/get-recently-played/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getMyRecentlyPlayedTracks(options, callback) {
  var requestData = {
    url: _baseUri + '/me/player/recently-played'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Adds the current user as a follower of one or more other Spotify users.
 * See [Follow Artists or Users](https://developer.spotify.com/web-api/follow-artists-users/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} userIds The ids of the users. If you know their Spotify URI it is easy
 * to find their user id (e.g. spotify:user:<here_is_the_user_id>)
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is an empty value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function followUsers(userIds, callback) {
  var requestData = {
    url: _baseUri + '/me/following/',
    type: 'PUT',
    params: {
      ids: userIds.join(','),
      type: 'user'
    }
  };
  return _checkParamsAndPerformRequest(requestData, callback);
};

/**
 * Adds the current user as a follower of one or more artists.
 * See [Follow Artists or Users](https://developer.spotify.com/web-api/follow-artists-users/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} artistIds The ids of the artists. If you know their Spotify URI it is easy
 * to find their artist id (e.g. spotify:artist:<here_is_the_artist_id>)
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is an empty value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function followArtists(artistIds, callback) {
  var requestData = {
    url: _baseUri + '/me/following/',
    type: 'PUT',
    params: {
      ids: artistIds.join(','),
      type: 'artist'
    },
    postData: {}
  };
  return _checkParamsAndPerformRequest(requestData, callback);
};

/**
 * Add the current user as a follower of one playlist.
 * See [Follow a Playlist](https://developer.spotify.com/web-api/follow-playlist/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} playlistId The id of the playlist. If you know the Spotify URI it is easy
 * to find the playlist id (e.g. spotify:user:xxxx:playlist:<here_is_the_playlist_id>)
 * @param {Object} options A JSON object with options that can be passed. For instance,
 * whether you want the playlist to be followed privately ({public: false})
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is an empty value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
 function followPlaylist(playlistId, options, callback) {
  var requestData = {
      url: _baseUri + '/playlists/' + playlistId + '/followers',
    type: 'PUT',
    postData: {}
  };

  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Removes the current user as a follower of one or more other Spotify users.
 * See [Unfollow Artists or Users](https://developer.spotify.com/web-api/unfollow-artists-users/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} userIds The ids of the users. If you know their Spotify URI it is easy
 * to find their user id (e.g. spotify:user:<here_is_the_user_id>)
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is an empty value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function unfollowUsers(userIds, callback) {
  var requestData = {
    url: _baseUri + '/me/following/',
    type: 'DELETE',
    params: {
      ids: userIds.join(','),
      type: 'user'
    }
  };
  return _checkParamsAndPerformRequest(requestData, callback);
};

/**
 * Removes the current user as a follower of one or more artists.
 * See [Unfollow Artists or Users](https://developer.spotify.com/web-api/unfollow-artists-users/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} artistIds The ids of the artists. If you know their Spotify URI it is easy
 * to find their artist id (e.g. spotify:artist:<here_is_the_artist_id>)
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is an empty value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function unfollowArtists(artistIds, callback) {
  var requestData = {
    url: _baseUri + '/me/following/',
    type: 'DELETE',
    params: {
      ids: artistIds.join(','),
      type: 'artist'
    }
  };
  return _checkParamsAndPerformRequest(requestData, callback);
};

/**
 * Remove the current user as a follower of one playlist.
 * See [Unfollow a Playlist](https://developer.spotify.com/web-api/unfollow-playlist/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} playlistId The id of the playlist. If you know the Spotify URI it is easy
 * to find the playlist id (e.g. spotify:user:xxxx:playlist:<here_is_the_playlist_id>)
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is an empty value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function unfollowPlaylist(playlistId, callback) {
  var requestData = {
      url: _baseUri + '/playlists/' + playlistId + '/followers',
    type: 'DELETE'
  };
  return _checkParamsAndPerformRequest(requestData, callback);
};

/**
 * Checks to see if the current user is following one or more other Spotify users.
 * See [Check if Current User Follows Users or Artists](https://developer.spotify.com/web-api/check-current-user-follows/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} userIds The ids of the users. If you know their Spotify URI it is easy
 * to find their user id (e.g. spotify:user:<here_is_the_user_id>)
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is an array of boolean values that indicate
 * whether the user is following the users sent in the request.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function isFollowingUsers(userIds, callback) {
  var requestData = {
    url: _baseUri + '/me/following/contains',
    type: 'GET',
    params: {
      ids: userIds.join(','),
      type: 'user'
    }
  };
  return _checkParamsAndPerformRequest(requestData, callback);
};

/**
 * Checks to see if the current user is following one or more artists.
 * See [Check if Current User Follows](https://developer.spotify.com/web-api/check-current-user-follows/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} artistIds The ids of the artists. If you know their Spotify URI it is easy
 * to find their artist id (e.g. spotify:artist:<here_is_the_artist_id>)
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is an array of boolean values that indicate
 * whether the user is following the artists sent in the request.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function isFollowingArtists(artistIds, callback) {
  var requestData = {
    url: _baseUri + '/me/following/contains',
    type: 'GET',
    params: {
      ids: artistIds.join(','),
      type: 'artist'
    }
  };
  return _checkParamsAndPerformRequest(requestData, callback);
};

/**
 * Check to see if one or more Spotify users are following a specified playlist.
 * See [Check if Users Follow a Playlist](https://developer.spotify.com/web-api/check-user-following-playlist/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} playlistId The id of the playlist. If you know the Spotify URI it is easy
 * to find the playlist id (e.g. spotify:user:xxxx:playlist:<here_is_the_playlist_id>)
 * @param {Array<string>} userIds The ids of the users. If you know their Spotify URI it is easy
 * to find their user id (e.g. spotify:user:<here_is_the_user_id>)
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is an array of boolean values that indicate
 * whether the users are following the playlist sent in the request.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function areFollowingPlaylist(playlistId, userIds, callback) {
  var requestData = {
      url: _baseUri + '/playlists/' + playlistId + '/followers/contains',
    type: 'GET',
    params: {
      ids: userIds.join(',')
    }
  };
  return _checkParamsAndPerformRequest(requestData, callback);
};

/**
 * Get the current user's followed artists.
 * See [Get User's Followed Artists](https://developer.spotify.com/web-api/get-followed-artists/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} [options] Options, being after and limit.
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is an object with a paged object containing
 * artists.
 * @returns {Promise|undefined} A promise that if successful, resolves to an object containing a paging object which contains
 * artists objects. Not returned if a callback is given.
 */
function getFollowedArtists(options, callback) {
  var requestData = {
    url: _baseUri + '/me/following',
    type: 'GET',
    params: {
      type: 'artist'
    }
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches information about a specific user.
 * See [Get a User's Profile](https://developer.spotify.com/web-api/get-users-profile/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} userId The id of the user. If you know the Spotify URI it is easy
 * to find the id (e.g. spotify:user:<here_is_the_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getUser(userId, options, callback) {
  var requestData = {
    url: _baseUri + '/users/' + encodeURIComponent(userId)
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches a list of the current user's playlists.
 * See [Get a List of a User's Playlists](https://developer.spotify.com/web-api/get-list-users-playlists/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} userId An optional id of the user. If you know the Spotify URI it is easy
 * to find the id (e.g. spotify:user:<here_is_the_id>). If not provided, the id of the user that granted
 * the permissions will be used.
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getUserPlaylists(userId, options, callback) {
  var requestData;
  if (typeof userId === 'string') {
    requestData = {
      url: _baseUri + '/users/' + encodeURIComponent(userId) + '/playlists'
    };
  } else {
    requestData = {
      url: _baseUri + '/me/playlists'
    };
    callback = options;
    options = userId;
  }
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches a specific playlist.
 * See [Get a Playlist](https://developer.spotify.com/web-api/get-playlist/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} playlistId The id of the playlist. If you know the Spotify URI it is easy
 * to find the playlist id (e.g. spotify:user:xxxx:playlist:<here_is_the_playlist_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getPlaylist(playlistId, options, callback) {
  var requestData = {
    url: _baseUri + '/playlists/' + playlistId
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches the tracks from a specific playlist.
 * See [Get a Playlist's Tracks](https://developer.spotify.com/web-api/get-playlists-tracks/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} playlistId The id of the playlist. If you know the Spotify URI it is easy
 * to find the playlist id (e.g. spotify:user:xxxx:playlist:<here_is_the_playlist_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getPlaylistTracks(playlistId, options, callback) {
  var requestData = {
      url: _baseUri + '/playlists/' + playlistId + '/tracks'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Creates a playlist and stores it in the current user's library.
 * See [Create a Playlist](https://developer.spotify.com/web-api/create-playlist/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} userId The id of the user. If you know the Spotify URI it is easy
 * to find the id (e.g. spotify:user:<here_is_the_id>) * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function createPlaylist(userId, options, callback) {
  var requestData = {
    url: _baseUri + '/users/' + encodeURIComponent(userId) + '/playlists',
    type: 'POST',
    postData: options
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
}

/**
 * Change a playlist's name and public/private state
 * See [Change a Playlist's Details](https://developer.spotify.com/web-api/change-playlist-details/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} playlistId The id of the playlist. If you know the Spotify URI it is easy
 * to find the playlist id (e.g. spotify:user:xxxx:playlist:<here_is_the_playlist_id>)
 * @param {Object} data A JSON object with the data to update. E.g. {name: 'A new name', public: true}
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function changePlaylistDetails(playlistId, data, callback) {
  var requestData = {
      url: _baseUri + '/playlists/' + playlistId,
    type: 'PUT',
    postData: data
  };
  return _checkParamsAndPerformRequest(requestData, data, callback);
};

/**
 * Add tracks to a playlist.
 * See [Add Tracks to a Playlist](https://developer.spotify.com/web-api/add-tracks-to-playlist/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} playlistId The id of the playlist. If you know the Spotify URI it is easy
 * to find the playlist id (e.g. spotify:user:xxxx:playlist:<here_is_the_playlist_id>)
 * @param {Array<string>} uris An array of Spotify URIs for the tracks
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function addTracksToPlaylist(playlistId, uris, options, callback) {
  var requestData = {
      url: _baseUri + '/playlists/' + playlistId + '/tracks',
    type: 'POST',
    postData: {
      uris: uris
    }
  };
  return _checkParamsAndPerformRequest(requestData, options, callback, true);
};

/**
 * Replace the tracks of a playlist
 * See [Replace a Playlist's Tracks](https://developer.spotify.com/web-api/replace-playlists-tracks/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} playlistId The id of the playlist. If you know the Spotify URI it is easy
 * to find the playlist id (e.g. spotify:user:xxxx:playlist:<here_is_the_playlist_id>)
 * @param {Array<string>} uris An array of Spotify URIs for the tracks
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function replaceTracksInPlaylist(playlistId, uris, callback) {
  var requestData = {
      url: _baseUri + '/playlists/' + playlistId + '/tracks',
    type: 'PUT',
    postData: { uris: uris }
  };
  return _checkParamsAndPerformRequest(requestData, {}, callback);
};

/**
 * Reorder tracks in a playlist
 * See [Reorder a Playlist’s Tracks](https://developer.spotify.com/web-api/reorder-playlists-tracks/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} playlistId The id of the playlist. If you know the Spotify URI it is easy
 * to find the playlist id (e.g. spotify:user:xxxx:playlist:<here_is_the_playlist_id>)
 * @param {number} rangeStart The position of the first track to be reordered.
 * @param {number} insertBefore The position where the tracks should be inserted. To reorder the tracks to
 * the end of the playlist, simply set insert_before to the position after the last track.
 * @param {Object} options An object with optional parameters (range_length, snapshot_id)
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function reorderTracksInPlaylist(playlistId, rangeStart, insertBefore, options, callback) {
  /* eslint-disable camelcase */
  var requestData = {
      url: _baseUri + '/playlists/' + playlistId + '/tracks',
    type: 'PUT',
    postData: {
      range_start: rangeStart,
      insert_before: insertBefore
    }
  };
  /* eslint-enable camelcase */
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Remove tracks from a playlist
 * See [Remove Tracks from a Playlist](https://developer.spotify.com/web-api/remove-tracks-playlist/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} playlistId The id of the playlist. If you know the Spotify URI it is easy
 * to find the playlist id (e.g. spotify:user:xxxx:playlist:<here_is_the_playlist_id>)
 * @param {Array<Object>} uris An array of tracks to be removed. Each element of the array can be either a
 * string, in which case it is treated as a URI, or an object containing the properties `uri` (which is a
 * string) and `positions` (which is an array of integers).
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function removeTracksFromPlaylist(playlistId, uris, positions, callback) {

  var urisToBeSent = uris.map(function(uri) {
    if (typeof uri === 'string') {
      return { uri: uri };
    } else {
      return uri;
    }
  });

  var positionsToBeSent = uris.map(function(positions) {
    if (typeof uri === 'string') {
      return { positions: positions };
    } else {
      return positions;
    }
  });

  var requestData = {
    url: _baseUri + '/playlists/' + playlistId + '/tracks',
    type: 'DELETE',
    postData: { tracks: urisToBeSent, positions: positionsToBeSent }
  };
  return _checkParamsAndPerformRequest(requestData, {}, callback);
};

/**
 * Remove tracks from a playlist, specifying a snapshot id.
 * See [Remove Tracks from a Playlist](https://developer.spotify.com/web-api/remove-tracks-playlist/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} playlistId The id of the playlist. If you know the Spotify URI it is easy
 * to find the playlist id (e.g. spotify:user:xxxx:playlist:<here_is_the_playlist_id>)
 * @param {Array<Object>} uris An array of tracks to be removed. Each element of the array can be either a
 * string, in which case it is treated as a URI, or an object containing the properties `uri` (which is a
 * string) and `positions` (which is an array of integers).
 * @param {string} snapshotId The playlist's snapshot ID against which you want to make the changes
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function removeTracksFromPlaylistWithSnapshotId(playlistId, uris, snapshotId, callback) {
  var dataToBeSent = uris.map(function(uri) {
    if (typeof uri === 'string') {
      return { uri: uri };
    } else {
      return uri;
    }
  });
  /* eslint-disable camelcase */
  var requestData = {
      url: _baseUri + '/playlists/' + playlistId + '/tracks',
    type: 'DELETE',
    postData: {
      tracks: dataToBeSent,
      snapshot_id: snapshotId
    }
  };
  /* eslint-enable camelcase */
  return _checkParamsAndPerformRequest(requestData, {}, callback);
};

/**
 * Remove tracks from a playlist, specifying the positions of the tracks to be removed.
 * See [Remove Tracks from a Playlist](https://developer.spotify.com/web-api/remove-tracks-playlist/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} playlistId The id of the playlist. If you know the Spotify URI it is easy
 * to find the playlist id (e.g. spotify:user:xxxx:playlist:<here_is_the_playlist_id>)
 * @param {Array<number>} positions array of integers containing the positions of the tracks to remove
 * from the playlist.
 * @param {string} snapshotId The playlist's snapshot ID against which you want to make the changes
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function removeTracksFromPlaylistInPositions(playlistId, positions, snapshotId, callback) {
  /* eslint-disable camelcase */
  var requestData = {
      url: _baseUri + '/playlists/' + playlistId + '/tracks',
    type: 'DELETE',
    postData: {
      positions: positions,
      snapshot_id: snapshotId
    }
  };
  /* eslint-enable camelcase */
  return _checkParamsAndPerformRequest(requestData, {}, callback);
};

/**
 * Upload a custom playlist cover image.
 * See [Upload A Custom Playlist Cover Image](https://developer.spotify.com/web-api/upload-a-custom-playlist-cover-image/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} playlistId The id of the playlist. If you know the Spotify URI it is easy
 * to find the playlist id (e.g. spotify:user:xxxx:playlist:<here_is_the_playlist_id>)
 * @param {string} imageData Base64 encoded JPEG image data, maximum payload size is 256 KB.
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function uploadCustomPlaylistCoverImage(playlistId, imageData, callback) {
  var requestData = {
      url: _baseUri + '/playlists/' + playlistId + '/images',
    type: 'PUT',
    postData: imageData.replace(/^data:image\/jpeg;base64,/, ''),
    contentType: 'image/jpeg'
  };
  return _checkParamsAndPerformRequest(requestData, {}, callback);
};

function getPlaylistCoverImage(playlistId, callback) {
  var requestData = {
      url: _baseUri + '/playlists/' + playlistId + '/images'
  };
  return _checkParamsAndPerformRequest(requestData, {}, callback);
};

/**
 * Fetches an album from the Spotify catalog.
 * See [Get an Album](https://developer.spotify.com/web-api/get-album/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} albumId The id of the album. If you know the Spotify URI it is easy
 * to find the album id (e.g. spotify:album:<here_is_the_album_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getAlbum(albumId, options, callback) {
  var requestData = {
    url: _baseUri + '/albums/' + albumId
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches the tracks of an album from the Spotify catalog.
 * See [Get an Album's Tracks](https://developer.spotify.com/web-api/get-albums-tracks/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} albumId The id of the album. If you know the Spotify URI it is easy
 * to find the album id (e.g. spotify:album:<here_is_the_album_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getAlbumTracks(albumId, options, callback) {
  var requestData = {
    url: _baseUri + '/albums/' + albumId + '/tracks'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches multiple albums from the Spotify catalog.
 * See [Get Several Albums](https://developer.spotify.com/web-api/get-several-albums/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} albumIds The ids of the albums. If you know their Spotify URI it is easy
 * to find their album id (e.g. spotify:album:<here_is_the_album_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getAlbums(albumIds, options, callback) {
  var requestData = {
    url: _baseUri + '/albums/',
    params: { ids: albumIds.join(',') }
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches a track from the Spotify catalog.
 * See [Get a Track](https://developer.spotify.com/web-api/get-track/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} trackId The id of the track. If you know the Spotify URI it is easy
 * to find the track id (e.g. spotify:track:<here_is_the_track_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getTrack(trackId, options, callback) {
  var requestData = {};
  requestData.url = _baseUri + '/tracks/' + trackId;
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches multiple tracks from the Spotify catalog.
 * See [Get Several Tracks](https://developer.spotify.com/web-api/get-several-tracks/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} trackIds The ids of the tracks. If you know their Spotify URI it is easy
 * to find their track id (e.g. spotify:track:<here_is_the_track_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getTracks(trackIds, options, callback) {
  var requestData = {
    url: _baseUri + '/tracks/',
    params: { ids: trackIds.join(',') }
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches an artist from the Spotify catalog.
 * See [Get an Artist](https://developer.spotify.com/web-api/get-artist/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} artistId The id of the artist. If you know the Spotify URI it is easy
 * to find the artist id (e.g. spotify:artist:<here_is_the_artist_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getArtist(artistId, options, callback) {
  var requestData = {
    url: _baseUri + '/artists/' + artistId
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches multiple artists from the Spotify catalog.
 * See [Get Several Artists](https://developer.spotify.com/web-api/get-several-artists/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} artistIds The ids of the artists. If you know their Spotify URI it is easy
 * to find their artist id (e.g. spotify:artist:<here_is_the_artist_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getArtists(artistIds, options, callback) {
  var requestData = {
    url: _baseUri + '/artists/',
    params: { ids: artistIds.join(',') }
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches the albums of an artist from the Spotify catalog.
 * See [Get an Artist's Albums](https://developer.spotify.com/web-api/get-artists-albums/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} artistId The id of the artist. If you know the Spotify URI it is easy
 * to find the artist id (e.g. spotify:artist:<here_is_the_artist_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getArtistAlbums(artistId, options, callback) {
  var requestData = {
    url: _baseUri + '/artists/' + artistId + '/albums'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches a list of top tracks of an artist from the Spotify catalog, for a specific country.
 * See [Get an Artist's Top Tracks](https://developer.spotify.com/web-api/get-artists-top-tracks/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} artistId The id of the artist. If you know the Spotify URI it is easy
 * to find the artist id (e.g. spotify:artist:<here_is_the_artist_id>)
 * @param {string} countryId The id of the country (e.g. ES for Spain or US for United States)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getArtistTopTracks(artistId, countryId, options, callback) {
  var requestData = {
    url: _baseUri + '/artists/' + artistId + '/top-tracks',
    params: { country: countryId }
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches a list of artists related with a given one from the Spotify catalog.
 * See [Get an Artist's Related Artists](https://developer.spotify.com/web-api/get-related-artists/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} artistId The id of the artist. If you know the Spotify URI it is easy
 * to find the artist id (e.g. spotify:artist:<here_is_the_artist_id>)
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getArtistRelatedArtists(artistId, options, callback) {
  var requestData = {
    url: _baseUri + '/artists/' + artistId + '/related-artists'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches a list of Spotify featured playlists (shown, for example, on a Spotify player's "Browse" tab).
 * See [Get a List of Featured Playlists](https://developer.spotify.com/web-api/get-list-featured-playlists/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getFeaturedPlaylists(options, callback) {
  var requestData = {
    url: _baseUri + '/browse/featured-playlists'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches a list of new album releases featured in Spotify (shown, for example, on a Spotify player's "Browse" tab).
 * See [Get a List of New Releases](https://developer.spotify.com/web-api/get-list-new-releases/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getNewReleases(options, callback) {
  var requestData = {
    url: _baseUri + '/browse/new-releases'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Get a list of categories used to tag items in Spotify (on, for example, the Spotify player's "Browse" tab).
 * See [Get a List of Categories](https://developer.spotify.com/web-api/get-list-categories/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getCategories(options, callback) {
  var requestData = {
    url: _baseUri + '/browse/categories'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Get a single category used to tag items in Spotify (on, for example, the Spotify player's "Browse" tab).
 * See [Get a Category](https://developer.spotify.com/web-api/get-category/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} categoryId The id of the category. These can be found with the getCategories function
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getCategory(categoryId, options, callback) {
  var requestData = {
    url: _baseUri + '/browse/categories/' + categoryId
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Get a list of Spotify playlists tagged with a particular category.
 * See [Get a Category's Playlists](https://developer.spotify.com/web-api/get-categorys-playlists/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} categoryId The id of the category. These can be found with the getCategories function
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getCategoryPlaylists(categoryId, options, callback) {
  var requestData = {
    url: _baseUri + '/browse/categories/' + categoryId + '/playlists'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Get Spotify catalog information about artists, albums, tracks or playlists that match a keyword string.
 * See [Search for an Item](https://developer.spotify.com/web-api/search-item/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} query The search query
 * @param {Array<string>} types An array of item types to search across.
 * Valid types are: 'album', 'artist', 'playlist', and 'track'.
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function search(query, types, options, callback) {
  var requestData = {
    url: _baseUri + '/search/',
    params: {
      q: query,
      type: types.join(',')
    }
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Fetches albums from the Spotify catalog according to a query.
 * See [Search for an Item](https://developer.spotify.com/web-api/search-item/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} query The search query
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function searchAlbums(query, options, callback) {
  return this.search(query, ['album'], options, callback);
};

/**
 * Fetches artists from the Spotify catalog according to a query.
 * See [Search for an Item](https://developer.spotify.com/web-api/search-item/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} query The search query
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function searchArtists(query, options, callback) {
  return this.search(query, ['artist'], options, callback);
};

/**
 * Fetches tracks from the Spotify catalog according to a query.
 * See [Search for an Item](https://developer.spotify.com/web-api/search-item/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} query The search query
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function searchTracks(query, options, callback) {
  return this.search(query, ['track'], options, callback);
};

/**
 * Fetches playlists from the Spotify catalog according to a query.
 * See [Search for an Item](https://developer.spotify.com/web-api/search-item/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} query The search query
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function searchPlaylists(query, options, callback) {
  return this.search(query, ['playlist'], options, callback);
};

/**
 * Get audio features for a single track identified by its unique Spotify ID.
 * See [Get Audio Features for a Track](https://developer.spotify.com/web-api/get-audio-features/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} trackId The id of the track. If you know the Spotify URI it is easy
 * to find the track id (e.g. spotify:track:<here_is_the_track_id>)
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getAudioFeaturesForTrack(trackId, callback) {
  var requestData = {};
  requestData.url = _baseUri + '/audio-features/' + trackId;
  return _checkParamsAndPerformRequest(requestData, {}, callback);
};

/**
 * Get audio features for multiple tracks based on their Spotify IDs.
 * See [Get Audio Features for Several Tracks](https://developer.spotify.com/web-api/get-several-audio-features/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} trackIds The ids of the tracks. If you know their Spotify URI it is easy
 * to find their track id (e.g. spotify:track:<here_is_the_track_id>)
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getAudioFeaturesForTracks(trackIds, callback) {
  var requestData = {
    url: _baseUri + '/audio-features',
    params: { ids: trackIds }
  };
  return _checkParamsAndPerformRequest(requestData, {}, callback);
};

/**
 * Get audio analysis for a single track identified by its unique Spotify ID.
 * See [Get Audio Analysis for a Track](https://developer.spotify.com/web-api/get-audio-analysis/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {string} trackId The id of the track. If you know the Spotify URI it is easy
 * to find the track id (e.g. spotify:track:<here_is_the_track_id>)
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getAudioAnalysisForTrack(trackId, callback) {
  var requestData = {};
  requestData.url = _baseUri + '/audio-analysis/' + trackId;
  return _checkParamsAndPerformRequest(requestData, {}, callback);
};

/**
 * Create a playlist-style listening experience based on seed artists, tracks and genres.
 * See [Get Recommendations Based on Seeds](https://developer.spotify.com/web-api/get-recommendations/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} options A JSON object with options that can be passed
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getRecommendations(options, callback) {
  var requestData = {
    url: _baseUri + '/recommendations'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Retrieve a list of available genres seed parameter values for recommendations.
 * See [Available Genre Seeds](https://developer.spotify.com/web-api/get-recommendations/#available-genre-seeds) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getAvailableGenreSeeds(callback) {
  var requestData = {
    url: _baseUri + '/recommendations/available-genre-seeds'
  };
  return _checkParamsAndPerformRequest(requestData, {}, callback);
};

/**
 * Get information about a user’s available devices.
 * See [Get a User’s Available Devices](https://developer.spotify.com/web-api/get-a-users-available-devices/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getMyDevices(callback) {
  var requestData = {
    url: _baseUri + '/me/player/devices'
  };
  return _checkParamsAndPerformRequest(requestData, {}, callback);
};

/**
 * Get information about the user’s current playback state, including track, track progress, and active device.
 * See [Get Information About The User’s Current Playback](https://developer.spotify.com/web-api/get-information-about-the-users-current-playback/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} options A JSON object with options that can be passed.
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getMyCurrentPlaybackState(options, callback) {
  var requestData = {
    url: _baseUri + '/me/player'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Get the object currently being played on the user’s Spotify account.
 * See [Get the User’s Currently Playing Track](https://developer.spotify.com/web-api/get-the-users-currently-playing-track/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} options A JSON object with options that can be passed.
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function getMyCurrentPlayingTrack(options, callback) {
  var requestData = {
    url: _baseUri + '/me/player/currently-playing'
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

function getShow(showId, options, callback) {
  var requestData = {
    url: _baseUri + '/shows/' + showId
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

function getShows(showIds, options, callback) {
  var requestData = {
    url: _baseUri + '/shows/',
    params: { ids: showIds.join(',') }
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

function getEpisode(episodeId, options, callback) {
  var requestData = {
    url: _baseUri + '/episodes/' + episodeId
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Transfer playback to a new device and determine if it should start playing.
 * See [Transfer a User’s Playback](https://developer.spotify.com/web-api/transfer-a-users-playback/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Array<string>} deviceIds A JSON array containing the ID of the device on which playback should be started/transferred.
 * @param {Object} options A JSON object with options that can be passed.
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function transferMyPlayback(deviceIds, options, callback) {
  var postData = options || {};
  postData.device_ids = deviceIds;
  var requestData = {
    type: 'PUT',
    url: _baseUri + '/me/player',
    postData: postData
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Start a new context or resume current playback on the user’s active device.
 * See [Start/Resume a User’s Playback](https://developer.spotify.com/web-api/start-a-users-playback/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} options A JSON object with options that can be passed.
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function play(options, callback) {
  var params = 'device_id' in options ? {device_id: options.device_id} : null;
  var postData = {};
  ['context_uri', 'uris', 'offset', 'position_ms'].forEach(function(field) {
    if (field in options) {
      postData[field] = options[field];
    }
  });
  var requestData = {
    type: 'PUT',
    url: _baseUri + '/me/player/play',
    params: params,
    postData: postData
  };

  // need to clear options so it doesn't add all of them to the query params
  var newOptions = typeof options === 'function' ? options : {};
  return _checkParamsAndPerformRequest(requestData, newOptions, callback);
};

/**
 * Pause playback on the user’s account.
 * See [Pause a User’s Playback](https://developer.spotify.com/web-api/pause-a-users-playback/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} options A JSON object with options that can be passed.
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function pause(options, callback) {
  var params = 'device_id' in options ? {device_id: options.device_id} : null;
  var requestData = {
    type: 'PUT',
    url: _baseUri + '/me/player/pause',
    params: params
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Skips to next track in the user’s queue.
 * See [Skip User’s Playback To Next Track](https://developer.spotify.com/web-api/skip-users-playback-to-next-track/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} options A JSON object with options that can be passed.
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function skipToNext(options, callback) {
  var params = 'device_id' in options ? {device_id: options.device_id} : null;
  var requestData = {
    type: 'POST',
    url: _baseUri + '/me/player/next',
    params: params
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Skips to previous track in the user’s queue.
 * Note that this will ALWAYS skip to the previous track, regardless of the current track’s progress.
 * Returning to the start of the current track should be performed using `.seek()`
 * See [Skip User’s Playback To Previous Track](https://developer.spotify.com/web-api/skip-users-playback-to-next-track/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {Object} options A JSON object with options that can be passed.
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function skipToPrevious(options, callback) {
  var params = 'device_id' in options ? {device_id: options.device_id} : null;
  var requestData = {
    type: 'POST',
    url: _baseUri + '/me/player/previous',
    params: params
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Seeks to the given position in the user’s currently playing track.
 * See [Seek To Position In Currently Playing Track](https://developer.spotify.com/web-api/seek-to-position-in-currently-playing-track/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {number} position_ms The position in milliseconds to seek to. Must be a positive number.
 * @param {Object} options A JSON object with options that can be passed.
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function seek(position_ms, options, callback) {
  var params = {
    position_ms: position_ms
  };
  if ('device_id' in options) {
    params.device_id = options.device_id;
  }
  var requestData = {
    type: 'PUT',
    url: _baseUri + '/me/player/seek',
    params: params
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Set the repeat mode for the user’s playback. Options are repeat-track, repeat-context, and off.
 * See [Set Repeat Mode On User’s Playback](https://developer.spotify.com/web-api/set-repeat-mode-on-users-playback/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {String} state A string set to 'track', 'context' or 'off'.
 * @param {Object} options A JSON object with options that can be passed.
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function setRepeat(state, options, callback) {
  var params = {
    state: state
  };
  if ('device_id' in options) {
    params.device_id = options.device_id;
  }
  var requestData = {
    type: 'PUT',
    url: _baseUri + '/me/player/repeat',
    params: params
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Set the volume for the user’s current playback device.
 * See [Set Volume For User’s Playback](https://developer.spotify.com/web-api/set-volume-for-users-playback/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {number} volume_percent The volume to set. Must be a value from 0 to 100 inclusive.
 * @param {Object} options A JSON object with options that can be passed.
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function setVolume(volume_percent, options, callback) {
  var params = {
    volume_percent: volume_percent
  };
  if ('device_id' in options) {
    params.device_id = options.device_id;
  }
  var requestData = {
    type: 'PUT',
    url: _baseUri + '/me/player/volume',
    params: params
  };
  //console.log("Spotify.setVolume: " + JSON.stringify(requestData.params))
  //_debug = true
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Toggle shuffle on or off for user’s playback.
 * See [Toggle Shuffle For User’s Playback](https://developer.spotify.com/web-api/toggle-shuffle-for-users-playback/) on
 * the Spotify Developer site for more information about the endpoint.
 *
 * @param {bool} state Whether or not to shuffle user's playback.
 * @param {Object} options A JSON object with options that can be passed.
 * @param {function(Object,Object)} callback An optional callback that receives 2 parameters. The first
 * one is the error object (null if no error), and the second is the value if the request succeeded.
 * @return {Object} Null if a callback is provided, a `Promise` object otherwise
 */
function setShuffle(state, options, callback) {
  var params = {
    state: state
  };
  if ('device_id' in options) {
    params.device_id = options.device_id;
  }
  var requestData = {
    type: 'PUT',
    url: _baseUri + '/me/player/shuffle',
    params: params
  };
  return _checkParamsAndPerformRequest(requestData, options, callback);
};

/**
 * Get the object Spotify gave a url for
 */
function getObject(url, callback) {
  var requestData = {
    url: url
  };
  return _checkParamsAndPerformRequest(requestData, {}, callback);
}

/**
 * Gets the access token in use.
 *
 * @return {string} accessToken The access token
 */
function getAccessToken() {
  return _accessToken;
};

/**
 * Sets the access token to be used.
 * See [the Authorization Guide](https://developer.spotify.com/web-api/authorization-guide/) on
 * the Spotify Developer site for more information about obtaining an access token.
 *
 * @param {string} accessToken The access token
 * @return {void}
 */
function setAccessToken(accessToken) {
  _accessToken = accessToken;
};

// ToDo: remove?
var ItemType = {
    Album: 0,
    Artist: 1,
    Playlist: 2,
    Track: 3,
    Episode: 4,
    Show: 5
}
