import QtQuick
import QtTest
import "../Api.js" as Api
TestCase {
  name: "SoloistIntegration"
  function test_pausedLocalReceiverStillChecksCloud() {
    verify(Api.remotePlaybackPollShouldRun(true,false,false,false,false,true,true))
    verify(!Api.remotePlaybackPollShouldRun(false,false,false,false,false,true,true))
    compare(Api.remotePlaybackPollInterval(false,false,true,true,false),60000)
    compare(Api.remotePlaybackPollInterval(true,false,true,true,false),15000)
  }
  function test_rememberedInactiveDeviceSurvivesReopen() {
    var rows = [{id:"solo",name:"Omarchy Soloist",active:false},
      {id:"phone",name:"Phone",active:false}]
    compare(Api.preferredPlaybackDevice(rows,"",false,null,"solo","Omarchy Soloist").id,"solo")
    compare(Api.preferredPlaybackDevice(rows,"phone",true,null,"solo","Omarchy Soloist").id,"phone")
    rows[0].id="new-id"
    compare(Api.preferredPlaybackDevice(rows,"",false,null,"old-id","Omarchy Soloist").id,"new-id")
  }
  function test_activePhoneTakesPrecedenceOverRememberedLaptop() {
    var rows = [{id:"solo",name:"Omarchy Soloist",active:false},
      {id:"phone",name:"Phone",active:true}]
    compare(Api.preferredPlaybackDevice(rows,"",false,rows[1],"solo","Omarchy Soloist").id,"phone")
    compare(Api.preferredPlaybackDevice(rows,"solo",true,rows[1],"solo","Omarchy Soloist").id,"solo")
  }
  function test_localControlsDoNotNeedCloudRequests() {
    compare(Api.soloistControlArgs("PUT","/me/player/repeat",{state:"track"}),["repeat","track"])
    compare(Api.soloistControlArgs("PUT","/me/player/pause",{}),["pause"])
    compare(Api.soloistControlArgs("POST","/me/player/next",{}),["next"])
    compare(Api.soloistControlArgs("PUT","/me/player/shuffle",{state:"false"}),["shuffle","off"])
    compare(Api.soloistControlArgs("PUT","/me/player/seek",{position_ms:1200}),["seek","1200"])
  }
  function test_loopResetUsesLocalPosition() {
    var raw={status:"playing",position:{position_ms:99000},options:{repeat:"track"},
      is_active:true,item:{uri:"spotify:track:abc",entity_type:"track",decorations:{
        identity:{name:"Song"},playback:{duration_ms:100000}}}}
    compare(Api.normalizePlaybackState(Api.soloistPlaybackPayload(raw,"solo","Omarchy Soloist"),96).progressSeconds,99)
    raw.position.position_ms=200
    var next=Api.normalizePlaybackState(Api.soloistPlaybackPayload(raw,"solo","Omarchy Soloist"),96)
    compare(next.progressSeconds,0.2)
    compare(next.repeatMode,"track")
    compare(next.item.name,"Song")
  }
  function test_tracePrefixAndGranularPosition() {
    var event=Api.parseSoloistTraceLine('123 {"type":"position_sync","position":{"position_ms":0}}')
    compare(event.type,"position_sync")
    compare(Api.mergeSoloistState({status:"playing",position:{position_ms:1000}},event).position.position_ms,0)
    compare(Api.parseSoloistTraceLine("connected to ws://127.0.0.1:123"),null)
  }
}
