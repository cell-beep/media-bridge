# Privacy Policy — Media Bridge

Effective date: August 14, 2026

Media Bridge helps a user save video or audio that the user owns or has permission to download. Media processing takes place on the user's Windows computer through the Media Bridge Helper.

## Information processed

When the user opens Media Bridge, the extension can read the URL of the active browser tab and place it in the Media URL field. The user can replace or remove that URL before starting a download.

The extension and local Helper process:

- the submitted media URL;
- media metadata returned by the requested website, such as title, duration, and thumbnail;
- the user's selected format and quality;
- local download progress and error information;
- extension preferences, including format choices and dismissed interface cards.

The extension sends these data through Native Messaging to the locally installed Media Bridge Helper for the user-requested operation. Mozilla classifies this local transfer as data transmission outside the extension. Media Bridge version 0.2.2 does not send this information to servers operated by the Media Bridge publisher. It does not access browser cookies, account passwords, payment information, or the user's general browsing history.

## Network communication

The local Helper connects directly to the website and content-delivery services associated with the URL submitted by the user. Those third-party services receive ordinary network information, including the user's IP address, and process requests under their own privacy policies.

The current release does not include publisher analytics, behavioral advertising, or remote sponsor content. If these practices change, this policy and the browser-store disclosures will be updated before the feature is released.

## Local storage and retention

Media Bridge stores format preferences and interface state in local browser-extension storage. The Helper stores temporary download-job state under the current Windows user's local application-data folder. Downloaded files are saved to `Downloads\MediaBridge` by default.

The publisher does not receive or retain these locally stored records. Users can remove them by uninstalling the extension and Helper and deleting the Media Bridge folders from Windows local application data and Downloads.

## Sharing and sale of information

The Media Bridge publisher does not sell personal information and does not share locally processed URLs, media metadata, or downloaded files with advertisers or data brokers. The requested media website receives direct requests as described above.

## User controls

Users can:

- edit or clear the URL before starting a download;
- close the extension without submitting the URL;
- remove local downloaded files;
- remove the Media Bridge extension from the browser;
- uninstall Media Bridge Helper through Windows Installed apps;
- delete remaining local Media Bridge application data.

## Security

The extension uses the browser's Native Messaging mechanism to communicate with the installed Helper. The Helper accepts only external HTTP or HTTPS media URLs and rejects local and private-network targets. No downloaded media is routed through a Media Bridge cloud service.

## Changes to this policy

This policy will be updated when Media Bridge's data practices materially change. The effective date at the top of the policy identifies the current version.

## Contact

Privacy and support requests can be submitted through the dedicated Soft Harbor Studio support address published on the Media Bridge listing and product support page.

Soft Harbor Studio is the public project and publisher display name used by the individual maintainer. It is not a claim that a corporation or other registered legal entity exists.
