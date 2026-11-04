#!/usr/bin/env bash
set -euo pipefail
root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
mkdir -p "$test_root/fixture/scripts" "$test_root/app"
cp "$root/HttpTransport.qml" "$test_root/app/"
sed 's|import "../.." as Plugin|import "." as Plugin|' "$root/tests/integration/HttpRecovery.qml" > "$test_root/app/shell.qml"
cat > "$test_root/fixture/scripts/spotify-http.py" <<'PY'
import sys,json,time
p=json.loads(sys.stdin.readline())
if p['url'].endswith('/slow'):time.sleep(60)
print(json.dumps({'status':429,'headers':{'retry-after':'120'},'body':json.dumps({'method':p['method'],'body':p['body'],'argc':len(sys.argv)})}))
PY
env TEST_HTTP_DIR="$test_root/fixture" XDG_STATE_HOME="$test_root/state" QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME=generic timeout 10 qs --no-color -p "$test_root/app" > "$test_root/output" 2>&1 || { cat "$test_root/output"; exit 1; }
cat "$test_root/output"
rg -q HTTP_RECOVERY_PASS "$test_root/output"
! rg -q 'ReferenceError|TypeError|Error:|HTTP_RECOVERY_TIMEOUT' "$test_root/output"
echo 'Isolated HTTP transport integration passed.'

cp "$root/"{AuthManager.qml,Api.js,OAuth.js} "$test_root/app/"
sed 's|import "../.." as Plugin|import "." as Plugin|' "$root/tests/integration/AuthRecovery.qml" > "$test_root/app/shell.qml"
env XDG_STATE_HOME="$test_root/state" QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME=generic timeout 10 qs --no-color -p "$test_root/app" > "$test_root/auth-output" 2>&1
cat "$test_root/auth-output"
rg -q AUTH_RECOVERY_PASS "$test_root/auth-output"
! rg -q 'AUTH_RECOVERY_FAIL|ReferenceError|TypeError' "$test_root/auth-output"
