#!/usr/bin/env python3
"""Exercise the actual controller with disposable user units and fake apps.

Only unit names prefixed wf-dictation-test- are used. No dictation app is run.
"""
import ctypes
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time


SOURCE = Path(__file__).resolve().parents[1]
PREFIX = 'wf-dictation-test-'


def load(root):
    loader = importlib.machinery.SourceFileLoader(
        'dictation_mode', str(SOURCE / 'bin/dictation-mode'))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    module.STATE_ROOT = root / 'state'
    original_systemctl = module.systemctl

    def translated(*args, **kwargs):
        mapped = [PREFIX + arg if arg.endswith('.service') and (
            arg in ('voxtype.service', 'spokenly.service')
            or arg.startswith('dictation-switch@')) else arg for arg in args]
        result = original_systemctl(*mapped, **kwargs)
        if 'list-jobs' in args:
            lines = []
            for line in result.stdout.splitlines():
                fields = line.split()
                if len(fields) == 4 and fields[1].startswith(PREFIX):
                    fields[1] = fields[1].removeprefix(PREFIX)
                    lines.append(' '.join(fields))
            result.stdout = '\n'.join(lines)
        return result

    def fake_identity(name, arguments):
        return {'wf-test-vx': 'voxtype', 'wf-test-sp': 'spokenly'}.get(name)

    module.systemctl = translated
    module.dictation_app = fake_identity
    original_verify = module.Manager.verify

    def verify(manager, app):
        original_verify(manager, app)
        if app == 'spokenly' and (root / 'hold').exists():
            (root / 'verifying').touch()
            time.sleep(60)

    module.Manager.verify = verify
    return module


def ctl(*args, check=True):
    return subprocess.run(['systemctl', '--user', *args], text=True,
                          capture_output=True, check=check, timeout=40)


def wait_for(check, description):
    deadline = time.monotonic() + 12
    while time.monotonic() < deadline:
        if check():
            return
        time.sleep(0.1)
    raise AssertionError('timed out: ' + description)


def run_rehearsal():
    with tempfile.TemporaryDirectory(prefix='wf-dictation-test-') as directory:
        root = Path(directory)
        script = Path(__file__).resolve()
        runner = f'/usr/bin/python3 {script} worker {root}'
        units = []
        module = load(root)
        store = module.State(root / 'state')
        store.initialize()
        store.select('voxtype')
        for app in module.APPS:
            name = PREFIX + app + '.service'
            ordering = f'Before={PREFIX}spokenly.service' if app == 'voxtype' else ''
            body = f'''[Unit]
Description=Disposable dictation switch test ({app})
{ordering}
[Service]
Type=exec
ExecCondition={runner} _admit {app}
ExecStart=/usr/bin/python3 {script} app {root} {app}
TimeoutStopSec=3
KillMode=control-group
'''
            (root / name).write_text(body)
            units.append(name)
        template = PREFIX + 'dictation-switch@.service'
        (root / template).write_text(f'''[Unit]
Description=Disposable dictation switch supervisor
[Service]
Type=oneshot
ExecStart={runner} _run %i
ExecStopPost={runner} _cleanup %i
TimeoutStartSec=75
TimeoutStopSec=10
KillMode=control-group
''')
        units.append(template)
        instances = [PREFIX + f'dictation-switch@{target}.service'
                     for target in (*module.APPS, 'recover')]
        try:
            ctl('link', '--runtime', *(str(root / name) for name in units))
            ctl('daemon-reload')
            ctl('start', PREFIX + 'voxtype.service', PREFIX + 'spokenly.service')
            module.Manager().verify('voxtype')
            print('PASS simultaneous login starts select only Voxtype', flush=True)

            ctl('start', PREFIX + 'dictation-switch@spokenly.service')
            module.Manager().verify('spokenly')
            assert store.selection() == 'spokenly' and store.journal() is None
            print('PASS real service switch and ownership', flush=True)

            ctl('stop', PREFIX + 'voxtype.service', PREFIX + 'spokenly.service')
            ctl('start', PREFIX + 'voxtype.service', PREFIX + 'spokenly.service')
            module.Manager().verify('spokenly')
            print('PASS simultaneous login starts select only Spokenly', flush=True)

            ctl('restart', PREFIX + 'voxtype.service')
            module.Manager().verify('spokenly')
            print('PASS unselected restart leaves selected app running', flush=True)

            ctl('start', PREFIX + 'dictation-switch@voxtype.service')
            (root / 'fail-spokenly').touch()
            result = ctl('start', PREFIX + 'dictation-switch@spokenly.service', check=False)
            assert result.returncode != 0
            module.Manager().verify('voxtype')
            assert store.selection() == 'voxtype' and store.journal() is None
            (root / 'fail-spokenly').unlink()
            print('PASS real target failure automatically restores previous app', flush=True)

            (root / 'hold').touch()
            ctl('start', '--no-block', PREFIX + 'dictation-switch@spokenly.service')
            wait_for(lambda: (root / 'verifying').exists(), 'verification phase')
            ctl('kill', '--signal=KILL', '--kill-whom=main',
                PREFIX + 'dictation-switch@spokenly.service')
            wait_for(lambda: store.journal()['phase'] == 'degraded', 'cleanup journal')
            wait_for(lambda: not module.processes(), 'both apps stopped by cleanup')
            assert store.selection() is None
            print('PASS SIGKILL invokes fail-closed cleanup', flush=True)

            # A persistent journal after loss of its supervisor must deny starts.
            store.select('spokenly')
            ctl('start', PREFIX + 'spokenly.service')
            assert not module.processes()
            store.suppress()
            print('PASS stale transaction blocks startup despite target marker', flush=True)

            (root / 'hold').unlink()
            ctl('start', PREFIX + 'dictation-switch@recover.service')
            module.Manager().verify('voxtype')
            assert store.selection() == 'voxtype' and store.journal() is None
            print('PASS explicit recovery restores previous app', flush=True)
        except Exception:
            logs = subprocess.run(['journalctl', '--user', '--no-pager', '-n', '60',
                                   *[arg for unit in instances + units
                                     for arg in ('-u', unit)]],
                                  capture_output=True, text=True)
            print(logs.stdout, file=sys.stderr)
            raise
        finally:
            ctl('stop', *instances, *(PREFIX + app + '.service' for app in module.APPS),
                check=False)
            for name in units:
                link = Path(os.environ['XDG_RUNTIME_DIR']) / 'systemd/user' / name
                if link.is_symlink() and link.resolve() == root / name:
                    link.unlink()
            ctl('daemon-reload')
            ctl('reset-failed', *instances,
                *(PREFIX + app + '.service' for app in module.APPS), check=False)


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'app':
        root, app = Path(sys.argv[2]), sys.argv[3]
        if (root / ('fail-' + app)).exists():
            sys.exit(1)
        name = b'wf-test-vx' if app == 'voxtype' else b'wf-test-sp'
        ctypes.CDLL(None).prctl(15, name, 0, 0, 0)
        time.sleep(300)
    elif len(sys.argv) > 1 and sys.argv[1] == 'worker':
        module = load(Path(sys.argv[2]))
        try:
            sys.exit(module.main(sys.argv[3:]))
        except Exception as error:
            print(str(error), file=sys.stderr)
            sys.exit(1)
    else:
        run_rehearsal()
