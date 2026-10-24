import QtQuick
import Quickshell
import "../.." as Plugin

ShellRoot {
  Plugin.AuthManager {
    id: auth
    pluginDir: "/nonexistent"
    property int restores: 0
    function restoreSession() { restores++; sessionChecked = true }
  }
  Plugin.DaemonManager {
    id: daemon
    property int installs: 0
    function checkRequirements() {}
    function setupPlayback() { installs++ }
  }
  Timer {
    interval: 100
    running: true
    onTriggered: {
      if (auth.restores !== 1) throw new Error("Saved session was not restored exactly once on startup")
      daemon.pluginDir = "/nonexistent"
      daemon.binaryChecked = true
      daemon.unitChecked = true
      daemon.binaryAvailable = true
      daemon.unitAvailable = true
      daemon.usingFallbackRuntime = true
      daemon.installPlaybackBackendIfNeeded()
      if (daemon.installs !== 0) throw new Error("Working fallback unnecessarily triggered installation")
      console.log("STARTUP_PASS")
      Qt.quit()
    }
  }
}
