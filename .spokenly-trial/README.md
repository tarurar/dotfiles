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

Use only the switch to launch the dictation apps. Keep Spokenly's own login
autostart disabled. The package desktop launcher and direct execution bypass
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
