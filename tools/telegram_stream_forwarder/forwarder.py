"""
=============================================================================
LiveScore Pro - Automated Telegram Match Stream Forwarder & Rebrander
=============================================================================
This script monitors popular Telegram sports streaming channels, filters for
live match streams, strips competitor branding/ads, adds your LiveScore app
branding & download link, and posts the clean stream links directly to your
own Telegram channel.

Requirements:
    pip install telethon

Setup:
    1. Go to https://my.telegram.org and log in with your phone number.
    2. Click 'API development tools' and create an app (name it anything, e.g. 'LiveScoreStreamBot').
    3. Copy your API_ID and API_HASH below.
    4. Create your destination Telegram channel (e.g. @YourLiveScoreStreams).
    5. Add your Telegram account or a bot as an Administrator with 'Post Messages' permission.
    6. Run: python forwarder.py
=============================================================================
"""

import os
import re
import asyncio
from telethon import TelegramClient, events

# ─── 1. TELEGRAM API CREDENTIALS ─────────────────────────────────────────────
# Obtain these from https://my.telegram.org -> API development tools
API_ID = int(os.environ.get("TELEGRAM_API_ID", "12345678"))
API_HASH = os.environ.get("TELEGRAM_API_HASH", "your_api_hash_here")

# ─── 2. CHANNEL CONFIGURATION ────────────────────────────────────────────────
# Your destination channel (username with '@' or numerical channel ID):
DESTINATION_CHANNEL = os.environ.get("TELEGRAM_DEST_CHANNEL", "@YourLiveScoreStreams")

# Public/private source channels to monitor for live football stream links.
# You can use public handles (e.g. 'LiveSoccerStreams') or invite links.
SOURCE_CHANNELS = [
    "LiveFootballStreamsHD",
    "SoccerStreamsLive",
    "PremierLeagueStreamsLive",
    "UCL_Live_Streams",
    "FutbolEnVivoHDLinks",
    # Add more source channels here as you discover them
]

# ─── 3. BRANDING & PROMO FOOTER ──────────────────────────────────────────────
# This branding footer will be appended to every stream post in your channel:
APP_PROMO_FOOTER = (
    "\n\n━━━━━━━━━━━━━━━━━━━━━\n"
    "📲 *Live Scores & Real-Time Stats:*\n"
    "⚡ Download the *LiveScore Pro* App for instant goal alerts & live lineups!\n"
    "👉 [Download LiveScore Pro](https://play.google.com/store/apps/details?id=com.asdevelopments.livescore.livescore)\n"
    "💬 Join Community: @YourLiveScoreStreams"
)

# Competitor words/links to strip out
BLACKLIST_PATTERNS = [
    r"@[\w_]+",                         # Strip other channel @mentions
    r"t\.me\/(?!joinchat)[a-zA-Z0-9_+]+", # Strip other t.me links
    r"Join\s+our\s+channel[^\n]*",        # Strip competitor call-to-actions
    r"Subscribe\s+to[^\n]*",
    r"Sponsored\s+by[^\n]*",
    r"Bet\s+now[^\n]*",
]

# Keywords that indicate a message contains a live stream or match link
STREAM_KEYWORDS = [
    "stream", "live", "vs", "v/s", "kickoff", "link", "watch", "hd",
    "premier league", "champions league", "la liga", "serie a", "bundesliga",
    "chelsea", "arsenal", "liverpool", "manchester", "barcelona", "real madrid"
]

client = TelegramClient("livescore_forwarder_session", API_ID, API_HASH)

def clean_and_rebrand_text(original_text: str) -> str:
    """Strips competitor mentions and appends LiveScore branding."""
    if not original_text:
        return ""
    
    cleaned = original_text
    for pattern in BLACKLIST_PATTERNS:
        cleaned = re.sub(pattern, "", cleaned, flags=re.IGNORECASE)
    
    cleaned = cleaned.strip()
    return f"{cleaned}\n{APP_PROMO_FOOTER}"

@client.on(events.NewMessage(chats=SOURCE_CHANNELS))
async def handle_incoming_stream_message(event):
    message = event.message
    text = message.text or message.caption or ""
    
    # Check if message contains sports stream keywords
    has_keyword = any(kw in text.lower() for kw in STREAM_KEYWORDS)
    has_url = "http://" in text or "https://" in text
    
    if not (has_keyword and has_url):
        # Ignore non-stream or irrelevant chatter
        return

    print(f"[*] Live stream detected from source: {event.chat_id}")
    new_caption = clean_and_rebrand_text(text)

    try:
        if message.media and not message.web_preview:
            # Post media (image/banner) with rebranded caption
            await client.send_file(
                DESTINATION_CHANNEL,
                message.media,
                caption=new_caption,
                parse_mode="markdown"
            )
        else:
            # Post rebranded text message
            await client.send_message(
                DESTINATION_CHANNEL,
                new_caption,
                parse_mode="markdown",
                link_preview=True
            )
        print(f"[+] Successfully posted to {DESTINATION_CHANNEL}")
    except Exception as e:
        print(f"[!] Error forwarding message: {e}")

async def main():
    print("=" * 60)
    print(" LiveScore Pro - Telegram Stream Forwarder Bot Starting...")
    print(f" Destination Channel: {DESTINATION_CHANNEL}")
    print(f" Monitoring {len(SOURCE_CHANNELS)} Source Channels...")
    print("=" * 60)
    await client.start()
    print("[✓] Client authenticated. Listening for incoming match streams...")
    await client.run_until_disconnected()

if __name__ == "__main__":
    asyncio.run(main())
