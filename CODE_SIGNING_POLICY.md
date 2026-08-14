# Code-Signing Policy

Free code signing for this open-source project is planned to be provided by
[SignPath.io](https://signpath.io/) with a certificate provided by the
[SignPath Foundation](https://signpath.org/).

## Covered artifacts

Signing is limited to release artifacts produced from the public Media Bridge
source repository by the documented build process. Private, unreviewed, or
locally modified binaries are not eligible.

## Roles

- Committers: [`cell-beep`](https://github.com/cell-beep) and future maintainers
  with write access to the public repository.
- Reviewers: `cell-beep` and future maintainers who review source revisions and
  build provenance.
- Approvers: `cell-beep`, acting for Soft Harbor Studio with two-factor
  authentication enabled.

Where the signing service supports separation of duties, an artifact should be
reviewed separately from the local build that produced it.

## Release requirements

Before approval, a release must:

1. originate from a tagged public commit;
2. pass the automated test and extension-lint workflow;
3. include dependency licenses and notices;
4. identify the exact bundled dependency versions and checksums;
5. provide the corresponding source required by bundled GPL components;
6. be scanned for accidental credentials and unexpected binaries;
7. publish checksums alongside the signed installer.

Signing credentials and private keys must never be stored in this repository.
