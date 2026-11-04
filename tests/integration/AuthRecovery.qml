import QtQuick
import Quickshell
import "../.." as Plugin
ShellRoot {
  id: testCase
  function compare(a,b){if(a!==b)throw new Error("Mismatch: "+a+" vs "+b)}
  function verify(value){if(!value)throw new Error("Assertion failed")}
  function createTemporaryObject(c,p){return c.createObject(p)}
  Timer { interval: 20; running: true; onTriggered: {
    try {
      init();test_refreshTransportFailureRetriesOnce()
      init();test_timeoutRecoveryAndCancellationIgnoreLateReplies()
      init();test_authorizationCodeIsNeverReplayed()
      console.log("AUTH_RECOVERY_PASS")
    } catch(error) {console.error("AUTH_RECOVERY_FAIL",String(error))}
    Qt.quit()
  }}
  property var requests: []
  property int recoveries: 0
  Component {
    id: component
    Plugin.AuthManager {
      pluginDir: "/nonexistent"
      customClientId: "11111111111111111111111111111111"
      function restoreSession() {}
      onTransportFailed: testCase.recoveries++
      xhrFactory: function() {
        var xhr={readyState:0,status:0,responseText:"",onreadystatechange:null,aborted:false,
          open:function(){},setRequestHeader:function(){},send:function(){},abort:function(){this.aborted=true}}
        testCase.requests.push(xhr);return xhr
      }
    }
  }
  function init(){requests=[];recoveries=0}
  function complete(xhr,status,body){xhr.status=status;xhr.responseText=body||"{}";xhr.readyState=4;xhr.onreadystatechange()}
  function test_refreshTransportFailureRetriesOnce(){
    var auth=createTemporaryObject(component,testCase);var calls=0
    auth.postTokenRequest("grant_type=refresh_token&refresh_token=fixture","fixture",function(){calls++})
    complete(requests[0],0);compare(requests.length,2);compare(calls,0);compare(recoveries,1)
    complete(requests[1],0);compare(requests.length,2);compare(calls,1)
  }
  function test_timeoutRecoveryAndCancellationIgnoreLateReplies(){
    var auth=createTemporaryObject(component,testCase);var calls=0
    auth.postTokenRequest("grant_type=refresh_token&refresh_token=fixture","fixture",function(){calls++})
    verify(auth.recoverTokenRequest());verify(requests[0].aborted);compare(requests.length,2)
    complete(requests[0],200,'{"access_token":"late","expires_in":3600}');compare(calls,0)
    auth.cancelLogin();complete(requests[1],200,'{"access_token":"late","expires_in":3600}');compare(calls,0)
  }
  function test_authorizationCodeIsNeverReplayed(){
    var auth=createTemporaryObject(component,testCase);var calls=0
    auth.postTokenRequest("grant_type=authorization_code&code=fixture","",function(){calls++})
    complete(requests[0],0);compare(requests.length,1);compare(calls,1)
  }
}
