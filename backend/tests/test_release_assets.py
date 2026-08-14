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
FFMPEG_BUILD = PROJECT_ROOT / "packaging" / "ffmpeg" / "build.json"


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

    def test_installer_supports_a_firefox_only_release(self):
        build_script = (PROJECT_ROOT / "scripts" / "build-installer.ps1").read_text(
            encoding="utf-8"
        )
        nsis_script = (PROJECT_ROOT / "installer" / "MediaBridgeHelper.nsi").read_text(
            encoding="utf-8"
        )
        self.assertIn("[switch]$FirefoxOnly", build_script)
        self.assertIn("/DMB_FIREFOX_ONLY=1", build_script)
        self.assertIn("!ifndef MB_FIREFOX_ONLY", nsis_script)
        self.assertIn("/DAPP_VERSION=$version", build_script)

    def test_github_pages_preview_is_safe_before_helper_signing(self):
        workflow = (PROJECT_ROOT / ".github" / "workflows" / "pages.yml").read_text(
            encoding="utf-8"
        )
        builder = (PROJECT_ROOT / "scripts" / "build-pages-preview.ps1").read_text(
            encoding="utf-8"
        )
        self.assertIn("actions/deploy-pages@v4", workflow)
        self.assertIn("build-pages-preview.ps1", workflow)
        self.assertIn("The signed public Helper is being prepared", builder)
        self.assertNotIn("Copy-Item -LiteralPath $InstallerPath", builder)
        self.assertIn("https://github.com/cell-beep/media-bridge/releases", builder)

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

    def test_ffmpeg_build_is_pinned_and_verified(self):
        metadata = json.loads(FFMPEG_BUILD.read_text(encoding="utf-8"))
        setup_script = (PROJECT_ROOT / "scripts" / "setup-ffmpeg.ps1").read_text(
            encoding="utf-8"
        )
        self.assertEqual(metadata["provider"], "BtbN/FFmpeg-Builds")
        self.assertIn("win64-gpl-8.1.zip", metadata["assetName"])
        self.assertEqual(len(metadata["providerCommit"]), 40)
        self.assertEqual(len(metadata["assetSha256"]), 64)
        int(metadata["assetSha256"], 16)
        self.assertIn("Get-FileHash", setup_script)
        self.assertIn("--enable-gpl", setup_script)

    def test_release_automation_preserves_nested_signatures_and_sources(self):
        signing = (PROJECT_ROOT / ".github" / "workflows" / "signpath.yml").read_text(
            encoding="utf-8"
        )
        sources = (PROJECT_ROOT / ".github" / "workflows" / "ffmpeg-source.yml").read_text(
            encoding="utf-8"
        )
        self.assertEqual(signing.count("signpath/github-action-submit-signing-request@v2"), 2)
        self.assertIn("SIGNPATH_HELPER_ARTIFACT_CONFIGURATION_SLUG", signing)
        self.assertIn("SIGNPATH_INSTALLER_ARTIFACT_CONFIGURATION_SLUG", signing)
        self.assertIn("verify-signed-release.ps1", signing)
        self.assertIn("dist/installer/MediaBridgeHelper-Setup-*.exe", signing)
        self.assertIn("./download.sh", sources)
        self.assertIn("corresponding-source.tar.zst", sources)

        readiness = (PROJECT_ROOT / "scripts" / "test-release-readiness.ps1").read_text(
            encoding="utf-8"
        )
        self.assertIn("[ValidateSet('Firefox', 'Edge')][string]$Browser = 'Firefox'", readiness)
        self.assertIn("$helperSignature.TimeStamperCertificate", readiness)

    def test_firefox_listing_contains_public_release_links_without_placeholders(self):
        listing = (PROJECT_ROOT / "docs" / "STORE_LISTING_FIREFOX.md").read_text(
            encoding="utf-8"
        )
        self.assertNotIn("[REQUIRED:", listing)
        self.assertIn("https://cell-beep.github.io/media-bridge/", listing)
        self.assertIn("https://github.com/cell-beep/media-bridge", listing)

    def test_reusable_release_skill_is_complete(self):
        skill_root = PROJECT_ROOT / "skills" / "release-browser-native-helper"
        skill = (skill_root / "SKILL.md").read_text(encoding="utf-8")
        self.assertTrue(skill.startswith("---\nname: release-browser-native-helper\n"))
        self.assertNotIn("TODO", skill)
        self.assertIn("Native Messaging", skill)
        self.assertIn("Submit the Helper executable for Authenticode signing", skill)
        for filename in ("release-gates.md", "pitfalls.md", "store-review.md"):
            self.assertTrue((skill_root / "references" / filename).is_file())


if __name__ == "__main__":
    unittest.main()
