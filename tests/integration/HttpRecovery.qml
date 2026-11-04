import QtQuick
import Quickshell
import "../.." as Plugin
ShellRoot {
  id: root
  property int calls: 0
  property double clock: 1000
  Plugin.HttpTransport {
    id: idleTransport
    pluginDir: "/nonexistent"
    now: function(){return root.clock}
    nativeFactory: function(){return {native:true}}
  }
  property var slow: null
  Plugin.HttpTransport {
    id: transport
    pluginDir: Quickshell.env("TEST_HTTP_DIR")
    nativeFactory: function() { throw new Error("Native transport should not run after recovery") }
  }
  Component.onCompleted: {
    if(!idleTransport.createRequest().native) throw new Error("Native default changed")
    root.clock=62000
    if(idleTransport.createRequest().native || !idleTransport.fallbackActive) throw new Error("Idle/wake recovery failed")
    transport.recover()
    var xhr=transport.createRequest()
    xhr.open("POST","https://accounts.spotify.com/api/token")
    xhr.setRequestHeader("Authorization","Bearer fixture-private")
    xhr.onreadystatechange=function() {
      root.calls++
      if(xhr.status!==429 || xhr.getResponseHeader("Retry-After")!=="120") throw new Error("HTTP status/header lost")
      var body=JSON.parse(xhr.responseText)
      if(body.method!=="POST" || body.body!=="refresh_token=fixture-private" || body.argc!==1) throw new Error("stdin/argument contract failed")
      if(transport.requestsRunning!==0) throw new Error("Completed worker leaked")
      root.slow=transport.createRequest()
      root.slow.open("GET","https://api.spotify.com/v1/slow")
      root.slow.onreadystatechange=function(){throw new Error("Cancelled request delivered callback")}
      root.slow.send()
      abortTimer.start()
    }
    xhr.send("refresh_token=fixture-private")
    if(xhr.process.command.length!==2) throw new Error("Credentials exposed in command arguments")
  }
  Timer {
    id: abortTimer
    interval: 200
    onTriggered: {
      root.slow.abort();root.slow.abort()
      if(root.calls!==1 || transport.requestsRunning!==0) throw new Error("Abort leaked or double-completed")
      console.log("HTTP_RECOVERY_PASS")
      Qt.quit()
    }
  }
  Timer {interval:5000;running:true;onTriggered:{console.error("HTTP_RECOVERY_TIMEOUT");Qt.quit()}}
}
