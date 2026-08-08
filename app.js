const JORDAN_ADHAN_URL = "./audio/athan-amman-jordan.mp3";

const ADHANS = [
  {
    name: "Adhan by Alafasy - style 1",
    url: "https://cdn.aladhan.com/audio/adhans/a9.mp3",
    theme: "alafasy",
  },
  {
    name: "Adhan by Ahmad al-Nafees",
    url: "https://cdn.aladhan.com/audio/adhans/a1.mp3",
    theme: "nafees",
  },
  {
    name: "Adhan by Hafiz Mustafa Özcan from Turkey",
    url: "https://cdn.aladhan.com/audio/adhans/a2.mp3",
    theme: "turkey",
  },
  {
    name: "Adhan from Karl Jenkins' Mass for Peace",
    url: "https://cdn.aladhan.com/audio/adhans/a3.mp3",
    theme: "jenkins",
  },
  {
    name: "Adhan from Dubai's One TV by Mishary Rashid Alafasy",
    url: "https://cdn.aladhan.com/audio/adhans/a4.mp3",
    theme: "dubai",
  },
  {
    name: "Another Adhan by Mishary Rashid Alafasy",
    url: "https://cdn.aladhan.com/audio/adhans/a7.mp3",
    theme: "alafasy2",
  },
  {
    name: "Adhan by Mansour Al-Zahrani",
    url: "https://cdn.aladhan.com/audio/adhans/a11-mansour-al-zahrani.mp3",
    theme: "zahrani",
  },
  {
    name: "Adhan by Ma'rouf Rashad Al-Sharif from Jordan",
    url: JORDAN_ADHAN_URL,
    theme: "jordan",
    credit: "https://soundcloud.com/jihad-khaled-m-abdulhaq/athan-amman-jordan",
  },
];

const METHODS = [
  { id: 2, name: "Islamic Society of North America (ISNA)" },
  { id: 3, name: "Muslim World League" },
  { id: 4, name: "Umm Al-Qura University, Makkah" },
  { id: 5, name: "Egyptian General Authority of Survey" },
  { id: 1, name: "University of Islamic Sciences, Karachi" },
  { id: 8, name: "Gulf Region" },
  { id: 9, name: "Kuwait" },
  { id: 10, name: "Qatar" },
  { id: 11, name: "Majlis Ugama Islam Singapura (MUIS)" },
  { id: 12, name: "Union des Organisations Islamiques de France" },
  { id: 13, name: "Diyanet İşleri Başkanlığı, Turkey" },
  { id: 14, name: "Spiritual Administration of Muslims of Russia" },
  { id: 15, name: "Moonsighting Committee Worldwide" },
  { id: 16, name: "Dubai" },
  { id: 0, name: "Shia Ithna-Ashari, Leva Institute, Qum" },
  { id: 7, name: "Institute of Geophysics, University of Tehran" },
];

const PRAYER_ORDER = [
  "Fajr",
  "Sunrise",
  "Dhuhr",
  "Asr",
  "Maghrib",
  "Isha",
  "Midnight",
  "Firstthird",
  "Lastthird",
];

const ADHAN_PRAYERS = new Set(["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]);

const SECONDARY_TIMES = ["Sunrise", "Midnight", "Firstthird", "Lastthird"];

const ALARM_SOUNDS = [
  { id: "classic-alarm", name: "Classic Alarm", url: "./audio/alarms/classic-alarm.mp3" },
  { id: "digital-clock-beep", name: "Digital Clock Beep", url: "./audio/alarms/digital-clock-beep.mp3" },
  { id: "facility-alarm", name: "Facility Alarm", url: "./audio/alarms/facility-alarm.mp3" },
  { id: "alert-alarm", name: "Alert Alarm", url: "./audio/alarms/alert-alarm.mp3" },
  { id: "positive-notification", name: "Positive Notification", url: "./audio/alarms/positive-notification.mp3" },
  { id: "correct-answer-tone", name: "Correct Answer Tone", url: "./audio/alarms/correct-answer-tone.mp3" },
  { id: "game-notification-wave", name: "Rooster", url: "./audio/alarms/game-notification-wave.mp3" },
  { id: "software-interface-start", name: "Interface Start", url: "./audio/alarms/software-interface-start.mp3" },
];

/** Alarms + Adhan clips selectable for Sunrise / Midnight / thirds. */
const SECONDARY_SOUNDS = [
  ...ALARM_SOUNDS,
  ...ADHANS.map((adhan) => ({
    id: `adhan-${adhan.theme}`,
    name: adhan.name,
    url: adhan.url,
  })),
];

const DEFAULT_SECONDARY_ALERTS = {
  Sunrise: { enabled: false, sound: "positive-notification" },
  Midnight: { enabled: false, sound: "digital-clock-beep" },
  Firstthird: { enabled: false, sound: "correct-answer-tone" },
  Lastthird: { enabled: false, sound: "classic-alarm" },
};

const LABELS = {
  Fajr: "Fajr",
  Sunrise: "Sunrise",
  Dhuhr: "Dhuhr",
  Asr: "Asr",
  Maghrib: "Maghrib",
  Isha: "Isha",
  Midnight: "Midnight",
  Firstthird: "First Third",
  Lastthird: "Last Third (Tahajjud)",
};

const ALARM_PLAY_MS = 60_000;

/** Tiny silent WAV — used to unlock autoplay without hearing Adhan/alarms. */
const KEEP_ALIVE_SRC =
  "data:audio/wav;base64,UklGRiwAAABXQVZFZm10IBAAAAABAAEAIlYAAESsAAACABAAZGF0YQgAAAAAAAAAAA==";

const STORAGE_KEY = "athan-player-settings-v1";

const DEFAULT_LOCATION = {
  label: "Tampa, Florida, United States",
  latitude: 27.9506,
  longitude: -82.4572,
  timezone: "America/New_York",
};

const els = {
  connectionStatus: document.getElementById("connectionStatus"),
  dateLine: document.getElementById("dateLine"),
  gregorianDate: document.getElementById("gregorianDate"),
  hijriDate: document.getElementById("hijriDate"),
  localClock: document.getElementById("localClock"),
  locationTitle: document.getElementById("locationTitle"),
  methodLabel: document.getElementById("methodLabel"),
  nextPill: document.getElementById("nextPill"),
  nextPrayerName: document.getElementById("nextPrayerName"),
  nextPrayerTime: document.getElementById("nextPrayerTime"),
  countdownBlock: document.getElementById("countdownBlock"),
  countdownValue: document.getElementById("countdownValue"),
  prayerList: document.getElementById("prayerList"),
  adhanSelect: document.getElementById("adhanSelect"),
  fajrAdhanSelect: document.getElementById("fajrAdhanSelect"),
  fajrAdhanRow: document.getElementById("fajrAdhanRow"),
  differentFajr: document.getElementById("differentFajr"),
  showCountdown: document.getElementById("showCountdown"),
  secondaryAlertsList: document.getElementById("secondaryAlertsList"),
  adhanAudio: document.getElementById("adhanAudio"),
  alarmAudio: document.getElementById("alarmAudio"),
  keepAliveAudio: document.getElementById("keepAliveAudio"),
  audioHint: document.getElementById("audioHint"),
  enableAudioBtn: document.getElementById("enableAudioBtn"),
  audioArmStatus: document.getElementById("audioArmStatus"),
  adhanTransport: document.getElementById("adhanTransport"),
  fajrAdhanTransport: document.getElementById("fajrAdhanTransport"),
  locationInput: document.getElementById("locationInput"),
  searchBtn: document.getElementById("searchBtn"),
  suggestions: document.getElementById("suggestions"),
  methodSelect: document.getElementById("methodSelect"),
  schoolSelect: document.getElementById("schoolSelect"),
  refreshBtn: document.getElementById("refreshBtn"),
  fullscreenBtn: document.getElementById("fullscreenBtn"),
  metaNote: document.getElementById("metaNote"),
  statusNext: document.getElementById("statusNext"),
  audioState: document.getElementById("audioState"),
};

const state = {
  location: { ...DEFAULT_LOCATION },
  method: 2,
  school: 0,
  timings: null,
  dateInfo: null,
  meta: null,
  audioEnabled: false,
  adhanUrl: ADHANS[0].url,
  fajrAdhanUrl: ADHANS[0].url,
  differentFajr: false,
  showCountdown: true,
  secondaryAlerts: structuredClone(DEFAULT_SECONDARY_ALERTS),
  lastPlayedKey: null,
  wakeLock: null,
  audioCtx: null,
  alarmStopTimer: null,
  alarmLoopHandler: null,
  previewId: null,
  transportControls: new Map(),
  searchTimer: null,
  searchRequestId: 0,
};

function loadSettings() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return;
    const saved = JSON.parse(raw);
    Object.assign(state, {
      location: saved.location || state.location,
      method: saved.method ?? state.method,
      school: saved.school ?? state.school,
      adhanUrl: saved.adhanUrl || state.adhanUrl,
      fajrAdhanUrl: saved.fajrAdhanUrl || state.fajrAdhanUrl,
      differentFajr: Boolean(saved.differentFajr),
      showCountdown: saved.showCountdown !== false,
      secondaryAlerts: {
        ...structuredClone(DEFAULT_SECONDARY_ALERTS),
        ...(saved.secondaryAlerts || {}),
      },
    });
    // Migrate older Jordan CDN links to the local SoundCloud file.
    if (
      typeof state.adhanUrl === "string" &&
      (state.adhanUrl.includes("jsdelivr.net/gh/Kiwifu/adhan-mp3") ||
        state.adhanUrl.includes("Al_Albane_-_Jordan"))
    ) {
      state.adhanUrl = JORDAN_ADHAN_URL;
    }
    if (
      typeof state.fajrAdhanUrl === "string" &&
      (state.fajrAdhanUrl.includes("jsdelivr.net/gh/Kiwifu/adhan-mp3") ||
        state.fajrAdhanUrl.includes("Al_Albane_-_Jordan"))
    ) {
      state.fajrAdhanUrl = JORDAN_ADHAN_URL;
    }
    // Migrate old Tahajjud Adhan checkbox into secondary alerts.
    if (saved.playTahajjud && state.secondaryAlerts.Lastthird) {
      state.secondaryAlerts.Lastthird.enabled = true;
    }
  } catch {
    /* ignore corrupt storage */
  }
}

function saveSettings() {
  localStorage.setItem(
    STORAGE_KEY,
    JSON.stringify({
      location: state.location,
      method: state.method,
      school: state.school,
      adhanUrl: state.adhanUrl,
      fajrAdhanUrl: state.fajrAdhanUrl,
      differentFajr: state.differentFajr,
      showCountdown: state.showCountdown,
      secondaryAlerts: state.secondaryAlerts,
    })
  );
}

function fillSelect(select, items, getValue, getLabel, current) {
  select.innerHTML = "";
  for (const item of items) {
    const option = document.createElement("option");
    option.value = getValue(item);
    option.textContent = getLabel(item);
    select.appendChild(option);
  }
  const values = items.map(getValue);
  select.value = values.includes(current) ? current : values[0];
}

function pad(n) {
  return String(n).padStart(2, "0");
}

function parseApiTime(hhmm) {
  const [h, m] = String(hhmm).split(":").map(Number);
  return { hours: h, minutes: m || 0 };
}

function formatDisplayTime(hhmm) {
  const { hours, minutes } = parseApiTime(hhmm);
  const d = new Date();
  d.setHours(hours, minutes, 0, 0);
  return d.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
}

/**
 * Read calendar/clock parts in a time zone.
 * Uses the sv-SE locale which always formats 24-hour time as
 * "YYYY-MM-DD HH:mm:ss" — this avoids Safari's hour12 / hourCycle bugs.
 */
function readZoneParts(date, timeZone) {
  const options = {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  };
  if (timeZone) options.timeZone = timeZone;

  let raw = new Intl.DateTimeFormat("sv-SE", options).format(date);
  raw = raw.replace("T", " ").replace(",", " ").replace(/\s+/g, " ").trim();

  const match = raw.match(
    /(\d{4})-(\d{2})-(\d{2})[ ]+(\d{1,2}):(\d{2})(?::(\d{2}))?/
  );

  if (!match) {
    // Last-resort fallback using device local getters (no Intl hour bugs).
    return {
      year: date.getFullYear(),
      month: date.getMonth() + 1,
      day: date.getDate(),
      hour: date.getHours(),
      minute: date.getMinutes(),
      second: date.getSeconds(),
    };
  }

  let hour = Number(match[4]);
  if (hour === 24) hour = 0;

  return {
    year: Number(match[1]),
    month: Number(match[2]),
    day: Number(match[3]),
    hour,
    minute: Number(match[5]),
    second: Number(match[6] || 0),
  };
}

function getLocalParts(date = new Date()) {
  const tz = state.location.timezone;
  const deviceTz = Intl.DateTimeFormat().resolvedOptions().timeZone;

  // Same zone as the device → use native Date getters (most reliable on Safari).
  if (!tz || tz === deviceTz) {
    return {
      year: date.getFullYear(),
      month: date.getMonth() + 1,
      day: date.getDate(),
      hour: date.getHours(),
      minute: date.getMinutes(),
      second: date.getSeconds(),
    };
  }

  const zoned = readZoneParts(date, tz);
  const device = readZoneParts(date, deviceTz);
  // If both zones currently show the same wall clock, prefer native getters.
  if (
    zoned.year === device.year &&
    zoned.month === device.month &&
    zoned.day === device.day &&
    zoned.hour === device.hour &&
    zoned.minute === device.minute
  ) {
    return {
      year: date.getFullYear(),
      month: date.getMonth() + 1,
      day: date.getDate(),
      hour: date.getHours(),
      minute: date.getMinutes(),
      second: date.getSeconds(),
    };
  }

  return zoned;
}

function addCalendarDays(year, month, day, days) {
  const dt = new Date(Date.UTC(year, month - 1, day + days));
  return {
    year: dt.getUTCFullYear(),
    month: dt.getUTCMonth() + 1,
    day: dt.getUTCDate(),
  };
}

function localMinutesNow() {
  const p = getLocalParts();
  return p.hour * 60 + p.minute;
}

function localSecondsNow() {
  const p = getLocalParts();
  return p.hour * 3600 + p.minute * 60 + p.second;
}

function prayerMinutes(hhmm) {
  const { hours, minutes } = parseApiTime(hhmm);
  return hours * 60 + minutes;
}

function prayerSeconds(hhmm) {
  const { hours, minutes } = parseApiTime(hhmm);
  return hours * 3600 + minutes * 60;
}

function timingDateKey() {
  const p = getLocalParts();
  return `${p.year}-${pad(p.month)}-${pad(p.day)}`;
}

function apiDateParam() {
  const p = getLocalParts();
  return `${pad(p.day)}-${pad(p.month)}-${p.year}`;
}

function msUntilPrayer(hhmm, { tomorrow = false } = {}) {
  const nowSec = localSecondsNow();
  let targetSec = prayerSeconds(hhmm);
  let dayOffset = tomorrow ? 1 : 0;

  if (!tomorrow && targetSec <= nowSec) {
    dayOffset = 1;
  }

  // Wall-clock difference in the prayer location's local day.
  // (DST transition days can be off by ~1h once a year — acceptable for UI.)
  return (targetSec + dayOffset * 86400 - nowSec) * 1000;
}

function setStatus(message) {
  els.connectionStatus.textContent = message;
}

async function searchPlaces(query) {
  const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(
    query
  )}&count=8&language=en&format=json`;
  const res = await fetch(url);
  if (!res.ok) throw new Error("Place search failed");
  const data = await res.json();
  return (data.results || []).map((place) => ({
    label: [place.name, place.admin1, place.country].filter(Boolean).join(", "),
    latitude: place.latitude,
    longitude: place.longitude,
    timezone: place.timezone,
  }));
}

async function fetchTimings() {
  const { latitude, longitude } = state.location;
  const date = apiDateParam();
  const url =
    `https://api.aladhan.com/v1/timings/${date}` +
    `?latitude=${latitude}&longitude=${longitude}` +
    `&method=${state.method}&school=${state.school}`;

  const res = await fetch(url);
  if (!res.ok) throw new Error("Could not load prayer times");
  const json = await res.json();
  if (json.code !== 200) throw new Error(json.status || "API error");

  state.timings = json.data.timings;
  state.dateInfo = json.data.date;
  state.meta = json.data.meta;
  if (json.data.meta?.timezone) {
    state.location.timezone = json.data.meta.timezone;
  }
}

function activeAdhanPrayers() {
  return [...ADHAN_PRAYERS];
}

function alarmUrlFor(soundId) {
  return (
    SECONDARY_SOUNDS.find((s) => s.id === soundId)?.url ||
    SECONDARY_SOUNDS[0].url
  );
}

function renderSecondaryAlerts() {
  if (!els.secondaryAlertsList) return;
  // Drop prior alarm transport bindings before rebuilding rows.
  for (const key of [...state.transportControls.keys()]) {
    if (key.startsWith("alarm-")) state.transportControls.delete(key);
  }
  els.secondaryAlertsList.innerHTML = "";
  for (const key of SECONDARY_TIMES) {
    const cfg = state.secondaryAlerts[key] || DEFAULT_SECONDARY_ALERTS[key];
    const row = document.createElement("div");
    row.className = "secondary-row";
    row.dataset.key = key;

    const name = document.createElement("span");
    name.className = "secondary-row__name";
    name.textContent = LABELS[key] || key;

    const toggle = document.createElement("label");
    toggle.className = "check";
    const input = document.createElement("input");
    input.type = "checkbox";
    input.checked = Boolean(cfg.enabled);
    const label = document.createElement("span");
    label.textContent = input.checked ? "On" : "Off";
    toggle.append(input, label);

    const select = document.createElement("select");
    select.className = "select";
    // Keep sound picker enabled so every clip can be previewed even when Off.
    select.disabled = false;
    const alarmGroup = document.createElement("optgroup");
    alarmGroup.label = "Alarms";
    for (const sound of ALARM_SOUNDS) {
      const opt = document.createElement("option");
      opt.value = sound.id;
      opt.textContent = sound.name;
      alarmGroup.appendChild(opt);
    }
    const adhanGroup = document.createElement("optgroup");
    adhanGroup.label = "Adhan";
    for (const sound of SECONDARY_SOUNDS.filter((s) => s.id.startsWith("adhan-"))) {
      const opt = document.createElement("option");
      opt.value = sound.id;
      opt.textContent = sound.name;
      adhanGroup.appendChild(opt);
    }
    select.append(alarmGroup, adhanGroup);
    select.value = cfg.sound;

    const transportId = `alarm-${key}`;
    const transport = createTransport(transportId, {
      onPlay: async () => {
        try {
          const soundId = select.value;
          const label =
            SECONDARY_SOUNDS.find((s) => s.id === soundId)?.name ||
            LABELS[key] ||
            key;
          await previewAlarmSound(soundId, transportId, label);
        } catch (err) {
          els.audioHint.textContent =
            "Could not play alarm preview. Tap Play again after interacting with the page.";
          console.warn(err);
        }
      },
      onPause: () => pausePreview(transportId),
      onStop: () => stopPreview(transportId),
    });

    input.addEventListener("change", () => {
      if (!state.secondaryAlerts[key]) {
        state.secondaryAlerts[key] = {
          ...DEFAULT_SECONDARY_ALERTS[key],
        };
      }
      state.secondaryAlerts[key].enabled = input.checked;
      label.textContent = input.checked ? "On" : "Off";
      saveSettings();
    });
    select.addEventListener("change", () => {
      if (!state.secondaryAlerts[key]) {
        state.secondaryAlerts[key] = {
          ...DEFAULT_SECONDARY_ALERTS[key],
        };
      }
      state.secondaryAlerts[key].sound = select.value;
      saveSettings();
    });

    // Previews work even when the alert is Off — so you can hear every sound.
    row.append(name, toggle, select, transport);
    els.secondaryAlertsList.appendChild(row);
  }
}

function findNextPrayer() {
  if (!state.timings) return null;
  const now = localMinutesNow();
  const candidates = PRAYER_ORDER.filter((name) => state.timings[name]);

  for (const name of candidates) {
    if (prayerMinutes(state.timings[name]) > now) {
      return { name, time: state.timings[name] };
    }
  }

  return {
    name: "Fajr",
    time: state.timings.Fajr,
    tomorrow: true,
  };
}

function renderDates() {
  if (!state.dateInfo) return;
  const g = state.dateInfo.gregorian;
  const h = state.dateInfo.hijri;
  els.gregorianDate.textContent = `${g.weekday.en}, ${Number(g.day)} ${g.month.en} ${g.year}`;
  els.hijriDate.textContent = `${h.weekday.en}, ${Number(h.day)} ${h.month.en} ${h.year} AH`;
  updateLocalClock();
}

function updateLocalClock() {
  const now = new Date();
  const tz = state.location.timezone || undefined;
  els.localClock.textContent = now.toLocaleTimeString([], {
    timeZone: tz,
    hour: "numeric",
    minute: "2-digit",
    second: "2-digit",
  });
}

function themeForUrl(url) {
  return ADHANS.find((a) => a.url === url)?.theme || "alafasy";
}

function applyTheme(url = state.adhanUrl) {
  document.body.dataset.theme = themeForUrl(url);
}

function renderPrayers() {
  if (!state.timings) return;
  const now = localMinutesNow();
  const next = findNextPrayer();

  els.prayerList.innerHTML = "";
  for (const name of PRAYER_ORDER) {
    const raw = state.timings[name];
    if (!raw) continue;
    const li = document.createElement("li");
    li.className = "prayer";
    const mins = prayerMinutes(raw);
    if (!next?.tomorrow && next?.name === name) li.classList.add("is-next");
    if (mins <= now && !(next?.tomorrow && name === "Fajr")) {
      li.classList.add("is-passed");
    }
    li.innerHTML = `<span class="prayer__name">${LABELS[name] || name}${ADHAN_PRAYERS.has(name) ? "" : `<small class="prayer__tag">${state.secondaryAlerts[name]?.enabled ? "alarm on" : "alarm off"}</small>`}</span><span class="prayer__time">${formatDisplayTime(raw)}</span>`;
    els.prayerList.appendChild(li);
  }

  if (next) {
    const label = next.tomorrow ? `${LABELS[next.name]} (tomorrow)` : LABELS[next.name];
    els.nextPrayerName.textContent = label;
    els.nextPrayerTime.textContent = formatDisplayTime(next.time);
    els.statusNext.textContent = `Next prayer: ${label} @ ${formatDisplayTime(next.time)}`;
  }

  els.locationTitle.textContent = state.location.label;
  els.methodLabel.textContent =
    state.meta?.method?.name ||
    METHODS.find((m) => m.id === state.method)?.name ||
    "Prayer calculation";
  if (document.activeElement !== els.locationInput) {
    els.locationInput.value = state.location.label;
  }
}

function updateCountdown() {
  const show = Boolean(state.showCountdown && state.timings);
  if (show) {
    els.countdownBlock.removeAttribute("hidden");
    els.countdownBlock.style.display = "flex";
  } else {
    els.countdownBlock.setAttribute("hidden", "");
    els.countdownBlock.style.display = "none";
    return;
  }

  const next = findNextPrayer();
  if (!next) {
    els.countdownValue.textContent = "--:--:--";
    return;
  }

  let remaining = msUntilPrayer(next.time, { tomorrow: Boolean(next.tomorrow) });
  if (!Number.isFinite(remaining)) remaining = 0;
  remaining = Math.max(0, Math.floor(remaining));

  const hours = Math.floor(remaining / 3600000);
  remaining -= hours * 3600000;
  const minutes = Math.floor(remaining / 60000);
  remaining -= minutes * 60000;
  const seconds = Math.floor(remaining / 1000);
  els.countdownValue.textContent = `${pad(hours)}:${pad(minutes)}:${pad(seconds)}`;
}

function syncAudioSource(force = false) {
  const preferred = state.adhanUrl;
  if (force || els.adhanAudio.src !== preferred) {
    els.adhanAudio.src = preferred;
  }
  applyTheme(preferred);
}

function createTransport(id, { onPlay, onPause, onStop }, host = null) {
  const wrap = host || document.createElement("div");
  wrap.className = "transport";
  wrap.dataset.transportId = id;
  wrap.replaceChildren();

  const play = document.createElement("button");
  play.type = "button";
  play.className = "transport__btn";
  play.dataset.action = "play";
  play.textContent = "Play";
  play.addEventListener("click", () => onPlay());

  const pause = document.createElement("button");
  pause.type = "button";
  pause.className = "transport__btn";
  pause.dataset.action = "pause";
  pause.textContent = "Pause";
  pause.addEventListener("click", () => onPause());

  const stop = document.createElement("button");
  stop.type = "button";
  stop.className = "transport__btn";
  stop.dataset.action = "stop";
  stop.textContent = "Stop";
  stop.addEventListener("click", () => onStop());

  wrap.append(play, pause, stop);
  state.transportControls.set(id, { wrap, play, pause, stop });
  return wrap;
}

function setTransportActive(id, mode) {
  for (const [key, ctrl] of state.transportControls) {
    ctrl.play.classList.toggle("is-active", key === id && mode === "playing");
    ctrl.pause.classList.toggle("is-active", key === id && mode === "paused");
    ctrl.stop.classList.toggle("is-active", false);
  }
}

function sameAudioSrc(audioEl, url) {
  if (!audioEl?.src || !url) return false;
  try {
    return new URL(url, window.location.href).href === audioEl.src;
  } catch {
    return audioEl.src.endsWith(url.replace(/^\.\//, ""));
  }
}

async function previewAdhan(url, transportId, label) {
  stopKeepAlive();
  clearAlarmPlayback();
  try {
    els.alarmAudio.pause();
  } catch {
    /* ignore */
  }

  if (
    state.previewId === transportId &&
    sameAudioSrc(els.adhanAudio, url) &&
    !els.adhanAudio.paused
  ) {
    return;
  }

  if (
    state.previewId === transportId &&
    sameAudioSrc(els.adhanAudio, url) &&
    els.adhanAudio.paused &&
    els.adhanAudio.currentTime > 0
  ) {
    prepareAudiblePlayback(els.adhanAudio);
    await els.adhanAudio.play();
    state.previewId = transportId;
    setTransportActive(transportId, "playing");
    els.audioHint.textContent = `Playing preview: ${label}`;
    updateMediaSession("playing", label);
    return;
  }

  if (!sameAudioSrc(els.adhanAudio, url)) {
    els.adhanAudio.src = url;
  }
  prepareAudiblePlayback(els.adhanAudio);
  els.adhanAudio.currentTime = 0;
  await els.adhanAudio.play();
  state.previewId = transportId;
  setTransportActive(transportId, "playing");
  els.audioHint.textContent = `Playing preview: ${label}`;
  updateMediaSession("playing", label);
}

async function previewAlarmSound(soundId, transportId, label) {
  stopKeepAlive();
  try {
    els.adhanAudio.pause();
  } catch {
    /* ignore */
  }
  clearAlarmPlayback();

  const url = alarmUrlFor(soundId);
  if (
    state.previewId === transportId &&
    sameAudioSrc(els.alarmAudio, url) &&
    els.alarmAudio.paused &&
    els.alarmAudio.currentTime > 0
  ) {
    prepareAudiblePlayback(els.alarmAudio);
    await els.alarmAudio.play();
    state.previewId = transportId;
    setTransportActive(transportId, "playing");
    els.audioHint.textContent = `Playing preview: ${label}`;
    updateMediaSession("playing", label);
    return;
  }

  els.alarmAudio.src = url;
  prepareAudiblePlayback(els.alarmAudio);
  els.alarmAudio.currentTime = 0;
  await els.alarmAudio.play();
  state.previewId = transportId;
  setTransportActive(transportId, "playing");
  els.audioHint.textContent = `Playing preview: ${label}`;
  updateMediaSession("playing", label);
}

function pausePreview(transportId) {
  const usingAdhan =
    transportId === "adhan" || transportId === "fajr-adhan";
  const audio = usingAdhan ? els.adhanAudio : els.alarmAudio;
  try {
    audio.pause();
  } catch {
    /* ignore */
  }
  if (state.previewId === transportId) {
    setTransportActive(transportId, "paused");
    els.audioHint.textContent = "Paused preview.";
    updateMediaSession("paused");
  }
}

function stopPreview(transportId) {
  const usingAdhan =
    transportId === "adhan" || transportId === "fajr-adhan";
  if (usingAdhan) {
    try {
      els.adhanAudio.pause();
      els.adhanAudio.currentTime = 0;
    } catch {
      /* ignore */
    }
  } else {
    clearAlarmPlayback();
  }
  if (state.previewId === transportId || !transportId) {
    state.previewId = null;
    setTransportActive(transportId || "", "stopped");
    if (state.audioEnabled) startKeepAlive();
    els.audioHint.textContent = state.audioEnabled
      ? "Stopped. Audio is still armed for prayer time."
      : "Preview stopped.";
    updateMediaSession("stopped");
  }
}

function mountAdhanTransports() {
  const fill = (host, id, getUrl, getLabel) => {
    if (!host) return;
    createTransport(
      id,
      {
        onPlay: async () => {
          try {
            await previewAdhan(getUrl(), id, getLabel());
          } catch (err) {
            els.audioHint.textContent =
              "Could not play Adhan preview. Tap Play again after interacting with the page.";
            console.warn(err);
          }
        },
        onPause: () => pausePreview(id),
        onStop: () => stopPreview(id),
      },
      host
    );
  };

  fill(
    els.adhanTransport,
    "adhan",
    () => els.adhanSelect.value,
    () => ADHANS.find((a) => a.url === els.adhanSelect.value)?.name || "Adhan"
  );
  fill(
    els.fajrAdhanTransport,
    "fajr-adhan",
    () => els.fajrAdhanSelect.value,
    () =>
      ADHANS.find((a) => a.url === els.fajrAdhanSelect.value)?.name ||
      "Fajr Adhan"
  );
}

function isShortAlarmSound(soundId) {
  return ALARM_SOUNDS.some((s) => s.id === soundId);
}

function clearAlarmPlayback() {
  if (state.alarmStopTimer) {
    clearTimeout(state.alarmStopTimer);
    state.alarmStopTimer = null;
  }
  if (state.alarmLoopHandler) {
    els.alarmAudio.removeEventListener("ended", state.alarmLoopHandler);
    state.alarmLoopHandler = null;
  }
  try {
    els.alarmAudio.pause();
    els.alarmAudio.currentTime = 0;
  } catch {
    /* ignore */
  }
}

function stopAllAudio({ keepArmed = true } = {}) {
  clearAlarmPlayback();
  try {
    els.adhanAudio.pause();
    els.adhanAudio.currentTime = 0;
  } catch {
    /* ignore */
  }
  state.previewId = null;
  setTransportActive("", "stopped");
  updateMediaSession("stopped");
  if (keepArmed && state.audioEnabled) {
    els.audioHint.textContent =
      "Stopped. Audio is still armed — alarms and Adhan will play at the next scheduled time.";
    startKeepAlive();
  } else {
    els.audioHint.textContent =
      "Click Enable Adhan audio once so browsers allow autoplay at prayer time.";
  }
}

function updateMediaSession(stateName, title = "Athan") {
  if (!("mediaSession" in navigator)) return;
  try {
    navigator.mediaSession.metadata = new MediaMetadata({
      title,
      artist: "Athan",
      album: "Prayer times",
    });
    navigator.mediaSession.playbackState =
      stateName === "playing" ? "playing" : "paused";
  } catch {
    /* optional */
  }
}

function bindMediaSessionHandlers() {
  if (!("mediaSession" in navigator)) return;
  try {
    navigator.mediaSession.setActionHandler("pause", () => stopAllAudio());
    navigator.mediaSession.setActionHandler("stop", () => stopAllAudio());
    navigator.mediaSession.setActionHandler("play", () => {
      if (state.audioEnabled) startKeepAlive();
    });
  } catch {
    /* optional */
  }
}

async function startKeepAlive() {
  if (!els.keepAliveAudio || !state.audioEnabled) return;
  try {
    els.keepAliveAudio.src = KEEP_ALIVE_SRC;
    els.keepAliveAudio.loop = true;
    // Unmuted silent file keeps Safari's autoplay permission for later Adhan.
    els.keepAliveAudio.muted = false;
    els.keepAliveAudio.volume = 1;
    await els.keepAliveAudio.play();
  } catch {
    /* mobile may still suspend; best-effort */
  }
}

function stopKeepAlive() {
  if (!els.keepAliveAudio) return;
  try {
    els.keepAliveAudio.pause();
    els.keepAliveAudio.currentTime = 0;
  } catch {
    /* ignore */
  }
}

/**
 * Unlock HTML audio on a user gesture without playing Adhan/alarms.
 * Important: do NOT use muted=true here — Safari won't allow later unmuted scheduled play.
 */
async function silentlyUnlockAudio() {
  try {
    const Ctx = window.AudioContext || window.webkitAudioContext;
    if (Ctx) {
      if (!state.audioCtx) state.audioCtx = new Ctx();
      if (state.audioCtx.state === "suspended") {
        await state.audioCtx.resume();
      }
      const buffer = state.audioCtx.createBuffer(1, 1, 22050);
      const source = state.audioCtx.createBufferSource();
      source.buffer = buffer;
      source.connect(state.audioCtx.destination);
      source.start(0);
    }
  } catch {
    /* optional */
  }

  const elements = [els.adhanAudio, els.alarmAudio, els.keepAliveAudio].filter(
    Boolean
  );
  let unlocked = 0;
  for (const el of elements) {
    try {
      el.muted = false;
      el.volume = 1;
      el.src = KEEP_ALIVE_SRC;
      await el.play();
      el.pause();
      el.currentTime = 0;
      unlocked += 1;
    } catch (err) {
      console.warn("Audio unlock skipped for", el.id, err);
    }
  }

  // Point Adhan/alarm at real files for later scheduled play — do not play them now.
  syncAudioSource(true);
  if (els.alarmAudio) {
    els.alarmAudio.src = ALARM_SOUNDS[0].url;
    els.alarmAudio.preload = "auto";
  }
  if (els.keepAliveAudio) {
    els.keepAliveAudio.src = KEEP_ALIVE_SRC;
  }

  if (!unlocked) {
    throw new Error("Could not unlock any audio element");
  }
}

function prepareAudiblePlayback(audioEl) {
  if (!audioEl) return;
  audioEl.muted = false;
  audioEl.volume = 1;
}

async function playAdhan(prayerName) {
  if (!state.audioEnabled) return;
  const url =
    prayerName === "Fajr" && state.differentFajr
      ? state.fajrAdhanUrl
      : state.adhanUrl;
  if (els.adhanAudio.src !== url) {
    els.adhanAudio.src = url;
  }
  try {
    clearAlarmPlayback();
    stopKeepAlive();
    prepareAudiblePlayback(els.adhanAudio);
    els.adhanAudio.currentTime = 0;
    await els.adhanAudio.play();
    const label = LABELS[prayerName] || prayerName;
    els.audioHint.textContent = `Playing Adhan for ${label}.`;
    updateMediaSession("playing", `Adhan — ${label}`);
  } catch (err) {
    // Stay armed — a blocked attempt shouldn't turn autoplay off.
    els.audioHint.textContent =
      "Scheduled Adhan was blocked by the browser. Toggle Audio Off then On again, and keep this tab open.";
    console.warn(err);
  }
}

async function playAlarm(prayerName, soundId) {
  if (!state.audioEnabled) return;
  const url = alarmUrlFor(soundId);
  const label = LABELS[prayerName] || prayerName;
  clearAlarmPlayback();
  els.alarmAudio.src = url;
  try {
    els.adhanAudio.pause();
    stopKeepAlive();
    prepareAudiblePlayback(els.alarmAudio);
    els.alarmAudio.currentTime = 0;

    // Short alarm clips loop for 60s. Full Adhan picks in this dropdown play once.
    if (isShortAlarmSound(soundId)) {
      const endsAt = Date.now() + ALARM_PLAY_MS;
      state.alarmLoopHandler = () => {
        if (Date.now() >= endsAt) {
          clearAlarmPlayback();
          startKeepAlive();
          els.audioHint.textContent = `Alarm finished for ${label}.`;
          updateMediaSession("stopped");
          return;
        }
        els.alarmAudio.currentTime = 0;
        els.alarmAudio.play().catch(() => {});
      };
      els.alarmAudio.addEventListener("ended", state.alarmLoopHandler);
      state.alarmStopTimer = setTimeout(() => {
        clearAlarmPlayback();
        startKeepAlive();
        els.audioHint.textContent = `Alarm finished for ${label}.`;
        updateMediaSession("stopped");
      }, ALARM_PLAY_MS);
      await els.alarmAudio.play();
      els.audioHint.textContent = `Playing alarm for ${label} (60 seconds).`;
    } else {
      await els.alarmAudio.play();
      els.audioHint.textContent = `Playing alert sound for ${label}.`;
    }
    updateMediaSession("playing", `Alarm — ${label}`);
  } catch (err) {
    els.audioHint.textContent =
      "Scheduled alarm was blocked by the browser. Toggle Audio Off then On again, and keep this tab open.";
    console.warn(err);
  }
}

function checkPrayerAlarm() {
  if (!state.timings || !state.audioEnabled) return;
  const now = localMinutesNow();
  const day = timingDateKey();

  for (const name of activeAdhanPrayers()) {
    const raw = state.timings[name];
    if (!raw) continue;
    if (prayerMinutes(raw) !== now) continue;
    const key = `${day}:${name}:adhan`;
    if (state.lastPlayedKey === key) return;
    state.lastPlayedKey = key;
    playAdhan(name);
    return;
  }

  for (const name of SECONDARY_TIMES) {
    const cfg = state.secondaryAlerts[name];
    if (!cfg?.enabled) continue;
    const raw = state.timings[name];
    if (!raw) continue;
    if (prayerMinutes(raw) !== now) continue;
    const key = `${day}:${name}:alarm`;
    if (state.lastPlayedKey === key) return;
    state.lastPlayedKey = key;
    playAlarm(name, cfg.sound);
    return;
  }
}

function updateAudioUi() {
  const on = Boolean(state.audioEnabled);
  els.enableAudioBtn.classList.toggle("is-on", on);
  els.enableAudioBtn.setAttribute("aria-pressed", on ? "true" : "false");
  els.enableAudioBtn.textContent = on ? "Audio: On" : "Audio: Off";

  if (els.audioArmStatus) {
    els.audioArmStatus.classList.toggle("is-on", on);
    els.audioArmStatus.classList.toggle("is-off", !on);
    els.audioArmStatus.textContent = on
      ? "Status: On — armed for prayer / alarm times"
      : "Status: Off — autoplay not armed";
  }

  if (els.audioState) {
    els.audioState.classList.toggle("is-on", on);
    els.audioState.classList.toggle("is-off", !on);
    els.audioState.textContent = on
      ? "Audio: On (armed)"
      : "Audio: Off";
  }

  if (on) {
    els.audioHint.textContent =
      "Autoplay is On. No sound until the next scheduled Adhan or enabled alarm time. Preview buttons still work anytime.";
  } else {
    els.audioHint.textContent =
      "Autoplay is Off — nothing plays automatically. You can still press Play beside any sound to hear it.";
  }
}

async function requestWakeLock() {
  try {
    if ("wakeLock" in navigator) {
      state.wakeLock = await navigator.wakeLock.request("screen");
      state.wakeLock.addEventListener("release", () => {
        state.wakeLock = null;
      });
    }
  } catch {
    /* optional */
  }
}

function releaseWakeLock() {
  try {
    if (state.wakeLock) {
      state.wakeLock.release();
      state.wakeLock = null;
    }
  } catch {
    /* optional */
  }
}

async function toggleAudio() {
  // Turn off
  if (state.audioEnabled) {
    state.audioEnabled = false;
    stopAllAudio({ keepArmed: false });
    stopKeepAlive();
    releaseWakeLock();
    updateAudioUi();
    return;
  }

  // Turn on immediately so the UI always reflects the tap, then unlock audio.
  state.audioEnabled = true;
  updateAudioUi();
  els.enableAudioBtn.disabled = true;
  try {
    await silentlyUnlockAudio();
    await startKeepAlive();
    await requestWakeLock();
    updateMediaSession("paused", "Athan — autoplay armed");
    checkPrayerAlarm();
    updateAudioUi();
  } catch (err) {
    state.audioEnabled = false;
    stopKeepAlive();
    releaseWakeLock();
    updateAudioUi();
    els.audioHint.textContent =
      "Could not arm autoplay. Tap Audio: Off / On again after interacting with the page.";
    console.warn(err);
  } finally {
    els.enableAudioBtn.disabled = false;
  }
}

async function refreshTimings({ silent = false } = {}) {
  if (!silent) setStatus("Loading prayer times…");
  try {
    await fetchTimings();
    renderDates();
    renderPrayers();
    updateCountdown();
    setStatus(`Times ready · ${state.location.label}`);
    els.metaNote.textContent = `Calculated with ${
      state.meta?.method?.name || "selected method"
    } for ${state.location.latitude.toFixed(4)}, ${state.location.longitude.toFixed(
      4
    )} (${state.location.timezone || "local zone"}). Matches IslamicFinder’s ISNA settings when method is ISNA.`;
    saveSettings();
  } catch (err) {
    setStatus("Could not load prayer times");
    els.audioHint.textContent = err.message || "Network error loading times.";
  }
}

function renderSuggestions(places, { loading = false } = {}) {
  els.suggestions.innerHTML = "";
  if (loading) {
    const li = document.createElement("li");
    li.className = "suggestions__hint";
    li.textContent = "Searching cities…";
    els.suggestions.appendChild(li);
    els.suggestions.hidden = false;
    return;
  }
  if (!places.length) {
    els.suggestions.hidden = true;
    return;
  }
  for (const place of places) {
    const li = document.createElement("li");
    const btn = document.createElement("button");
    btn.type = "button";
    btn.textContent = place.label;
    btn.addEventListener("click", async () => {
      state.location = place;
      els.locationInput.value = place.label;
      els.suggestions.hidden = true;
      await refreshTimings();
    });
    li.appendChild(btn);
    els.suggestions.appendChild(li);
  }
  els.suggestions.hidden = false;
}

async function runSearch({ quiet = false } = {}) {
  const query = els.locationInput.value.trim();
  if (query.length < 2) {
    els.suggestions.hidden = true;
    return;
  }
  const requestId = ++state.searchRequestId;
  if (!quiet) setStatus(`Searching for “${query}”…`);
  renderSuggestions([], { loading: true });
  try {
    const places = await searchPlaces(query);
    if (requestId !== state.searchRequestId) return;
    if (!places.length) {
      if (!quiet) setStatus("No matching places found");
      els.suggestions.hidden = true;
      return;
    }
    renderSuggestions(places);
    if (!quiet) setStatus(`${places.length} places found — pick one`);
  } catch (err) {
    if (requestId !== state.searchRequestId) return;
    if (!quiet) setStatus("Search failed");
    els.suggestions.hidden = true;
    console.warn(err);
  }
}

function scheduleAutocomplete() {
  clearTimeout(state.searchTimer);
  const query = els.locationInput.value.trim();
  if (query.length < 2) {
    els.suggestions.hidden = true;
    return;
  }
  state.searchTimer = setTimeout(() => {
    runSearch({ quiet: true });
  }, 280);
}

function bindUi() {
  fillSelect(
    els.adhanSelect,
    ADHANS,
    (a) => a.url,
    (a) => a.name,
    state.adhanUrl
  );
  fillSelect(
    els.fajrAdhanSelect,
    ADHANS,
    (a) => a.url,
    (a) => a.name,
    state.fajrAdhanUrl
  );
  fillSelect(
    els.methodSelect,
    METHODS,
    (m) => String(m.id),
    (m) => m.name,
    String(state.method)
  );

  els.schoolSelect.value = String(state.school);
  els.differentFajr.checked = state.differentFajr;
  els.showCountdown.checked = state.showCountdown;
  els.fajrAdhanRow.hidden = !state.differentFajr;
  els.locationInput.value = state.location.label;
  renderSecondaryAlerts();
  mountAdhanTransports();
  syncAudioSource(true);
  updateAudioUi();

  els.enableAudioBtn.addEventListener("click", toggleAudio);
  els.refreshBtn.addEventListener("click", () => refreshTimings());
  els.searchBtn.addEventListener("click", () => runSearch());
  els.locationInput.addEventListener("input", scheduleAutocomplete);
  els.locationInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      clearTimeout(state.searchTimer);
      runSearch();
    } else if (e.key === "Escape") {
      els.suggestions.hidden = true;
    }
  });
  els.locationInput.addEventListener("blur", () => {
    // Delay so suggestion clicks still register.
    setTimeout(() => {
      if (!els.suggestions.contains(document.activeElement)) {
        els.suggestions.hidden = true;
      }
    }, 180);
  });

  els.adhanSelect.addEventListener("change", () => {
    state.adhanUrl = els.adhanSelect.value;
    syncAudioSource(true);
    saveSettings();
  });

  els.fajrAdhanSelect.addEventListener("change", () => {
    state.fajrAdhanUrl = els.fajrAdhanSelect.value;
    saveSettings();
  });

  els.methodSelect.addEventListener("change", async () => {
    state.method = Number(els.methodSelect.value);
    await refreshTimings();
  });

  els.schoolSelect.addEventListener("change", async () => {
    state.school = Number(els.schoolSelect.value);
    await refreshTimings();
  });

  els.differentFajr.addEventListener("change", () => {
    state.differentFajr = els.differentFajr.checked;
    els.fajrAdhanRow.hidden = !state.differentFajr;
    saveSettings();
  });

  els.showCountdown.addEventListener("change", () => {
    state.showCountdown = els.showCountdown.checked;
    updateCountdown();
    saveSettings();
  });

  els.fullscreenBtn.addEventListener("click", async () => {
    try {
      if (!document.fullscreenElement) {
        await document.documentElement.requestFullscreen();
      } else {
        await document.exitFullscreen();
      }
    } catch (err) {
      console.warn(err);
    }
  });

  document.addEventListener("visibilitychange", async () => {
    if (document.visibilityState === "visible" && state.audioEnabled) {
      await requestWakeLock();
      await startKeepAlive();
    }
  });

  els.adhanAudio.addEventListener("ended", () => {
    updateMediaSession("stopped");
    if (state.previewId === "adhan" || state.previewId === "fajr-adhan") {
      setTransportActive(state.previewId, "stopped");
      state.previewId = null;
    }
    if (state.audioEnabled) startKeepAlive();
  });
  els.alarmAudio.addEventListener("ended", () => {
    // Loop handler for scheduled short alarms owns restart; previews end here.
    if (!state.alarmLoopHandler) {
      if (state.previewId?.startsWith("alarm-")) {
        setTransportActive(state.previewId, "stopped");
        state.previewId = null;
      }
      if (state.audioEnabled) startKeepAlive();
    }
  });

  bindMediaSessionHandlers();
}

async function init() {
  loadSettings();
  bindUi();
  await refreshTimings();

  setInterval(() => {
    updateLocalClock();
    updateCountdown();
    checkPrayerAlarm();
    renderPrayers();
  }, 1000);

  // Refresh timings around midnight local time.
  setInterval(() => {
    const p = getLocalParts();
    if (p.hour === 0 && p.minute === 0) {
      refreshTimings({ silent: true });
    }
  }, 30_000);
}

init();
