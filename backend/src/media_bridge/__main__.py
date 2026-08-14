# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from __future__ import annotations

import os

import uvicorn


def main() -> None:
    uvicorn.run(
        "media_bridge.app:app",
        host="127.0.0.1",
        port=int(os.environ.get("MEDIA_BRIDGE_PORT", "8765")),
        reload=False,
    )


if __name__ == "__main__":
    main()
