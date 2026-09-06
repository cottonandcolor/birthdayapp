# Birthday (birthdaycel)

iOS app for birthdays: reminders, voice entry, countdown, cards, party planning, optional iCloud, and a Home Screen widget.

## AdMob `app-ads.txt`

Publisher line (already hosted at the developer site root):

```text
google.com, pub-2410550817953613, DIRECT, f08c47fec0942fa0
```

Live file AdMob must fetch:

- https://cottonandcolor.github.io/app-ads.txt

Also mirrored in this repo at `docs/app-ads.txt`.

**Important:** Do **not** use `https://github.com/...` as the Marketing URL for AdMob. Google looks for `/app-ads.txt` on the **root domain**, and you cannot place that file on `github.com`.

## App Store Connect (copy/paste)

| Field | Value |
|--------|--------|
| **Marketing URL** | `https://cottonandcolor.github.io` |
| **Support URL** | `https://github.com/cottonandcolor/birthdayapp/issues` |
| **Privacy Policy URL** | `https://cottonandcolor.github.io/birthdayapp/privacy.html` |
| **Copyright** | `2026 Preeti Dave` |

Birthday marketing pages (GitHub Pages from `/docs`):

- https://cottonandcolor.github.io/birthdayapp/
- https://cottonandcolor.github.io/birthdayapp/support.html
- https://cottonandcolor.github.io/birthdayapp/privacy.html

Marketing URL stays on `https://cottonandcolor.github.io` so AdMob finds `app-ads.txt` at the domain root.

Changing Marketing / Support URL on a **Ready for Distribution** version requires a **new App Store version + new build**.

## Requirements

- Xcode 17+ / iOS 26.3+ deployment (adjust in project settings if you support older OS versions).

## License

All rights reserved unless you add a license file.
