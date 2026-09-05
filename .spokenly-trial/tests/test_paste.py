import importlib.machinery
import importlib.util
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

loader = importlib.machinery.SourceFileLoader(
    'paste', str(Path(__file__).resolve().parents[1] / 'bin/spokenly-ydotool'))
spec = importlib.util.spec_from_loader(loader.name, loader)
paste = importlib.util.module_from_spec(spec)
loader.exec_module(paste)
CTRL_V = ['key', '29:1', '47:1', '47:0', '29:0']
SHIFT_CTRL_V = ['key', '29:1', '42:1', '47:1', '47:0', '42:0', '29:0']


class PasteTests(unittest.TestCase):
    def invoke(self, args, window):
        with patch.object(paste, 'focused_class', return_value=window), \
                patch.object(paste.os, 'execv') as execute:
            paste.main(args)
        return execute.call_args.args

    def test_ghostty_uses_terminal_paste(self):
        self.assertEqual(('/usr/bin/ydotool', ['/usr/bin/ydotool', *SHIFT_CTRL_V]),
                         self.invoke(CTRL_V, 'com.mitchellh.ghostty'))

    def test_editor_keeps_ctrl_v(self):
        self.assertEqual(('/usr/bin/ydotool', ['/usr/bin/ydotool', *CTRL_V]),
                         self.invoke(CTRL_V, 'code'))

    def test_unknown_focus_preserves_original_paste(self):
        self.assertEqual(('/usr/bin/ydotool', ['/usr/bin/ydotool', *CTRL_V]),
                         self.invoke(CTRL_V, None))

    def test_non_paste_command_passes_through_without_focus_query(self):
        for args in (['--help'], ['key', '28:1', '28:0'],
                     ['type', 'synthetic fixture'], CTRL_V + ['28:1']):
            with self.subTest(args=args), \
                    patch.object(paste, 'focused_class') as focus, \
                    patch.object(paste.os, 'execv') as execute:
                paste.main(args)
                focus.assert_not_called()
                execute.assert_called_once_with('/usr/bin/ydotool',
                                                ['/usr/bin/ydotool', *args])

    def test_focus_query_reads_class_without_using_title(self):
        response = subprocess.CompletedProcess([], 0,
            '{"class":"code","title":"com.mitchellh.ghostty"}')
        with patch.object(paste.subprocess, 'run', return_value=response):
            self.assertEqual('code', paste.focused_class())

    def test_focus_query_failures_return_unknown(self):
        for failure in (OSError(), subprocess.TimeoutExpired('hyprctl', .5)):
            with self.subTest(failure=failure), \
                    patch.object(paste.subprocess, 'run', side_effect=failure):
                self.assertIsNone(paste.focused_class())
        for value in ('not json', '[]', '{}', '{"class":null}'):
            with self.subTest(value=value), patch.object(paste.subprocess, 'run',
                    return_value=subprocess.CompletedProcess([], 0, value)):
                self.assertIsNone(paste.focused_class())
