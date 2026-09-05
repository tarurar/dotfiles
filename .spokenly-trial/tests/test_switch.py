import importlib.machinery
import importlib.util
import os
from pathlib import Path
import tempfile
import unittest


source = Path(__file__).resolve().parents[1] / 'bin' / 'dictation-mode'
loader = importlib.machinery.SourceFileLoader('dictation_mode', str(source))
spec = importlib.util.spec_from_loader(loader.name, loader)
switch = importlib.util.module_from_spec(spec)
loader.exec_module(switch)


class FakeManager:
    def __init__(self):
        self.running = {'voxtype'}
        self.fail_start = set()
        self.unmanaged = set()
        self.jobs = []
        self.events = []
        self.live_owner = True
        self.interrupt = None
        self.store = None

    def owner_alive(self, journal):
        return self.live_owner

    def can_start(self, app):
        return not self.running and not self.unmanaged

    def snapshot(self):
        return {
            'running': set(self.running),
            'unmanaged': set(self.unmanaged),
            'jobs': list(self.jobs),
            'errors': [],
        }

    def stop_all(self):
        self.events.append('stop')
        self.running.clear()
        self.jobs.clear()

    def start(self, app):
        self.events.append('start:' + app)
        if self.store is not None:
            assert switch.admitted(self.store, self, app)
        if self.interrupt == app:
            raise KeyboardInterrupt('simulated process interruption')
        if app in self.fail_start:
            raise switch.SwitchError('simulated startup failure')
        self.running.add(app)

    def verify(self, app):
        state = self.snapshot()
        if state['running'] != {app} or state['unmanaged'] or state['jobs']:
            raise switch.SwitchError('not exclusive')


class SwitchTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.store = switch.State(Path(self.directory.name) / 'state')
        self.store.initialize()
        self.store.select('voxtype')
        self.manager = FakeManager()
        self.manager.store = self.store
        self.controller = switch.Controller(
            self.store, self.manager, 'dictation-switch@spokenly.service',
            'a' * 32,
        )

    def test_healthy_reselection_has_no_service_side_effects(self):
        self.controller.run('voxtype')
        self.assertEqual([], self.manager.events)

    def test_switch_stops_previous_before_admitting_target(self):
        self.controller.run('spokenly')
        self.assertEqual(['stop', 'start:spokenly'], self.manager.events)
        self.assertEqual('spokenly', self.store.selection())
        self.assertIsNone(self.store.journal())

    def test_failed_target_restores_previous_selection(self):
        self.manager.fail_start.add('spokenly')
        with self.assertRaises(switch.SwitchError):
            self.controller.run('spokenly')
        self.assertEqual({'voxtype'}, self.manager.running)
        self.assertEqual('voxtype', self.store.selection())
        self.assertIsNone(self.store.journal())

    def test_failed_rollback_leaves_no_permission_and_keeps_recovery(self):
        self.manager.fail_start.update(('spokenly', 'voxtype'))
        with self.assertRaises(switch.SwitchError):
            self.controller.run('spokenly')
        self.assertIsNone(self.store.selection())
        self.assertEqual('degraded', self.store.journal()['phase'])
        self.assertEqual(set(), self.manager.running)

    def test_dead_supervisor_cannot_admit_a_target(self):
        self.manager.interrupt = 'spokenly'
        with self.assertRaises(KeyboardInterrupt):
            self.controller.run('spokenly')
        self.manager.live_owner = False
        self.assertFalse(switch.admitted(self.store, self.manager, 'spokenly'))

    def test_cleanup_after_interruption_stops_both_and_retains_previous(self):
        self.manager.interrupt = 'spokenly'
        with self.assertRaises(KeyboardInterrupt):
            self.controller.run('spokenly')
        self.manager.running.add('spokenly')
        self.controller.cleanup()
        self.assertEqual(set(), self.manager.running)
        self.assertIsNone(self.store.selection())
        self.assertEqual('voxtype', self.store.journal()['previous'])

    def test_recovery_restores_previous_app_after_interruption(self):
        self.manager.interrupt = 'spokenly'
        with self.assertRaises(KeyboardInterrupt):
            self.controller.run('spokenly')
        self.controller.cleanup()
        self.manager.interrupt = None
        self.controller.run('recover')
        self.assertEqual('voxtype', self.store.selection())
        self.assertEqual({'voxtype'}, self.manager.running)

    def test_other_invocation_cleanup_cannot_stop_current_transaction(self):
        self.manager.interrupt = 'spokenly'
        with self.assertRaises(KeyboardInterrupt):
            self.controller.run('spokenly')
        other = switch.Controller(self.store, self.manager, 'other', 'b' * 32)
        events = list(self.manager.events)
        other.cleanup()
        self.assertEqual(events, self.manager.events)

    def test_unmanaged_app_prevents_switch_without_killing_it(self):
        self.manager.unmanaged.add('spokenly:123')
        with self.assertRaises(switch.SwitchError):
            self.controller.run('spokenly')
        self.assertEqual([], self.manager.events)
        self.assertEqual({'spokenly:123'}, self.manager.unmanaged)

    def test_both_markers_are_invalid_and_admit_neither_app(self):
        (self.store.root / 'spokenly-allowed').touch(mode=0o600)
        with self.assertRaises(switch.SwitchError):
            self.controller.run('spokenly')
        self.assertFalse(switch.admitted(self.store, self.manager, 'spokenly'))
        self.assertFalse(switch.admitted(self.store, self.manager, 'voxtype'))

    def test_stale_transaction_requires_explicit_recovery(self):
        self.manager.interrupt = 'spokenly'
        with self.assertRaises(KeyboardInterrupt):
            self.controller.run('spokenly')
        with self.assertRaises(switch.SwitchError):
            self.controller.run('voxtype')

    def test_foreign_permissions_are_rejected(self):
        self.store.root.chmod(0o755)
        with self.assertRaises(switch.SwitchError):
            self.store.check()

    def test_corrupt_journal_denies_admission(self):
        (self.store.root / 'transaction.json').write_text('{broken')
        self.assertFalse(switch.admitted(self.store, self.manager, 'voxtype'))

    def test_corrupt_journal_cleanup_stops_apps_and_preserves_the_record(self):
        journal = self.store.root / 'transaction.json'
        journal.write_text('{broken')
        with self.assertRaises(switch.SwitchError):
            self.controller.cleanup()
        self.assertEqual(set(), self.manager.running)
        self.assertIsNone(self.store.selection())
        self.assertEqual('{broken', journal.read_text())

    def test_selected_app_cannot_start_alongside_unmanaged_process(self):
        self.manager.running.clear()
        self.manager.unmanaged.add('spokenly:123')
        self.assertFalse(switch.admitted(self.store, self.manager, 'voxtype'))

    def test_status_reader_is_not_a_dictation_daemon(self):
        self.assertIsNone(switch.dictation_app(
            'voxtype', ['voxtype', 'status', '--follow', '--format', 'json']
        ))
        self.assertEqual('voxtype', switch.dictation_app(
            'voxtype', ['/usr/bin/voxtype', '-q', 'daemon']
        ))


if __name__ == '__main__':
    unittest.main()
