import QtQuick
import Quickshell.Io

// A stuck engine-wide QNetworkAccessManager cannot be reset by replacing an XHR.
// Switch this plugin (not the desktop) to fresh, bounded HTTP/1.1 helper processes.
Item {
  id: root
  required property string pluginDir
  property bool fallbackActive: false
  property int requestsRunning: 0
  property var nativeFactory: function() { return new XMLHttpRequest() }

  function recover() { fallbackActive = true; return true }
  function createRequest() {
    if (!fallbackActive) return nativeFactory()
    var xhr = {
      readyState: 0, status: 0, responseText: "", onreadystatechange: null,
      method: "GET", url: "", headers: ({}), responseHeaders: ({}), body: null,
      process: null, settled: false,
      open: function(method, url) { this.method=method; this.url=url; this.readyState=1 },
      setRequestHeader: function(name, value) { this.headers[name]=value },
      getResponseHeader: function(name) { return this.responseHeaders[String(name).toLowerCase()] || "" },
      send: function(body) {
        this.body = body === undefined ? null : body
        var xhr=this
        var p=worker.createObject(root)
        if (!p) throw new Error("Could not start Spotify transport")
        p.payload=JSON.stringify({method:this.method,url:this.url,headers:this.headers,body:this.body})
        this.headers=({});this.body=null
        // A QML object property can copy a JS record. Keep completion in a closure
        // over the actual XHR facade so callers observe the changed state.
        p.deliver=function(result) {
          if (xhr.settled) return
          xhr.settled=true; xhr.process=null
          root.requestsRunning=Math.max(0,root.requestsRunning-1)
          xhr.status=Number(result.status)||0; xhr.responseText=String(result.body||"")
          xhr.responseHeaders=result.headers||({});xhr.readyState=4
          if(typeof xhr.onreadystatechange==="function") xhr.onreadystatechange()
        }
        this.process=p
        root.requestsRunning++
        p.running=true
      },
      abort: function() {
        if (this.settled) return
        this.settled=true
        if (this.process) {
          var p=this.process; this.process=null
          root.requestsRunning=Math.max(0,root.requestsRunning-1)
          p.running=false; p.destroy()
        }
        this.headers=({});this.body=null
      }
    }
    return xhr
  }
  Component {
    id: worker
    Process {
      id: process
      property string payload: ""
      property var deliver
      command: ["python3", root.pluginDir + "/scripts/spotify-http.py"]
      stdinEnabled: true
      onStarted: {
        process.write(payload + "\n")
        payload=""
      }
      stdout: StdioCollector { id: output; waitForEnd: true }
      // Never log child output: token responses and user data travel through stdout.
      onExited: function(code) {
        var result=({})
        try { if(code===0) result=JSON.parse(output.text) } catch(error) {}
        if(typeof deliver==="function") deliver(result)
        process.destroy()
      }
    }
  }
}
