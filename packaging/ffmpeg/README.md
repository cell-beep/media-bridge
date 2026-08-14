# FFmpeg release input

Media Bridge invokes `ffmpeg.exe` and `ffprobe.exe` as separate programs for
stream merging and audio conversion. They are not linked into the Media Bridge
Helper.

The exact binary input is pinned in `build.json`. `scripts/setup-ffmpeg.ps1`
refuses an archive whose SHA-256 digest differs from that file and records the
verified metadata next to the extracted programs.

The selected BtbN GPL build includes GPL-only codecs such as x264/x265. Each
public Helper release must include:

1. the GPL license and notices shipped in the verified FFmpeg archive;
2. the exact `build.json` metadata;
3. the BtbN build scripts at the pinned commit;
4. the source archives downloaded by those scripts for the distributed build;
5. a durable download link from the same release page as the Helper.

The source-cache workflow is deliberately manual because it can create a large
artifact. Run it for every new pinned FFmpeg build before publishing a Helper.
