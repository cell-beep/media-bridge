# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from media_bridge import app


class JobPersistenceTests(unittest.TestCase):
    def setUp(self):
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.original_jobs_dir = app.JOBS_DIR
        app.JOBS_DIR = Path(self.temporary_directory.name)
        with app.JOBS_LOCK:
            app.JOBS.clear()

    def tearDown(self):
        with app.JOBS_LOCK:
            app.JOBS.clear()
        app.JOBS_DIR = self.original_jobs_dir
        self.temporary_directory.cleanup()

    def test_job_survives_an_empty_process_memory(self):
        job = {
            "id": "persisted-job",
            "status": "downloading",
            "progress": 42.0,
            "message": "Downloading media…",
            "error": None,
            "output_dir": "downloads",
        }
        app._write_job_file(job)
        with app.JOBS_LOCK:
            app.JOBS.clear()

        restored = app.get_job("persisted-job")

        self.assertEqual(restored["status"], "downloading")
        self.assertEqual(restored["progress"], 42.0)

    def test_job_updates_are_written_atomically(self):
        job = {
            "id": "updated-job",
            "status": "queued",
            "progress": 0.0,
            "message": "Waiting to start…",
            "error": None,
            "output_dir": "downloads",
        }
        with app.JOBS_LOCK:
            app.JOBS[job["id"]] = job
        app._write_job_file(job)

        app._update_job(job["id"], status="finished", progress=100.0)
        with app.JOBS_LOCK:
            app.JOBS.clear()

        restored = app.get_job(job["id"])
        self.assertEqual(restored["status"], "finished")
        self.assertEqual(restored["progress"], 100.0)


if __name__ == "__main__":
    unittest.main()
