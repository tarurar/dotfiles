import importlib.machinery
import importlib.util
from pathlib import Path
import unittest

loader = importlib.machinery.SourceFileLoader(
    'resume', str(Path(__file__).resolve().parents[1] / 'bin/spokenly-resume'))
spec = importlib.util.spec_from_loader(loader.name, loader)
resume = importlib.util.module_from_spec(spec)
loader.exec_module(resume)


class ResumeTests(unittest.TestCase):
    def setUp(self):
        self.pending = {}
        self.requests = []
        self.next_id = 0
        self.handler = resume.ResumeHandler(
            self.schedule, self.pending.pop, lambda: self.requests.append('resume'))

    def schedule(self, delay, callback):
        self.assertEqual(2000, delay)
        self.next_id += 1
        self.pending[self.next_id] = callback
        return self.next_id

    def fire(self):
        _, callback = self.pending.popitem()
        self.assertFalse(callback())

    def test_sleep_does_not_restart(self):
        self.handler.prepare_for_sleep(True)
        self.assertEqual({}, self.pending)
        self.assertEqual([], self.requests)

    def test_wake_schedules_one_restart(self):
        self.handler.prepare_for_sleep(False)
        self.assertEqual([], self.requests)
        self.fire()
        self.assertEqual(['resume'], self.requests)
        self.assertIsNone(self.handler.pending)

    def test_repeated_wake_replaces_pending_request(self):
        self.handler.prepare_for_sleep(False)
        self.handler.prepare_for_sleep(False)
        self.assertEqual(1, len(self.pending))
        self.fire()
        self.assertEqual(['resume'], self.requests)

    def test_sleep_cancels_pending_restart(self):
        self.handler.prepare_for_sleep(False)
        self.handler.prepare_for_sleep(True)
        self.assertEqual({}, self.pending)
        self.assertEqual([], self.requests)
