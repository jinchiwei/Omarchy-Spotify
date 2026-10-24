import QtQuick
import Quickshell.Io
import "Api.js" as Api

// A single local event connection; CLI controls also stay on loopback.
Item {
  id: root
  property bool wanted: false
  property bool loggedIn: false
  property string deviceName: "Omarchy Soloist"
  property var state: ({})
  property var queue: []
  property var current: null
  readonly property bool ready: wanted && trace.running && loggedIn
  signal stateReceived(var value)

  function handleLine(line) {
    var event = Api.parseSoloistTraceLine(line)
    if (!event) return
    if (event.type === "auth_state") {
      loggedIn = event.logged_in === true
      if (event.device_name) deviceName = event.device_name
      return
    }
    if (["playback_state", "track_changed", "playback_changed", "context_changed",
         "options_changed", "volume_changed", "position_sync"].indexOf(event.type) < 0
        && typeof event.is_active !== "boolean") return
    state = Api.mergeSoloistState(state, event)
    stateReceived(state)
  }
  function refresh() { if (wanted && !snapshot.running) snapshot.running = true }
  function send(args, callback) {
    if (!ready || !args || !args.length) return false
    if (queue.length >= 16) {
      if (callback) callback(false, "Too many pending local playback commands. Try again.")
      return true
    }
    queue = queue.concat([{args:args, callback:callback}])
    pump()
    return true
  }
  function pump() {
    if (control.running || !queue.length) return
    current = queue[0]
    queue = queue.slice(1)
    control.command = ["soloist", "ctl"].concat(current.args)
    control.running = true
  }
  onWantedChanged: {
    trace.running = wanted
    if (!wanted) { loggedIn = false; state = ({}) }
  }
  Process {
    id: trace
    command: ["soloist", "ctl", "trace"]
    stdout: SplitParser { onRead: function(line) { root.handleLine(line) } }
    onExited: root.loggedIn = false
  }
  Timer {
    interval: 2000
    repeat: true
    running: root.wanted && !trace.running
    onTriggered: trace.running = true
  }
  Process {
    id: snapshot
    command: ["soloist", "ctl", "now", "--json"]
    stdout: StdioCollector { id: snapshotOutput; waitForEnd: true }
    onExited: function(code) { if (code === 0) root.handleLine(snapshotOutput.text) }
  }
  Process {
    id: control
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector { id: controlError; waitForEnd: true }
    onExited: function(code) {
      var job = root.current
      root.current = null
      if (job && typeof job.callback === "function")
        job.callback(code === 0, code === 0 ? "" : Api.redact(controlError.text || "Local playback command failed"))
      root.refresh()
      Qt.callLater(root.pump)
    }
  }
}
