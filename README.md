# Omarchy Spotify

**Spotify in Quickshell—not Chromium.**

Omarchy Spotify brings the Spotify experience you already know into a fast,
beautiful Omarchy plugin. It uses about **60 MB of RAM** instead of roughly
**950 MB** for the Spotify desktop client, follows your active Omarchy theme,
and keeps your music close with an integrated mini player.

Pair it with **Omasing** and lyrics for the song you are playing are fetched
for you, ready when you want them.

## Install

```bash
omarchy plugin add https://github.com/jinchiwei/Omarchy-Spotify.git --enable
```

Requires Omarchy 4 and a personal Spotify Premium account.

## Why you will love it

- **Lightweight by design.** Enjoy your music without keeping a browser-sized
  desktop client running.
- **Made for Omarchy.** Every color follows your current theme automatically,
  including light themes.
- **Always within reach.** Play, pause, skip, seek, change volume, or open
  lyrics from the mini player in your bar. Your last song stays loaded, so
  Play picks up where you left off even after the player has gone idle.
- **Your full music library.** Search Spotify, browse artists and albums,
  manage playlists and the queue, and move playback between Spotify Connect
  devices.
- **Lyrics with Omasing.** Open the current song in Omasing and let it find the
  right lyrics and playback position automatically.

## Familiar from the first click

The layout is inspired by the Spotify client, so there is almost nothing new
to learn. Your library and playlists live in the sidebar, search stays at the
top, the player stays at the bottom, and artist and album names take you
straight to their pages.

Prefer to keep your hands on the keyboard? The whole app is designed for that
too.

| Shortcut | What it does |
| --- | --- |
| `Ctrl+F` or `/` | Search all of Spotify |
| `Ctrl+F` or `/` again | Toggle current area / all of Spotify |
| `Tab` / `F6` | Move between sidebar, search, the song list, and the player |
| `Arrow keys` | Move to a control; Enter activates |
| `C` | Row actions; arrows or Enter choose |
| `Space` | Play or pause |
| `Ctrl+Left` / `Ctrl+Right` | Previous or next song |
| `Shift+Left` / `Shift+Right` | Seek 10 seconds |
| `Ctrl+Up` / `Ctrl+Down` | Change volume |
| `M` | Mute or restore volume |
| `Ctrl+Shift+A` | Open the current song's artist |
| `Ctrl+Shift+B` | Open the current song's album |
| `Ctrl+/` | See every keyboard shortcut |
| `Ctrl+H` | Hide visible shortcut hints |

The first shortcut, Tab, or opening the player from the keyboard lights
matching controls with the next key. Hold Ctrl, Shift, or Alt to see those
chords; the matching hints remain until you release the held modifiers. While
hints are visible, the header keeps a **Ctrl+H · Hide hints** action in reach.
It turns hints off until you enable them again in Settings.

![Shortcut hints guiding focus down the Recently played song list](docs/media/shortcut-hints.gif)

The mini-player takes keyboard focus when it is opened from a shortcut. Use
`Tab` or the arrow keys to select every control, `Enter` to activate buttons,
left/right to adjust a selected slider, and `Esc` to close. The playback
shortcuts above work there too; `Ctrl+S` toggles shuffle, `Ctrl+R` cycles
repeat, `Ctrl+Shift+L` opens lyrics, `Ctrl+Shift+A` and `Ctrl+Shift+B` open the
current artist or album in the full player, and `O` expands the full player.

## See it in action

### Your playlists, instantly familiar

Everything is where you expect it to be—just faster, lighter, and dressed in
your Omarchy theme.

![Vietnam War Music playlist in Omarchy Spotify](docs/screenshots/vietnam-war-playlist.png)

### Everything from an artist, in one view

Top albums and EPs sit beside the artist's ten biggest songs, with their
**This Is** playlist and full catalog only a search away.

![Red Hot Chili Peppers artist page with Under the Bridge playing](docs/screenshots/red-hot-chili-peppers-under-the-bridge.png)

### Lyrics, already matched to the song

One click sends the current track to Omasing, where the lyrics are fetched and
lined up with your playback position—ready to auto-scroll as you listen.

![Omarchy Spotify beside Omasing lyrics for Under the Bridge](docs/screenshots/omasing-lyrics-under-the-bridge.png)

### A mini player that belongs in your desktop

The essentials are always one click away, without reopening the full app.

![Omarchy Spotify mini player playing Under the Bridge](docs/screenshots/mini-player-under-the-bridge.png)

## Set it up

To replace Omarchy's existing **Super+Shift+M · Music** binding, add this to
`~/.config/hypr/bindings.lua`:

```lua
  hl.unbind("SUPER + SHIFT + M") -- previously: Music
  o.bind("SUPER + SHIFT + M", "Omarchy Spotify",
    "omarchy shell -q quickshell.spotify.player togglePlayer")
```

Run `hyprctl reload` and check `hyprctl configerrors` after saving. Until the
binding is replaced, Omarchy's stock Music binding stays active and the
Settings choice below has no effect on the shortcut.

In Omarchy Spotify's Settings, choose whether that shortcut launches Omarchy's
Music app, toggles the full player, or toggles the mini-player. Separate
bindings can call `toggleMiniPlayer` or `toggleFullPlayer` on the same
`quickshell.spotify.player` target.

Raise or lower Spotify volume from a keybinding without opening the player:

```bash
omarchy shell -q quickshell.spotify.player volumeUp
omarchy shell -q quickshell.spotify.player volumeDown
```

Each step is 5%, the same as Ctrl+Up / Ctrl+Down. This changes Spotify's own
volume, including speakers, not the computer's output level.

Click the Spotify icon on the left side of the bar. The mini-player asks you
to **Set up and continue**, then Spotify sign-in finishes in your browser. You
can move the widget later with Omarchy's bar controls.

Local playback installs an exact-version backend only after its GitHub build
provenance matches this plugin version's tag and the checkout's backend inputs
still match that tagged source. If verification is unavailable, setup builds
the locked Rust source locally or offers Omarchy's packaged `spotifyd` fallback
instead of executing an unverified download.

## Seeing "Spotify is busy." or slow searches?

This fork requires a personal [Spotify Developer app](https://developer.spotify.com/dashboard)
and never falls back to the original plugin's shared Web API credentials. You can
still encounter Spotify rate limits with your own app. Development-mode apps under
the same developer account share a quota; creating more Client IDs does not increase
that budget. Respect Retry-After, reuse loaded pages, and avoid unnecessary refreshes.
A personal app does not provide unlimited requests or restore restricted endpoints.

1. Add `http://127.0.0.1:8989/login` as the app's redirect URI.
2. Set **Spotify Developer app client ID** in the plugin settings and click **Apply app**.
   Blank or malformed IDs produce an error; there is no shared fallback.
3. Authorize the selected app. Changing the ID clears the current session and
   account data; stored sessions are isolated by client ID.

Development apps require an eligible Premium owner and allowlisted users, and
have endpoint restrictions. See Spotify's [quota modes](https://developer.spotify.com/documentation/web-api/concepts/quota-modes).
The local Connect authorization remains separate.

## Remove it completely

Run the bundled uninstaller from outside the plugin directory:

```bash
cd "$HOME" && "$HOME/.config/omarchy/plugins/quickshell.spotify/scripts/uninstall.sh"
```

It disables and removes the plugin, stops and removes both user services,
restarts the shell, and deletes all plugin-owned configuration, cached audio,
backend build files, installed binaries, playback state, runtime sockets, old
configuration backups, and matching GNOME Keyring entries.

If you prefer to inspect and paste the main steps individually:

```bash
plugin_dir="$HOME/.config/omarchy/plugins/quickshell.spotify"
cd "$HOME"
omarchy plugin disable quickshell.spotify 2>/dev/null || true
"$plugin_dir/scripts/remove-runtime.sh" --purge
omarchy plugin remove quickshell.spotify --yes
omarchy restart shell
```

The cleanup deliberately leaves unrelated software alone. A source checkout
outside Omarchy's plugin directory, separate plugins such as Omasing, and the
`spotifyd` package remain in place. If this plugin was the only reason you
installed the fallback package, remove it with:

```bash
omarchy pkg drop spotifyd
```

Very old installation instructions may also have added a custom Hyprland
shortcut. The uninstaller reports any such references without rewriting your
personal configuration. Check both the live config and, when applicable, its
chezmoi source:

```bash
rg -n 'quickshell\.spotify|Omarchy Spotify' \
  "$HOME/.config/hypr" "$HOME/.local/share/chezmoi" 2>/dev/null
```

Remove only the matching custom lines, apply the dotfiles change, and run
`hyprctl reload`. Omarchy's stock **Super+Shift+M** Music shortcut will then be
used again.

## More music, less app

- Discover Weekly, Release Radar, Daily Mixes, daylist, and more in **Discover**.
- Browse Liked Songs, saved albums, followed artists, podcasts, and books.
- Create playlists, add songs, reorder tracks, and turn followed playlists
  into your own editable copies when Spotify makes their contents available.
- Build a queue, start track radio, use shuffle and repeat, or set a sleep timer.
- Listen on this computer or switch to another Spotify Connect speaker or player.
- Choose the mini-player or full player independently for the bar icon and
  keyboard shortcut, use optional spinning vinyl artwork in the mini-player,
  show the title, artist, or both, and softly scroll overflowing text at an
  adjustable speed.
- Choose up to 320 kbps for local playback.

Your Spotify password is entered only on Spotify's own page. Omarchy Spotify
stores your saved session in GNOME Keyring and clears it when you log out.

Want the details? Read the [technical notes](docs/TECHNICAL.md) or see the
[memory benchmark](docs/BENCHMARK.md).

Omarchy Spotify is an independent project and is not affiliated with Spotify.
Spotify is a trademark of Spotify AB.

Licensed under the [MIT License](LICENSE).

## Using Spotify Soloist or another external receiver

Choose **Spotify Connect** for **Playback engine** in the bar widget settings
(or run `omarchy bar set quickshell.spotify playbackEngine 'Spotify Connect'`).
This keeps the Omarchy interface and Web API login, but does not start or require
the bundled local playback engine. Select the separately running receiver in
Devices; a currently active receiver is selected automatically.

Spotify Soloist is Spotify's official headless playback receiver. Follow its
[official setup guide](https://developer.spotify.com/documentation/soloist/tutorials/getting-started)
to obtain your own private key, install the appropriate build, and pair it through
an official Spotify app. Never commit or redistribute your key or the binary.
Soloist builds expire after 90 days and require an update. The receiver's service,
key, data, and updates are managed separately from this plugin's uninstaller.

### Soloist user-service example (Linux)

After installing the official executable as `~/.local/bin/soloist`, create
`~/.config/soloist/key.env` containing `SOLOIST_API_KEY=your-own-key`. Create the
directory with mode 700 and the file with mode 600. Keep it outside this repo.
Copy `systemd/omarchy-soloist.service.example` to
`~/.config/systemd/user/omarchy-soloist.service`, then run:

```bash
systemctl --user daemon-reload
systemctl --user stop omarchy-spotifyd.service omarchy-spotify.service
systemctl --user enable --now omarchy-soloist.service
omarchy bar set quickshell.spotify playbackEngine 'Spotify Connect'
omarchy restart shell
```

Pair **Omarchy Soloist** once from an official Spotify app on the same network,
then select it in this plugin's Devices list. `soloist ctl status` verifies the
receiver is running and logged in. The receiver is separate from this plugin;
its key is separate from your Web API app's Client ID. Spotify's six-month
Web API reauthorization rule still applies to the interface.

Update the receiver before its 90-day build expiry by replacing the executable
with a fresh build from Spotify's official download page and restarting
`omarchy-soloist.service`. Preserve its data directory to retain pairing.
To remove the receiver, disable/stop its service and remove its unit, executable,
private key directory, `~/.local/share/soloist`, and `~/.cache/soloist`.

The mini-player and full-player song titles follow the theme accent by default.
For an independent title color, for example cyan:

```bash
omarchy bar set quickshell.spotify titleColor '#00E8C6'
```

Set `titleColor` to an empty string to follow the theme again. These are local
settings; do not hardcode your personal client ID, key, or sessions in the plugin.

### Responsive Soloist controls and remembered devices

For the local Soloist receiver, enable its live event stream and local transport
controls instead of sending every button through the Web API:

```bash
omarchy bar set quickshell.spotify soloistLocalControl On
omarchy bar set quickshell.spotify preferredDeviceName 'Omarchy Soloist'
omarchy restart shell
```

`soloist` must be on PATH and already running with its loopback WebSocket API
(`--ws 127.0.0.1:0` in the service example). One local `soloist ctl trace` connection
keeps position, repeat, shuffle, volume, and track metadata current. Controls use
argument arrays through `soloist ctl`; no key or refresh token is sent to this
local interface. Cloud catalog/library access remains subject to Spotify's API
latency and quota. Remote devices keep using the normal Spotify API controls.

The device picker remembers the selected device ID and name across player and
shell restarts. If its ID changes, the remembered name provides a fallback.
Selecting a different device updates this preference. To remove the preference,
set `preferredDeviceId` and `preferredDeviceName` to empty strings.

Check the active path with:

```bash
omarchy shell quickshell.spotify.player playbackEngineStatus
```

`soloist-local` means transport and live state are local. The profile header uses
the signed-in account's display name and avatar; profile data is never hardcoded.

### Loading a complete playlist

**Load remaining songs** retrieves the rest sequentially, with a loaded count.
No parallel page burst is used. Switching playlists, leaving the playlist view,
closing the player, a page error, or a rate-limit response stops the batch. Already
loaded songs are kept, including intentional duplicates. The existing 10,000-item
safety limit remains. Reopen the playlist and click again to continue as needed.

### Playlist actions and request timing

The full player's current-song row has an explicit **Add to playlist** button
(icon-only on compact windows), separate from the heart for Liked Songs. It opens
your editable playlists, loads the sidebar list if needed, and supports paging
and creating a playlist. Song rows and context menus use “Add to Liked Songs”
to distinguish liking from playlist membership.

Requested library pages get priority over queued background reads. The requested
page starts before optional profile/sidebar loads; playlists already returned by
the user's library don't need another saved-status check.

For latency diagnosis, `omarchy shell quickshell.spotify.player requestTimings`
returns a bounded list of sanitized API routes, queue/token/HTTP timing and statuses,
plus current queue size/cooldown. It excludes credentials, bodies, queries and song
metadata. A fast local receiver cannot remove latency from cloud library endpoints.

Profile loads are deduplicated while pending. Opening another player surface respects
the existing five-minute liked-status cache rather than forcing another lookup.
The playlist button is labeled **Load more** while retaining one-click remaining-page
loading with stop-on-close/error/rate-limit behavior.

The optional current-song liked-status lookup waits for foreground page requests to
finish. It still updates the heart when idle; it cannot put a newly opened library
page behind its own rate-limit retry before that page has loaded.

The personal-app settings section explicitly shows whether a personal app
is configured. Request timing diagnostics include the resolved public Client ID and loaded
item counts, so troubleshooting can verify the actual app instead of assuming that a
previous OAuth grant also persisted the setting. Personal IDs are machine settings;
no personal ID or private Soloist key is baked into the plugin.

### This fork requires your own Spotify app

There is **no fallback to the original author's shared Web API app**. Configure
your own Spotify Developer Client ID in Settings → Personal Spotify App and apply
it before signing in. A blank/malformed ID gives an actionable setup error instead
of silently sending traffic through another developer's quota. The existing official
Spotify Connect streaming integration remains separate from the personal Web API app.

This repository contains no personal app ID, Soloist API key, refresh token, or
private session. Each user supplies their own credentials using the setup above.

The optional lyrics installer downloads [jinchiwei/Omasing](https://github.com/jinchiwei/Omasing).
Its install prompt displays that same configured repository URL.

Lyrics availability uses Omarchy's public widget catalogue and bar placement on
versions with a self-scoped plugin registry. This avoids prompting to install an
already enabled Omasing widget. `omarchy shell quickshell.spotify.player lyricsStatus`
reports its detected state; `showLyrics` opens lyrics for the current song.
