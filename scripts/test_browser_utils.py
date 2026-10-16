import unittest
from unittest.mock import patch
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from browser_utils import get_browser_path


class TestBrowserUtils(unittest.TestCase):

    @patch("shutil.which")
    def test_finds_browser_in_path(self, mock_which):
        def side_effect(cmd):
            if cmd == "google-chrome":
                return "/usr/bin/google-chrome"
            return None

        mock_which.side_effect = side_effect

        browser_path = get_browser_path()
        self.assertEqual(browser_path, "/usr/bin/google-chrome")

    @patch("shutil.which")
    @patch("pathlib.Path.exists", autospec=True)
    @patch("pathlib.Path.is_file", autospec=True)
    def test_finds_browser_in_default_os_locations(self, mock_is_file, mock_exists, mock_which):
        mock_which.return_value = None

        def exists_side_effect(path_obj):
            if str(path_obj) in ("/usr/bin/chromium", r"C:\Program Files\Google\Chrome\Application\chrome.exe"):
                return True
            return False

        mock_exists.side_effect = exists_side_effect
        mock_is_file.side_effect = exists_side_effect

        browser_path = get_browser_path()
        self.assertTrue(browser_path.endswith("chromium") or browser_path.endswith("chrome.exe"))

    @patch("shutil.which")
    @patch("pathlib.Path.exists", autospec=True)
    @patch("pathlib.Path.is_file", autospec=True)
    def test_custom_env_variable_fallback(self, mock_is_file, mock_exists, mock_which):
        mock_which.return_value = None

        def exists_side_effect(path_obj):
            if str(path_obj) == "/custom/path/to/chrome":
                return True
            return False

        mock_exists.side_effect = exists_side_effect
        mock_is_file.side_effect = exists_side_effect

        with patch.dict(os.environ, {"CHROME_PATH": "/custom/path/to/chrome"}):
            browser_path = get_browser_path()
            self.assertEqual(browser_path, "/custom/path/to/chrome")

    @patch("shutil.which")
    @patch("pathlib.Path.exists", autospec=True)
    @patch("pathlib.Path.is_file", autospec=True)
    def test_invalid_custom_env_variable_raises_error(self, mock_is_file, mock_exists, mock_which):
        mock_which.return_value = None
        mock_exists.return_value = False
        mock_is_file.return_value = False

        with patch.dict(os.environ, {"CHROME_PATH": "/nonexistent/path/to/chrome"}):
            with self.assertRaises(FileNotFoundError) as ctx:
                get_browser_path()
            self.assertIn("Browser binary specified in environment variable was not found", str(ctx.exception))

    @patch("shutil.which")
    @patch("pathlib.Path.exists", autospec=True)
    @patch("pathlib.Path.is_file", autospec=True)
    def test_no_browser_found_raises_error(self, mock_is_file, mock_exists, mock_which):
        mock_which.return_value = None
        mock_exists.return_value = False
        mock_is_file.return_value = False

        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(FileNotFoundError) as ctx:
                get_browser_path()
            self.assertIn("Could not find Google Chrome, Chromium, or Microsoft Edge browser binary", str(ctx.exception))


if __name__ == "__main__":
    unittest.main()
