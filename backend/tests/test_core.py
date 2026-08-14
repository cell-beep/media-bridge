# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from __future__ import annotations

import unittest
from pathlib import Path

from media_bridge.core import (
    UnsafeUrlError,
    build_ydl_options,
    percentage_from_hook,
    validate_media_url,
)


def public_resolver(*_args):
    return [(2, 1, 6, "", ("93.184.216.34", 443))]


def private_resolver(*_args):
    return [(2, 1, 6, "", ("127.0.0.1", 80))]


class UrlValidationTests(unittest.TestCase):
    def test_accepts_public_https_url(self):
        self.assertEqual(
            validate_media_url(" https://example.com/watch?v=1 ", resolver=public_resolver),
            "https://example.com/watch?v=1",
        )

    def test_rejects_non_http_scheme(self):
        with self.assertRaises(UnsafeUrlError):
            validate_media_url("file:///etc/passwd", resolver=public_resolver)

    def test_rejects_credentials(self):
        with self.assertRaises(UnsafeUrlError):
            validate_media_url("https://user:pass@example.com/video", resolver=public_resolver)

    def test_rejects_private_address(self):
        with self.assertRaises(UnsafeUrlError):
            validate_media_url("http://example.test/video", resolver=private_resolver)

    def test_rejects_localhost_without_dns(self):
        with self.assertRaises(UnsafeUrlError):
            validate_media_url("http://localhost/video", resolver=public_resolver)


class DownloadOptionsTests(unittest.TestCase):
    def test_video_options_limit_height_and_disable_playlists(self):
        options = build_ydl_options(
            mode="video",
            max_height=1080,
            audio_format="mp3",
            output_dir=Path("downloads"),
            progress_hook=lambda _event: None,
        )
        self.assertIn("height<=1080", options["format"])
        self.assertTrue(options["noplaylist"])
        self.assertEqual(options["merge_output_format"], "mp4")

    def test_video_without_ffmpeg_uses_single_stream(self):
        options = build_ydl_options(
            mode="video",
            max_height=720,
            audio_format="mp3",
            output_dir=Path("downloads"),
            progress_hook=lambda _event: None,
            ffmpeg_available=False,
        )
        self.assertEqual(options["format"], "best[height<=720]/best")
        self.assertNotIn("merge_output_format", options)

    def test_audio_options_include_conversion(self):
        options = build_ydl_options(
            mode="audio",
            max_height=1080,
            audio_format="opus",
            output_dir=Path("downloads"),
            progress_hook=lambda _event: None,
        )
        self.assertEqual(options["format"], "bestaudio/best")
        self.assertEqual(options["postprocessors"][0]["preferredcodec"], "opus")

    def test_explicit_ffmpeg_location_is_forwarded(self):
        options = build_ydl_options(
            mode="video",
            max_height=1080,
            audio_format="mp3",
            output_dir=Path("downloads"),
            progress_hook=lambda _event: None,
            ffmpeg_location="tools/ffmpeg/bin",
        )
        self.assertEqual(options["ffmpeg_location"], "tools/ffmpeg/bin")

    def test_explicit_deno_location_is_forwarded(self):
        options = build_ydl_options(
            mode="video",
            max_height=1080,
            audio_format="mp3",
            output_dir=Path("downloads"),
            progress_hook=lambda _event: None,
            js_runtime_path="runtime/deno.exe",
        )
        self.assertEqual(
            options["js_runtimes"],
            {"deno": {"path": "runtime/deno.exe"}},
        )

    def test_progress_is_bounded(self):
        self.assertEqual(percentage_from_hook({"downloaded_bytes": 50, "total_bytes": 200}), 25.0)
        self.assertEqual(percentage_from_hook({"downloaded_bytes": 250, "total_bytes": 200}), 100.0)
        self.assertIsNone(percentage_from_hook({"downloaded_bytes": 10}))


if __name__ == "__main__":
    unittest.main()
