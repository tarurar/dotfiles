# Isolated Spokenly trial files

These files belong to the isolated `trial/spokenly` dotfiles worktree. Deploy
explicit copies with `./deploy install`; do not apply the dotfiles tree.

The migration runbook and package review live in
`/home/tarurar/Sources/spokenly-migration/docs/runbooks/prepare-spokenly-trial.md`.

## Switch

```sh
dictation-mode status
dictation-mode spokenly
dictation-mode voxtype
dictation-mode recover
```

Use only the switch to launch the dictation apps. The service passes native
`--autostart` so login and switch activation run Spokenly in the background
without opening its main window. Keep Spokenly's own login autostart disabled.
The package desktop launcher and direct execution bypass
the trial operating rule. Close any reported unmanaged process before switching.

Spokenly receives private XDG config, data, cache, and state directories under
`~/.local/state/spokenly-migration/spokenly/`. This keeps app settings and model
downloads separate from the normal desktop directories. Runtime inspection
must still check for app paths that ignore XDG variables. Retain this entire
private app directory when temporarily switching back to Voxtype.

The private selection and durable transaction are stored in
`~/.local/state/spokenly-migration/dictation-mode/`. Exactly one marker permits
startup when stable. A transaction admits only its current target while its
exact systemd supervisor invocation is alive. Both apps are gated even when the
NuPhy helper requests a Voxtype restart. Voxtype is ordered before Spokenly
when both receive login start jobs; there are no conflicting-unit dependencies.

The supervisor serializes changes, records previous selection and phases,
stops both apps, admits the target, verifies process ownership for a full
second, then commits. Failure restores the previous app. Unexpected supervisor
exit invokes systemd cleanup that removes permission markers, stops both apps,
and keeps the transaction for `recover`. No app is ordered against the
supervisor: its synchronous start/stop commands must not depend on itself.

Systemd must remain running to perform cleanup. Killing the user manager or
cleanup process itself cannot provide synchronous cleanup; after reboot the
durable transaction still denies startup. A process check is not application
readiness: a later crash is handled by the selected app's restart policy.
Dictation, local-only mode, language quality, and text insertion need separate
human checks before the grace period.

## Checks

```sh
python3 -m unittest discover -s tests -v
python3 tests/systemd_rehearsal.py
```

The second command uses temporary `wf-dictation-test-*` user units and fake
processes, then removes them. It does not start or stop the real apps.

## Inverse

First select Voxtype. Then `./deploy remove` removes only the installed files
whose hashes still match the private deployment manifest and restores the
original Voxtype service. It retains the source worktree, package, and private
state. Do not remove the restore point during the trial or cooling-off period.

The manifest is
`~/.local/state/spokenly-migration/switch-deployment.json`. It records source
paths, destination paths, hashes, modes, created directories, and inverse
operations. If a deployed file changes, removal refuses to overwrite that
change. If a transaction is corrupt, preserve it for inspection; the command
does not guess its previous selection. The rehearsed baseline remains the
manual recovery authority.

## Verified Linux input setup

Use local Parakeet V3, Local Only Mode, Smart Paste, and the `rcmd` mode
shortcut. Framework AltGr is already mapped to Right Meta; NuPhy Right Cmd
uses the same key. The UI recorder does not capture these keys reliably.
The global `mainShortcutDefaultKeys` value is not the active mode binding:
that binding lives in `modes.v2.envelope.items[].value.shortcutWindows.keys`.

The Spokenly service hides `/usr/bin/wtype` to use ydotool. The Hyprland rule
in `hypr/spokenly-trial.lua` prevents only the Recording overlay from taking
focus. Without it, Spokenly sends a valid Ctrl+V to its own overlay instead
of the editor. The settings window remains focusable.

Deployment additionally appends the exact guarded block in
`hypr/bootstrap.lua` to the existing Hyprland Lua config. This small include
is the documented exception to additive-only deployment. Its text and path
are recorded in the deployment manifest. Removal strips that exact block,
preserves subsequent unrelated edits, and refuses an altered block. The
rule is disabled immediately on removal; its declaration also disappears
on the next config reload. Do not restore the whole config backup over later
user changes.

After a clean restart, the user verified every combination of English and
Russian, Framework and NuPhy keyboards, and T3 Code and VS Code: recognition
and automatic insertion work. NuPhy reconnect followed by dictation passed,
and Voxtype remained inactive. The setup is trial-ready. Clipboard retention
is off; the user accepts clipboard history capturing Smart Paste temporarily.

## Temporary wake workaround

Spokenly 0.3.20 abandons its evdev listener on EINTR after suspend. This was
also reproduced by briefly stopping and continuing the main process. The
application bug has been reported upstream; restarting is a temporary
workaround, not an internal fix.

`spokenly-resume.service` runs for the graphical session and listens for
login1 `PrepareForSleep(false)` using Python dbus and PyGObject (both must be
installed). Two seconds after wake it queues
`dictation-switch@resume-spokenly.service`. The existing supervisor checks
selection under its lock: Voxtype is a no-op, unfinished transactions are
refused, and selected Spokenly is restarted through the normal transaction.
Concurrent switch requests can cause the resume request to be refused; it
never overrides a user's selection or automatically recovers a transaction.
A repeated notification replaces the timer; another sleep cancels it.

The watcher stays independent of the app service so restarting Spokenly
cannot terminate the watcher. Native `--autostart` keeps the app hidden.
Restarting does not retain an in-progress recording. The watcher reads no
key events and performs no device polling.

Fresh `deploy install` records and enables the watcher. Existing deployments
are not automatically upgraded by `install`; this laptop was upgraded with
hash checks and a private backup of the old control file and manifest under
`runtime-inventory/resume-upgrade-2026-09-05/`. The manifest records the new
files and enable link. `deploy remove` stops and disables the watcher before
removing the recorded files, after Voxtype has been selected.

Disable just the workaround:

```sh
systemctl --user disable --now spokenly-resume.service
```

Re-enable with `systemctl --user enable --now spokenly-resume.service`.
Inspect operational logs with:

```sh
journalctl --user -u spokenly-resume.service -u dictation-switch@resume-spokenly.service
```

All 30 source tests and installed unit verification pass. A simulated wake
through the actual callback preserved Voxtype's PID when selected, and
restarted only Spokenly when selected (30 input handles, zero mapped windows).
A real sleep/wake check also passed on 2026-09-05: wake at 23:08:41 UTC+03,
watcher request at 23:08:44, successful restart at 23:08:46, followed by
user-confirmed dictation and 30 input handles with only Spokenly running.
This verifies one actual wake. Once an upstream fix
passes both the stop/continue reproduction and real sleep/wake with this
watcher disabled, remove the workaround and update the deployment inventory.
Detailed evidence is in the migration repository's
`docs/diagnostics/spokenly-resume-2026-09-05.md`.
