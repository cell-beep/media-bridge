# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from __future__ import annotations

import json
import unittest
import zipfile
from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[2]
EXTENSION_DIR = PROJECT_ROOT / "extension"
FIREFOX_MANIFEST = PROJECT_ROOT / "packaging" / "firefox" / "manifest.json"


class ExtensionReleaseTests(unittest.TestCase):
    def test_manifest_has_minimal_release_permissions(self):
        manifest = json.loads((EXTENSION_DIR / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["manifest_version"], 3)
        self.assertEqual(manifest["permissions"], ["activeTab", "nativeMessaging", "storage"])
        self.assertNotIn("host_permissions", manifest)
        self.assertLessEqual(len(manifest["description"]), 132)
        self.assertIn("own or are permitted", manifest["description"])
        self.assertEqual(
            manifest["content_security_policy"]["extension_pages"],
            "script-src 'self'; object-src 'self'",
        )

    def test_manifest_and_helper_versions_match(self):
        manifest = json.loads((EXTENSION_DIR / "manifest.json").read_text(encoding="utf-8"))
        firefox_manifest = json.loads(FIREFOX_MANIFEST.read_text(encoding="utf-8"))
        pyproject = (PROJECT_ROOT / "backend" / "pyproject.toml").read_text(encoding="utf-8")
        self.assertIn(f'version = "{manifest["version"]}"', pyproject)
        self.assertEqual(firefox_manifest["version"], manifest["version"])

    def test_firefox_manifest_uses_background_script_and_stable_id(self):
        manifest = json.loads(FIREFOX_MANIFEST.read_text(encoding="utf-8"))
        self.assertEqual(manifest["manifest_version"], 3)
        self.assertEqual(manifest["permissions"], ["activeTab", "nativeMessaging", "storage"])
        self.assertEqual(manifest["background"], {"scripts": ["service-worker.js"]})
        self.assertEqual(
            manifest["browser_specific_settings"]["gecko"]["id"],
            "{d6c3a4cc-8b7b-4f97-a669-7f41c39a6ac8}",
        )
        self.assertEqual(
            manifest["browser_specific_settings"]["gecko"]["data_collection_permissions"],
            {
                "required": [
                    "browsingActivity",
                    "websiteContent",
                    "websiteActivity",
                ]
            },
        )
        self.assertEqual(
            manifest["browser_specific_settings"]["gecko"]["strict_min_version"],
            "142.0",
        )
        self.assertNotIn("gecko_android", manifest["browser_specific_settings"])

    def test_native_host_manifests_use_browser_specific_allowlists(self):
        chromium = json.loads(
            (PROJECT_ROOT / "installer" / "native-host" / "chromium-host.template.json").read_text(
                encoding="utf-8"
            )
        )
        firefox = json.loads(
            (PROJECT_ROOT / "installer" / "native-host" / "firefox-host.template.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertIn("allowed_origins", chromium)
        self.assertNotIn("allowed_extensions", chromium)
        self.assertIn("allowed_extensions", firefox)
        self.assertNotIn("allowed_origins", firefox)

    def test_extension_icons_have_declared_dimensions(self):
        for size in (16, 32, 48, 128):
            with Image.open(EXTENSION_DIR / "assets" / f"icon-{size}.png") as image:
                self.assertEqual(image.size, (size, size))
                self.assertEqual(image.format, "PNG")

    def test_store_artwork_has_edge_dimensions(self):
        expected = {
            "media-bridge-logo-300.png": (300, 300),
            "media-bridge-small-tile-440x280.png": (440, 280),
            "media-bridge-large-tile-1400x560.png": (1400, 560),
        }
        for filename, size in expected.items():
            with Image.open(PROJECT_ROOT / "store-assets" / filename) as image:
                self.assertEqual(image.size, size)

    def test_first_review_build_has_sponsor_disabled(self):
        config = (EXTENSION_DIR / "config.js").read_text(encoding="utf-8")
        self.assertIn("enabled: false", config)

    def test_rights_confirmation_mentions_site_permission(self):
        popup = (EXTENSION_DIR / "popup.html").read_text(encoding="utf-8")
        self.assertIn("the website permits downloading it", popup)

    def test_first_party_license_exists(self):
        full_license = (PROJECT_ROOT / "LICENSE").read_text(encoding="utf-8")
        license_text = (PROJECT_ROOT / "LICENSE.txt").read_text(encoding="utf-8")
        self.assertIn("Mozilla Public License Version 2.0", full_license)
        self.assertIn("MPL-2.0", license_text)
        self.assertIn("Soft Harbor Studio", license_text)

    def test_built_extension_archives_use_portable_entry_names(self):
        version = json.loads((EXTENSION_DIR / "manifest.json").read_text(encoding="utf-8"))["version"]
        for browser in ("Edge", "Firefox"):
            archive_path = PROJECT_ROOT / "dist" / "extension" / f"MediaBridge-{browser}-{version}.zip"
            if not archive_path.exists():
                self.skipTest(f"Build archive first: {archive_path}")
            with zipfile.ZipFile(archive_path) as archive:
                names = archive.namelist()
            self.assertIn("assets/icon-128.png", names)
            self.assertIn("LICENSE", names)
            self.assertIn("LICENSE.txt", names)
            self.assertTrue(all("\\" not in name for name in names))


if __name__ == "__main__":
    unittest.main()
