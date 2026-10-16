import os
import sys
import shutil
from pathlib import Path
from typing import Optional, List


def get_browser_path() -> str:
    """
    Finds and returns the path to a Chrome, Chromium, or Microsoft Edge browser executable.

    Logic:
    1. Check default executables in system PATH (shutil.which).
    2. Check standard OS-specific install paths.
    3. If not detected in default locations, check custom environment variables (CHROME_PATH, BROWSER_PATH).
    4. Raise FileNotFoundError if no suitable browser binary is found.
    """
    # Candidate binary names for shutil.which
    candidate_binaries = [
        "google-chrome",
        "google-chrome-stable",
        "chrome",
        "chromium",
        "chromium-browser",
        "msedge",
        "microsoft-edge",
    ]

    for binary in candidate_binaries:
        found = shutil.which(binary)
        if found:
            return found

    # Standard OS-specific install paths
    candidate_paths: List[Path] = []

    if sys.platform == "win32":
        pf = os.getenv("ProgramFiles", r"C:\Program Files")
        pfx86 = os.getenv("ProgramFiles(x86)", r"C:\Program Files (x86)")
        local_app_data = os.getenv("LOCALAPPDATA", "")

        candidate_paths.extend([
            Path(pf) / "Google" / "Chrome" / "Application" / "chrome.exe",
            Path(pfx86) / "Google" / "Chrome" / "Application" / "chrome.exe",
            Path(pfx86) / "Microsoft" / "Edge" / "Application" / "msedge.exe",
            Path(pf) / "Microsoft" / "Edge" / "Application" / "msedge.exe",
        ])
        if local_app_data:
            candidate_paths.extend([
                Path(local_app_data) / "Google" / "Chrome" / "Application" / "chrome.exe",
                Path(local_app_data) / "Microsoft" / "Edge" / "Application" / "msedge.exe",
            ])
    elif sys.platform == "darwin":
        candidate_paths.extend([
            Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"),
            Path("/Applications/Chromium.app/Contents/MacOS/Chromium"),
            Path("/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"),
        ])
    else:  # Linux and other Unix-like OS
        candidate_paths.extend([
            Path("/usr/bin/google-chrome"),
            Path("/usr/bin/google-chrome-stable"),
            Path("/usr/bin/chromium"),
            Path("/usr/bin/chromium-browser"),
            Path("/usr/bin/microsoft-edge"),
            Path("/snap/bin/chromium"),
        ])

    for p in candidate_paths:
        if p.exists() and p.is_file():
            return str(p)

    # Check custom path variable provided by user
    env_path = os.getenv("CHROME_PATH") or os.getenv("BROWSER_PATH")
    if env_path:
        env_path_obj = Path(env_path)
        if env_path_obj.exists() and env_path_obj.is_file():
            return str(env_path_obj)
        else:
            raise FileNotFoundError(
                f"Browser binary specified in environment variable was not found: '{env_path}'"
            )

    raise FileNotFoundError(
        "Could not find Google Chrome, Chromium, or Microsoft Edge browser binary in default system locations. "
        "Please install one of these browsers or set the 'CHROME_PATH' or 'BROWSER_PATH' environment variable "
        "to the executable path."
    )
