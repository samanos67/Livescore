# ⚽ LiveScore Pro: Telegram Live Match Streams & Community Guide

This guide details how to find top Telegram football streaming channels, set up your own branded Telegram community, and automate match stream links directly into your channel to drive traffic to your LiveScore app.

---

## 1. Why a Telegram Channel is a Game Changer for Your App

1. **Google Play Store & AdMob Protection:**
   - Google Play policy strictly prohibits embedding unauthorized video streams directly inside the Android APK.
   - However, providing a button that says **"Join our Live Sports Community on Telegram"** is **100% compliant** with Google Play and AdMob policies. The app acts solely as a live score, stats, and community hub.

2. **Audience Ownership & Daily Engagement:**
   - Telegram notifications have an open rate above 80%. When a big match is about to start (e.g. Arsenal vs Chelsea), you can broadcast to thousands of fans at once.
   - Every post includes your download link, driving continuous app downloads and high eCPM ad impressions.

---

## 2. How to Find Active Football Streaming Channels on Telegram

Because streaming channels occasionally change usernames or get reported, static links expire. The best approach is to search using the top Telegram search tools and directory databases:

### A. Telegram In-App Search Keywords
Open Telegram and search for:
- `Football Live Streams HD`
- `Soccer Streams Links`
- `Premier League Live Stream`
- `Champions League HD`
- `Futbol En Vivo Links` *(Spanish feeds often have the highest uptime and cleanest M3U8 players)*
- `Yalla Shoot Live` / `Koora Live` *(Arabic sports feeds)*

### B. Telegram Channel Directories
Use these specialized directories to find channels with the highest subscriber count and active matchday posts:
1. **[TGStat Sports Category](https://tgstat.com/category/sports):**
   - Filter by Category: **Sports**.
   - Sort by **Subscribers** or **Reach per post**.
2. **[TLGRM Sports Directory](https://tlgrm.eu/channels/sports)**
3. **[Telemetr.io](https://telemetr.io):** Search "Live Streams" or "Football".

### C. What to Look For in a Source Channel
- They post match announcements **15 to 30 minutes before kickoff**.
- They provide 2–3 working web links (e.g., player mirrors or stream servers).
- They post instant video goal replays during the game.

---

## 3. Step-by-Step: Creating Your Own Channel

### Step 1: Create the Telegram Channel
1. Open Telegram on your phone or desktop.
2. Tap the **Compose** button (pencil icon) -> **New Channel**.
3. **Channel Name:** e.g. `LiveScore Pro - Live Streams & Goals` or `LiveScore Official Community`.
4. **Channel Type:** **Public** (so anyone can find and join it without needing manual admin approval).
5. **Set Permanent Public Link:** e.g. `t.me/livescore_official_streams` (or your chosen brand handle).

### Step 2: Channel Branding
- **Profile Picture:** Use `assets/images/app_logo.png` from this project.
- **Description / Bio:**
  > ⚽ Official LiveScore Community!
  > • Daily Match Schedules & Fixtures
  > • HD Live Match Stream Links
  > • Instant Goal Replays & Highlights
  > • Real-time Lineups & Statistics
  > 📲 Download LiveScore Pro Android App:
  > https://play.google.com/store/apps/details?id=com.asdevelopments.livescore.livescore

### Step 3: Matchday Post Template (Manual Posting)
If posting manually, use this clean, professional format:

```text
🔥 MATCHDAY LIVE: Premier League
⚽ Arsenal vs Chelsea
⏰ Kickoff: 20:00 GMT
🏟️ Emirates Stadium

📺 STREAM SERVERS:
👉 Server 1 (HD English): https://...
👉 Server 2 (Mobile Low Data): https://...
👉 Server 3 (Backup / Replays): https://...

⚡ Track real-time live scores, lineups, player ratings & match events:
📲 Open LiveScore Pro App: https://play.google.com/store/apps/details?id=com.asdevelopments.livescore.livescore
```

---

## 4. Automated Stream Forwarder (Hands-Free Python Bot)

Instead of manually checking channels before every game, use the included Python script: `forwarder.py`.

### How it Works:
1. It listens to your designated source channels in real-time.
2. When a channel posts a live match stream link, it intercepts the message.
3. It **strips out competitor ads, sponsor links, and watermarks**.
4. It **attaches your LiveScore app branding and download link**.
5. It posts the cleaned stream message into **your** Telegram channel automatically!

### Quick Setup:
1. Install Telethon:
   ```bash
   pip install -r requirements.txt
   ```
2. Get your free Telegram API credentials:
   - Visit [my.telegram.org](https://my.telegram.org) and log in.
   - Click **API development tools** and create an app.
   - Copy your `API_ID` and `API_HASH`.
3. Open `forwarder.py` and insert your credentials:
   ```python
   API_ID = 12345678
   API_HASH = "your_api_hash_here"
   DESTINATION_CHANNEL = "@your_channel_handle"
   ```
4. Run the script:
   ```bash
   python forwarder.py
   ```

---

## 5. Connecting Your Telegram Channel to the LiveScore App

The app is already set up to launch your channel across multiple screens:
- **Live TV Screen:** The top hero banner features a one-tap **"Join Telegram Stream Channel"** button.
- **Video Player Screen:** Includes a dedicated banner card for matchday stream links.
- **More Screen:** Includes a **"Telegram Stream Channel"** tile with a one-tap `JOIN` button.

### To Change the Telegram URL:
Open `lib/core/constants/api_constants.dart` and update line 23:
```dart
static const String telegramChannelUrl = 'https://t.me/YOUR_NEW_CHANNEL_HANDLE';
```
The app will automatically point all buttons to your real Telegram channel!
