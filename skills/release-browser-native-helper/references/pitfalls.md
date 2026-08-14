# Common pitfalls and recoveries

## “The extension works unpacked but not from the store”

The production extension ID differs from the development ID, so the native host rejects it. Reserve the store ID first, generate the correct allowlist, and test a signed/store-equivalent package.

## Firefox says the job was not found

The popup or worker kept job state only in memory. Persist job identifiers and status in the Helper or browser storage and allow reconnection after worker suspension.

## A downloader returns HTTP 403 for one video

Do not immediately add cookie theft, browser impersonation, or restriction bypass. Update the downloader, retry with another rights-cleared URL, record that failures are media/site dependent, and preserve the error for diagnosis.

## Windows warns even though the installer is signed

The installer may contain an unsigned Helper. Sign the nested Helper first, build the installer, then sign the outer installer. Verify both files and timestamps from the final artifact.

## The release page accidentally serves an unsigned EXE

Separate preview-site generation from release publishing. Preview builds may show “signed Helper is being prepared” but must never copy local build output into public download directories.

## FFmpeg licensing becomes confusing

Record the exact binary variant and its configured features. Distinguish invoking a separate executable from linking a library. Bundle notices and publish corresponding source as required. If the project accepts open-source disclosure, prefer clarity and reproducibility over a narrower but poorly documented binary.

## Store review cannot reproduce the feature

The listing omitted the Helper or used a blocked/copyright-sensitive test URL. Provide the signed Helper link, exact steps, expected result, rights-cleared media, supported OS, and source/build links in reviewer-only notes.

## A release script works only from one directory

Resolve the repository root from the script's own location and pass it explicitly to Git. Avoid assuming the terminal starts inside a Git worktree. Treat Git whitespace diagnostics as actionable rather than generic command failure.

## GitHub authentication uses the wrong account

Verify the remote owner before pushing and inspect the resulting repository page after authentication. Keep publisher identity, support email, repository owner, and store account conceptually separate when needed.

## A signing service application stalls

Open-source signing programs may require a public project, OSI license, MFA, an already public release, reproducible CI, and ongoing maintenance. Prepare these before applying and keep a self-signed development path separate from public Authenticode releases.
