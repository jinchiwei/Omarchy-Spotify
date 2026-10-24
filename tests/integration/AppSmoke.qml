import QtQuick
import Quickshell
import "plugin" as Plugin

ShellRoot {
  QtObject { id: scopedShell; property var barConfig: ({ layout: { left: [
    { id: "quickshell.spotify", playbackEngine: "Spotify Connect" }
  ] } }) }
  property var pageRequests: []
  QtObject { id: pageAuth
    function withAccessToken(callback) { callback("mock-token", "") }
    function invalidateAccessToken() {}
  }
  function pageXhr() {
    var xhr = {readyState:0, status:0, responseText:"", onreadystatechange:null,
      open:function(method, url) { this.url = url }, setRequestHeader:function() {}, send:function() {},
      abort:function() {}, getResponseHeader:function() { return "1" }}
    pageRequests = pageRequests.concat([xhr])
    return xhr
  }
  function completePage(status, payload) {
    var xhr = pageRequests[pageRequests.length - 1]
    xhr.status = status; xhr.responseText = JSON.stringify(payload)
    xhr.readyState = XMLHttpRequest.DONE; xhr.onreadystatechange()
  }
  Plugin.Service { id: spotifyService }
  Plugin.Panel { id: panel; service: spotifyService; width: 1280; height: 800 }
  Plugin.BarWidget { id: widget }
  Timer {
    interval: 20
    running: true
    onTriggered: {
      spotifyService.auth.customClientId = "invalid"
      spotifyService.search("smoke-test", "track")
      if (spotifyService.searchLoading || !spotifyService.searchError)
        throw new Error("Search service did not return the authorization error")
      if (!panel.primaryNavigationItems().some(function(item) { return item.id === "search" }))
        throw new Error("Search navigation is missing")
      spotifyService.clearSearch()
      if (spotifyService.searchQuery !== "") throw new Error("Search state did not clear")
      spotifyService.shell = scopedShell
      spotifyService.syncSettings()
      if (spotifyService.settings.playbackEngine !== "Spotify Connect")
        throw new Error("Capability-scoped shell settings were ignored")
      spotifyService.applySettings({ playbackEngine: "Spotify Connect" })
      if (spotifyService.settings.playbackEngine !== "Spotify Connect")
        throw new Error("External playback preference was discarded")
      spotifyService.auth.customClientId = ""
      spotifyService.auth.loggedIn = true
      spotifyService.auth.sessionChecked = true
      spotifyService.daemon.binaryAvailable = false
      spotifyService.daemon.unitAvailable = false
      spotifyService.daemon.credentialsAvailable = false
      if (!spotifyService.fullyConnected)
        throw new Error("External playback still requires the unused local engine")
      spotifyService.selectedDeviceId = ""
      spotifyService.devices = []
      spotifyService.pendingPlaybackBody = { uris: ["spotify:track:test"] }
      spotifyService.pendingPlaybackSerial = 7
      spotifyService.dispatchPendingPlayback(7)
      if (spotifyService.lastError.indexOf("Spotify Connect") < 0)
        throw new Error("Missing external device did not give an actionable error")
      spotifyService.api.cancelAll()
      spotifyService.api.auth = pageAuth
      spotifyService.api.xhrFactory = pageXhr
      spotifyService.selectedPlaylist = {id:"test", name:"Test"}
      spotifyService.playlistItems = []
      spotifyService.playlistItemsNext = "/playlists/test/items?offset=0"
      spotifyService.loadMorePlaylistItems()
      if (pageRequests.length !== 1) throw new Error("First playlist request missing")
      var row = {track:{id:"a",uri:"spotify:track:a",name:"A",duration_ms:1000,artists:[]}}
      completePage(200,{items:[row],offset:0,next:"https://api.spotify.com/v1/playlists/test/items?offset=1"})
      if (pageRequests.length !== 2) throw new Error("One click did not fetch the next playlist page")
      completePage(200,{items:[row],offset:1,next:null})
      if (spotifyService.playlistItems.length !== 2 || spotifyService.playlistLoadAll)
        throw new Error("Playlist batch lost duplicate entries or did not finish")
      spotifyService.playlistItemsNext = "/playlists/test/items?offset=2"
      spotifyService.loadMorePlaylistItems()
      var beforeLimit = pageRequests.length
      completePage(429,{error:{message:"Rate limited"}})
      if (spotifyService.playlistLoadAll || pageRequests.length !== beforeLimit)
        throw new Error("Playlist batch did not stop at rate limiting")
      spotifyService.api.rateLimitedUntil = 0
      spotifyService.activeView = "playlists"
      spotifyService.playlistItemsNext = "/playlists/test/items?offset=2"
      spotifyService.loadMorePlaylistItems()
      spotifyService.activeView = "search"
      var beforeLeave = pageRequests.length
      completePage(200,{items:[row],offset:2,next:"https://api.spotify.com/v1/playlists/test/items?offset=3"})
      if (spotifyService.playlistLoadAll || pageRequests.length !== beforeLeave)
        throw new Error("Playlist batch kept loading after leaving the view")
      spotifyService.api.cancelAll()
      pageRequests = []
      spotifyService.api.request("GET", "/me", null, null, function() {})
      spotifyService.api.request("GET", "/me/player/devices", null, null, function() {})
      spotifyService.api.request("GET", "/me/albums", null, null, function() {})
      spotifyService.loadSavedTracks(false)
      completePage(200, {})
      if (pageRequests.length !== 3 || pageRequests[2].url.indexOf("/me/tracks") < 0)
        throw new Error("Liked Songs waited behind background library requests")
      spotifyService.api.cancelAll()
      pageRequests = []
      spotifyService.currentUserId = ""
      spotifyService.loadProfile()
      spotifyService.loadProfile()
      if (pageRequests.length !== 1)
        throw new Error("Opening another surface duplicated the pending profile request")
      spotifyService.api.cancelAll()
      pageRequests = []
      spotifyService.api.rateLimitedUntil = 0
      spotifyService.applyPlaybackState({device:{id:"receiver", name:"Remote", is_active:true},
        item:{id:"current",uri:"spotify:track:current",type:"track",name:"Current",duration_ms:1000,artists:[]},
        progress_ms:0,is_playing:false})
      spotifyService.setUiVisible("request-order-test", true)
      if (pageRequests.some(function(xhr) { return xhr.url.indexOf("/library/contains") >= 0 }))
        throw new Error("Opening a surface started optional liked-status work before its page")
      spotifyService.flushCurrentTrackSaved()
      if (pageRequests.some(function(xhr) { return xhr.url.indexOf("/library/contains") >= 0 }))
        throw new Error("Optional liked-status work ignored pending foreground work")
      spotifyService.api.cancelAll()
      pageRequests = []
      spotifyService.savedTracksLoading = false
      spotifyService.playlistsLoading = false
      spotifyService.flushCurrentTrackSaved()
      if (pageRequests.length !== 1 || pageRequests[0].url.indexOf("/library/contains") < 0)
        throw new Error("Deferred liked-status lookup never resumed")
      completePage(200, [true])
      if (!spotifyService.currentTrackSaved)
        throw new Error("Deferred liked-status lookup did not update the heart")
      spotifyService.setUiVisible("request-order-test", false)
      spotifyService.api.cancelAll()
      console.log("APP_SMOKE_PASS")
      Qt.quit()
    }
  }
}
