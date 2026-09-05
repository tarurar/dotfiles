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


class ResumeInventoryTests(unittest.TestCase):
    def test_fresh_manifest_records_resume_files_and_removal(self):
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            unit_dir = root / 'units'
            resume_link = unit_dir / 'graphical-session.target.wants/spokenly-resume.service'
            files = tuple((src, root / 'files' / Path(src).name, mode)
                          for src, _, mode in deploy.FILES)
            state = deploy.module().State(root / 'state')
            state.initialize()
            with patch.multiple(deploy, FILES=files, UNIT_DIR=unit_dir,
                                ENABLE_LINK=root / 'spokenly-link',
                                RESUME_LINK=resume_link):
                manifest = deploy.create_manifest(state)
            self.assertEqual(
                {'spokenly-resume', 'spokenly-resume.service'},
                {Path(item['source']).name for item in manifest['files']
                 if Path(item['source']).name.startswith('spokenly-resume')})
            self.assertEqual('systemctl --user disable --now spokenly-resume.service',
                             manifest['auxiliary_units'][0]['inverse'])

    def test_existing_resume_enable_link_is_not_adopted(self):
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            link = root / 'resume-link'
            link.symlink_to(root / 'missing-target')
            with patch.multiple(deploy, RESUME_LINK=link,
                                ENABLE_LINK=root / 'spokenly-link'):
                with self.assertRaisesRegex(RuntimeError, 'preexisting enable link'):
                    deploy.create_manifest(None)
