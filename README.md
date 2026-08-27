# Athan 2.1.1 — myathan.link

Prayer times and Adhan player. Live site: [myathan.link](https://myathan.link) (Cloudflare Pages from this `main` branch).

## This page (web)

Leave [myathan.link](https://myathan.link) open and Athan plays Adhan at **Fajr, Dhuhr, Asr, Maghrib, and Isha**. Sunrise and night thirds are optional alarms. Next-Adhan logic matches the Android and Mac apps.

On iPhone: Safari → Share → **Add to Home Screen**. Adhan plays only while the page is open. A Home Screen bookmark cannot run in the background on iOS.

## Downloads

Binaries are GitHub Release assets (not stored in this Pages tree):

- [Android APK 2.1.1](https://github.com/k9t2htrkyd-netizen/myathan/releases/download/v2.1.1/Athan-2.1.1-android.apk)
- [Mac menu bar (Athan v2)](https://github.com/k9t2htrkyd-netizen/myathan/releases/download/v2.1.1/Athan-2.1.1-menubar-macOS.zip)

There is no unsigned iOS `.app` download.

## Repo layout

| Path | What |
|---|---|
| `index.html`, `app.js`, `styles.css` | Website |
| `macos/` | Mac menu bar v1 sources |
| `version2/` | Mac menu bar v2 sources (Nest / Bluetooth) |

After changing the site, hard-refresh myathan.link (`Cmd-Shift-R`) so `app.js?v=2.1.1-downloads` loads.
