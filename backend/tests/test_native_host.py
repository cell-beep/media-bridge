# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from __future__ import annotations

import io
import unittest

from media_bridge.native_host import handle_message, read_message, write_message


class NativeProtocolTests(unittest.TestCase):
    def test_round_trip_preserves_unicode(self):
        stream = io.BytesIO()
        original = {"requestId": "1", "title": "Видео"}
        write_message(stream, original)
        stream.seek(0)
        self.assertEqual(read_message(stream), original)

    def test_health_action_returns_helper_status(self):
        response = handle_message({"requestId": "abc", "action": "health", "payload": {}})
        self.assertTrue(response["ok"])
        self.assertEqual(response["requestId"], "abc")
        self.assertEqual(response["data"]["status"], "ok")

    def test_unknown_action_is_rejected(self):
        with self.assertRaises(ValueError):
            handle_message({"requestId": "1", "action": "unknown", "payload": {}})


if __name__ == "__main__":
    unittest.main()
