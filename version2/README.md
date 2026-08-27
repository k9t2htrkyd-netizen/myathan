# Athan Bar version 2

Version 2 is a **separate** Mac menu-bar app. Version 1 is unchanged in `macos/` and can keep running as `AthanBar.app`.

| | Version 1 | Version 2 |
|---|---|---|
| Folder | `macos/` | `version2/` |
| App | `AthanBar.app` | `AthanBarV2.app` |
| Bundle ID | `com.athan.menubar` | `com.athan.menubar.v2` |
| Speakers | This Mac only | This Mac, Bluetooth (Alexa/Echo), Google Nest / Chromecast over Wi-Fi |

Both apps can be installed at the same time. Quit the one you are not using if two moon icons in the menu bar feel crowded.

## What changed in version 2

Prayer times, location search, Adhan arming, volume, and secondary alarms work the same as version 1.

New in version 2:

- **Play Adhan on** section with checkboxes for every speaker
- Play on **multiple devices at once** (several Nests, Bluetooth Echo, and/or a specific Mac speaker)
- **Google Nest / Chromecast** over Wi-Fi (same idea as [SmartAzan](https://www.smartazan.com) for Google speakers)
- Connect Nest by **Scan Wi-Fi** or **IP address**
- **Bluetooth** for Amazon Echo / Alexa without changing the Mac’s system speaker
- The app routes audio itself. It does **not** use or change the computer’s selected output. Unchecked Mac speakers stay silent.

## Build and run version 2

Leave version 1 alone. From the repo root:

```bash
cd version2
chmod +x build-and-run.sh
./build-and-run.sh
```

That builds `version2/AthanBarV2.app` and opens it. Look for **Athan v2** in the menu bar.

To build without launching:

```bash
cd version2
swift build -c release
```

macOS 13 or later is required.

---

## Connect a Google Nest (Wi-Fi / IP)

This is the SmartAzan-style path: the Mac sends Adhan to the speaker with Google Cast. The speaker plays the audio itself.

Supported devices include Google Nest Mini, Nest Audio, Nest Hub, Google Home, Chromecast with audio, and TVs with Chromecast built in.

### 1. Put both devices on the same Wi-Fi

- This Mac and the Nest must be on the **same Wi-Fi network** (not a guest network that blocks device-to-device traffic).
- Disable VPN on the Mac while testing if discovery fails.

### 2. Allow local network access

The first time you tap **Scan Wi-Fi**, macOS may ask:

> Allow Athan v2 to find devices on the local network?

Choose **Allow**. If you missed the prompt:

**System Settings → Privacy & Security → Local Network → Athan v2 → on**

If macOS asks to accept incoming connections (the app serves the Adhan file to the Nest), choose **Allow**.

### 3. Choose speakers in the bar

1. Click the moon icon → **Athan v2**.
2. Under **Play Adhan on**, leave Mac/Bluetooth boxes **unchecked** if you only want Nest.
3. Click **Scan Wi-Fi**.
4. **Check** every Nest that should play. You can check more than one.
5. Status should read `Will play on <speaker names>`.
6. Arm Adhan, then click **Play Jordan Adhan now**. Sound should come from the Nest speakers only.

### 4. Connect by IP address (if scan finds nothing)

1. Open the **Google Home** app on your phone.
2. Tap the Nest speaker → settings / device information.
3. Copy the **IP address** (example: `192.168.1.24`).
4. Paste it into **Add Nest IP** and click **Add**.
5. Make sure that Nest is **checked**.
6. Test with **Play Jordan Adhan now**.

Cast always uses port **8009** on the speaker. You do not need to type the port.

### 5. Keep it armed

Leave **Adhan armed** on. At each prayer time, version 2 casts Adhan to the connected Nest automatically.

The Mac must stay awake and on Wi-Fi. If the Mac sleeps, it cannot start playback. In **System Settings → Energy**, prevent sleep if you need Fajr or late Isha.

---

## Connect Amazon Alexa / Echo (Bluetooth)

Alexa does **not** accept Google Cast the way Nest does. SmartAzan plays on Alexa through an **Alexa Skill in the cloud**, not by sending audio to the Echo’s IP address. Version 2 does the local equivalent: the Echo becomes a Bluetooth speaker for this Mac.

### 1. Pair the Echo with this Mac

On the Echo, say:

> “Alexa, pair Bluetooth.”

On the Mac:

1. Open **System Settings → Bluetooth**.
2. Wait for the Echo (for example `Echo Dot-XXX`) to appear.
3. Click **Connect**.
4. Wait until the Echo says it is connected, or the Mac shows **Connected**.

You can also start pairing from the Alexa app: **Devices → Echo → Bluetooth devices**.

### 2. Select it in Athan v2

1. Open **Athan v2**.
2. Under **This Mac / Bluetooth**, click **Refresh Mac / Bluetooth speakers**.
3. **Check** the Echo. Leave MacBook Speakers unchecked if you do not want the computer to play.
4. You can also check Nest speakers in the Google Nest list at the same time.
5. Arm Adhan, then click **Play Jordan Adhan now**.
6. Sound should come from the Echo (and any other checked speakers only).

Version 2 plays straight to that Bluetooth device. It does **not** change the Mac’s system output in Sound settings.

### 3. Why IP does not work for Alexa

Typing an Echo IP into the Google Nest field will not play Adhan. Echo speakers have no public Cast/Chromecast receiver. That is why SmartAzan uses an Alexa Skill + Routines for Wi-Fi Alexa, and why this app uses Bluetooth instead.

If you specifically need Alexa over Wi-Fi without Bluetooth (phone-free, no Mac awake), use [SmartAzan for Alexa](https://www.smartazan.com/Alexa/Home/HowWorks) in addition to this bar. That path is cloud-based and is not part of this local app.

---

## Nest over Bluetooth (optional)

If Cast/Wi-Fi is blocked on your network, a Nest can also pair as a Bluetooth speaker:

1. In Google Home, open the speaker → **Audio → Pair Bluetooth**.
2. Pair it in **System Settings → Bluetooth** on the Mac.
3. In Athan v2, **check** that Nest under **This Mac / Bluetooth**.

Prefer the **Google Nest / Chromecast** checkboxes when you can. Cast usually sounds better and does not occupy the Mac’s Bluetooth connection.

---

## Play on multiple devices

Check every speaker that should play at the same time, for example:

- Kitchen Nest **and** living-room Nest
- Nest **and** an Echo (Bluetooth)
- Nest **and** a specific Mac/USB speaker

Only checked devices play. If MacBook Speakers is unchecked, the computer stays silent even if Sound settings point at it.

---

## Daily use

1. Launch **Athan v2** (`./build-and-run.sh` or open `AthanBarV2.app`).
2. Set your city if needed.
3. Check the Nest, Bluetooth, and/or Mac speakers you want. The selection is remembered.
4. Turn on **Adhan armed**.
5. Leave the app running. Do not let the Mac sleep through prayer times.

---

## Troubleshooting

**Scan finds no Nest**
- Same Wi-Fi as the speaker, not guest Wi-Fi.
- Allow Local Network for Athan v2.
- Turn the Nest off and on, then scan again.
- Use the IP from the Google Home app.

**Connected but no sound on Nest**
- Allow incoming connections when macOS asks (the Mac hosts the MP3 for the Nest).
- Check the Nest is not in Do Not Disturb.
- Turn the volume up in Athan v2 **and** on the Nest (“Hey Google, volume 8”).
- Click **Play Jordan Adhan now** while watching the Nest; it should show default Cast playback.

**Alexa not in the Bluetooth list**
- Say “Alexa, pair Bluetooth” again. Echo only stays discoverable for a short time.
- Disconnect the Echo from a phone if it is already paired elsewhere. Many Echos allow only one Bluetooth source.
- Click **Refresh speakers** after the Mac shows Connected.

**Adhan plays on the Mac instead of the speaker**
- Uncheck **MacBook Speakers** (and any other Mac device) under **This Mac / Bluetooth**.
- Check only the Nest/Echo you want.
- Status must say `Will play on` those speakers before you press play.
- Version 2 no longer uses the computer’s selected Sound output. If a Mac device is checked, that is why you hear the computer.

**Two moon icons in the menu bar**
- Version 1 and version 2 are both open. Quit one: **Quit Athan** vs **Quit Athan v2**.

**Firewall / security software**
- Athan v2 listens on TCP port **18765** on the Mac so the Nest can download Adhan. Allow that inbound local traffic.

---

## Files added (version 1 not modified)

```
version2/
  README.md                 ← this file
  Package.swift
  build-and-run.sh
  Sources/AthanBarV2/
    AthanBarApp.swift
    MenuPanel.swift         ← v2 speaker UI
    AdhanPlayer.swift       ← routes audio to Nest or Bluetooth
    SpeakerService.swift    ← output mode + connect/scan
    CastBrowser.swift       ← finds Nest on Wi-Fi
    CastClient.swift        ← Google Cast playback
    CastProto.swift
    CastModels.swift
    MediaServer.swift       ← local HTTP for Nest
    AudioOutputRouter.swift ← Bluetooth / system output
    PrayerService.swift     ← same behavior as v1
    Models.swift            ← same as v1
    Resources/              ← same Adhan and alarm audio as v1
```

Version 1 remains at `macos/` with no speaker-casting code.
