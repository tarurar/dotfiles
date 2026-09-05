import importlib.machinery
import importlib.util
from pathlib import Path
import tempfile
import unittest


source = Path(__file__).resolve().parents[1] / 'deploy'
loader = importlib.machinery.SourceFileLoader('trial_deploy', str(source))
spec = importlib.util.spec_from_loader(loader.name, loader)
deploy = importlib.util.module_from_spec(spec)
loader.exec_module(deploy)
BLOCK = '\n-- BEGIN spokenly-trial focus rule\ntrial\n-- END spokenly-trial focus rule\n'


class ConfigIncludeTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name) / 'hyprland.lua'
        self.path.write_text('original\n')

    def test_repeated_install_adds_only_one_include(self):
        deploy.config_block(self.path, BLOCK, True)
        deploy.config_block(self.path, BLOCK, True)
        self.assertEqual(self.path.read_text(), 'original\n' + BLOCK)

    def test_removal_preserves_later_user_edits(self):
        deploy.config_block(self.path, BLOCK, True)
        self.path.write_text(self.path.read_text() + 'later user edit\n')
        deploy.config_block(self.path, BLOCK, False)
        self.assertEqual(self.path.read_text(), 'original\nlater user edit\n')

    def test_modified_include_is_rejected_without_writing(self):
        altered = 'original\n' + BLOCK.replace('\ntrial\n', '\nchanged\n')
        self.path.write_text(altered)
        with self.assertRaises(RuntimeError):
            deploy.config_block(self.path, BLOCK, False)
        self.assertEqual(self.path.read_text(), altered)

    def test_symlink_config_is_rejected_without_writing(self):
        link = self.path.with_name('link')
        link.symlink_to(self.path)
        with self.assertRaises(RuntimeError):
            deploy.config_block(link, BLOCK, True)
        self.assertEqual(self.path.read_text(), 'original\n')
