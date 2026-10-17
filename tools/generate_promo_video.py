"""
=============================================================================
LiveScore Pro - Google Play Store Commercial Promo Video Generator
=============================================================================
Generates a 1080p 60fps / 30fps Full HD commercial-grade promo video (.mp4)
from Play Store screenshots with smooth camera motion, cinematic title cards,
stadium lighting backgrounds, and seamless cross-dissolve transitions.
=============================================================================
"""

import os
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import imageio

OUTPUT_WIDTH = 1920
OUTPUT_HEIGHT = 1080
FPS = 30
TRANSITION_FRAMES = 12  # ~0.4s crossfade

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "playstore_assets")
OUTPUT_PATH = os.path.join(ASSETS_DIR, "playstore_promo_video.mp4")

# Storyboard configuration: (Image filename, Header, Subtitle, Duration in seconds, is_fullscreen)
SCENES = [
    (
        "01_feature_graphic_1024x500.jpg",
        "LIVESCORE PRO",
        "Real-Time 4-Second In-Play Live Scores",
        3.5,
        True
    ),
    (
        "02_screenshot_livescores.jpg",
        "LIGHTNING FAST LIVE SCORES",
        "Instant Goal Alerts & Real-Time Minute Clocks",
        3.5,
        False
    ),
    (
        "03_screenshot_lineups_pitch.jpg",
        "TACTICAL FORMATIONS & LINEUPS",
        "Official 4-3-3 Pitch Boards & Player Ratings",
        3.5,
        False
    ),
    (
        "04_screenshot_match_stats.jpg",
        "DEEP MATCH STATS & MOMENTUM",
        "Possession, Expected Goals (xG) & Attack Charts",
        3.5,
        False
    ),
    (
        "05_screenshot_favorite_clubs.jpg",
        "FOLLOW YOUR FAVOURITE CLUBS",
        "Custom Matchday Alerts & Kickoff Reminders",
        3.0,
        False
    ),
    (
        "06_screenshot_breaking_news.jpg",
        "BREAKING FOOTBALL NEWS",
        "World Headlines, Exclusive Transfer Rumors & Feeds",
        3.0,
        False
    ),
    (
        "07_screenshot_livetv_streams.jpg",
        "LIVE MATCH STREAMS & TV GUIDE",
        "Plex TV, Pluto Golazo & Telegram Live Community",
        3.5,
        False
    ),
    (
        "01_feature_graphic_1024x500.jpg",
        "DOWNLOAD LIVESCORE PRO TODAY",
        "Free on Google Play Store • Join Millions of Fans",
        3.5,
        True
    ),
]

def get_font(size: int, bold: bool = False):
    """Attempts to load a clean modern font or falls back safely."""
    font_names = [
        "arialbd.ttf" if bold else "arial.ttf",
        "segoeuib.ttf" if bold else "segoeui.ttf",
        "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf",
    ]
    for fn in font_names:
        try:
            return ImageFont.truetype(fn, size)
        except Exception:
            continue
    return ImageFont.load_default()

def create_stadium_background(width=OUTPUT_WIDTH, height=OUTPUT_HEIGHT):
    """Creates a sleek, dark stadium atmosphere background with neon green energy glow."""
    bg = Image.new("RGBA", (width, height), (6, 12, 18, 255))
    draw = ImageDraw.Draw(bg)
    
    # Top glow
    for r in range(200, 0, -10):
        alpha = int(40 * (1 - r / 200))
        draw.ellipse(
            (width // 2 - r * 4, -r, width // 2 + r * 4, r * 2),
            fill=(0, 230, 118, alpha)
        )
    return bg

def render_frame(img_source: Image.Image, title: str, subtitle: str, progress: float, is_fullscreen: bool, bg_template: Image.Image) -> Image.Image:
    """Renders a single video frame with zoom/pan and typography."""
    frame = bg_template.copy()
    draw = ImageDraw.Draw(frame)

    if is_fullscreen:
        # Fullscreen feature graphic with subtle Ken Burns zoom (1.00 -> 1.06)
        scale = 1.0 + 0.06 * progress
        w = int(OUTPUT_WIDTH * scale)
        h = int(OUTPUT_HEIGHT * scale)
        scaled = img_source.resize((w, h), Image.Resampling.LANCZOS)
        
        # Center crop
        left = (w - OUTPUT_WIDTH) // 2
        top = (h - OUTPUT_HEIGHT) // 2
        cropped = scaled.crop((left, top, left + OUTPUT_WIDTH, top + OUTPUT_HEIGHT))
        frame.paste(cropped, (0, 0))

        # Bottom gradient overlay for text readability
        overlay = Image.new("RGBA", (OUTPUT_WIDTH, 260), (0, 0, 0, 0))
        ov_draw = ImageDraw.Draw(overlay)
        for y in range(260):
            a = int(220 * (y / 260))
            ov_draw.line([(0, y), (OUTPUT_WIDTH, y)], fill=(4, 8, 12, a))
        frame.paste(overlay, (0, OUTPUT_HEIGHT - 260), overlay)

        # Title and subtitle overlay
        f_title = get_font(52, bold=True)
        f_sub = get_font(24, bold=False)

        draw.text((OUTPUT_WIDTH // 2, OUTPUT_HEIGHT - 170), title, font=f_title, fill=(255, 255, 255), anchor="mm")
        draw.text((OUTPUT_WIDTH // 2, OUTPUT_HEIGHT - 110), subtitle, font=f_sub, fill=(0, 230, 118), anchor="mm")
    else:
        # Blurred background of the screenshot itself for high-end look
        thumb_bg = img_source.resize((OUTPUT_WIDTH // 8, OUTPUT_HEIGHT // 8), Image.Resampling.BILINEAR)
        thumb_bg = thumb_bg.filter(ImageFilter.GaussianBlur(radius=8))
        thumb_bg = thumb_bg.resize((OUTPUT_WIDTH, OUTPUT_HEIGHT), Image.Resampling.LANCZOS)
        
        # Dark tint over blurred background
        tint = Image.new("RGBA", (OUTPUT_WIDTH, OUTPUT_HEIGHT), (4, 10, 16, 200))
        thumb_bg = Image.alpha_composite(thumb_bg.convert("RGBA"), tint)
        frame.paste(thumb_bg, (0, 0))

        # Left Column: Marketing Headline
        f_badge = get_font(18, bold=True)
        f_title = get_font(50, bold=True)
        f_sub = get_font(22, bold=False)

        # Badge pill
        badge_text = "LIVESCORE PRO"
        draw.rounded_rectangle((100, 320, 290, 360), radius=20, fill=(0, 230, 118, 30), outline=(0, 230, 118, 180), width=2)
        draw.text((195, 340), badge_text, font=f_badge, fill=(0, 230, 118), anchor="mm")

        # Split title if too long
        title_lines = [title]
        if len(title) > 24 and " & " in title:
            title_lines = title.split(" & ")
            title_lines[0] = title_lines[0] + " &"

        y_offset = 390
        for line in title_lines:
            draw.text((100, y_offset), line, font=f_title, fill=(255, 255, 255))
            y_offset += 65

        # Subtitle
        draw.text((100, y_offset + 15), subtitle, font=f_sub, fill=(160, 180, 200))

        # Right Column: Phone Mockup with subtle vertical floating animation
        phone_h = 960
        aspect = img_source.width / img_source.height
        phone_w = int(phone_h * aspect)

        # Floating motion: smooth sine-like motion
        float_y = int(np.sin(progress * np.pi) * 12)
        phone_top = (OUTPUT_HEIGHT - phone_h) // 2 + float_y
        phone_left = OUTPUT_WIDTH - phone_w - 140

        # Subtle Ken burns on screenshot
        scale = 1.0 + 0.03 * progress
        cur_w = int(phone_w * scale)
        cur_h = int(phone_h * scale)
        scaled_phone = img_source.resize((cur_w, cur_h), Image.Resampling.LANCZOS)
        
        # Crop back to phone bounds
        c_left = (cur_w - phone_w) // 2
        c_top = (cur_h - phone_h) // 2
        cropped_phone = scaled_phone.crop((c_left, c_top, c_left + phone_w, c_top + phone_h))

        # Add rounded corners & drop shadow
        mask = Image.new("L", (phone_w, phone_h), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.rounded_rectangle((0, 0, phone_w, phone_h), radius=36, fill=255)

        # Shadow
        shadow = Image.new("RGBA", (phone_w + 40, phone_h + 40), (0, 0, 0, 0))
        sh_draw = ImageDraw.Draw(shadow)
        sh_draw.rounded_rectangle((20, 20, phone_w + 20, phone_h + 20), radius=38, fill=(0, 0, 0, 140))
        shadow = shadow.filter(ImageFilter.GaussianBlur(radius=15))
        frame.paste(shadow, (phone_left - 20, phone_top - 20), shadow)

        # Paste phone
        frame.paste(cropped_phone, (phone_left, phone_top), mask)

        # Outer border around phone
        border_overlay = Image.new("RGBA", (phone_w, phone_h), (0, 0, 0, 0))
        b_draw = ImageDraw.Draw(border_overlay)
        b_draw.rounded_rectangle((0, 0, phone_w - 1, phone_h - 1), radius=36, outline=(0, 230, 118, 120), width=3)
        frame.paste(border_overlay, (phone_left, phone_top), border_overlay)

    return frame.convert("RGB")

def build_promo_video():
    print("=" * 60)
    print(" LiveScore Pro - Play Store Promo Video Generator")
    print(f" Output Video: {OUTPUT_PATH}")
    print(f" Resolution: {OUTPUT_WIDTH}x{OUTPUT_HEIGHT} @ {FPS} fps")
    print("=" * 60)

    bg_template = create_stadium_background()
    writer = imageio.get_writer(
        OUTPUT_PATH,
        fps=FPS,
        codec="libx264",
        quality=8,
        pixelformat="yuv420p",
        macro_block_size=16
    )

    previous_scene_last_frame = None

    for idx, (img_name, title, subtitle, duration, is_fullscreen) in enumerate(SCENES):
        img_path = os.path.join(ASSETS_DIR, img_name)
        if not os.path.exists(img_path):
            print(f"[!] Warning: {img_path} not found, skipping scene {idx + 1}")
            continue

        print(f"[*] Rendering Scene {idx + 1}/{len(SCENES)}: '{title}' ({duration}s)...")
        src_img = Image.open(img_path).convert("RGBA")
        num_frames = int(duration * FPS)

        for f in range(num_frames):
            prog = f / max(1, num_frames - 1)
            frame_img = render_frame(src_img, title, subtitle, prog, is_fullscreen, bg_template)
            frame_np = np.array(frame_img)

            # Apply cross-dissolve transition from previous scene
            if idx > 0 and f < TRANSITION_FRAMES and previous_scene_last_frame is not None:
                alpha = f / TRANSITION_FRAMES
                blended = (previous_scene_last_frame * (1.0 - alpha) + frame_np * alpha).astype(np.uint8)
                writer.append_data(blended)
            else:
                writer.append_data(frame_np)

            if f == num_frames - 1:
                previous_scene_last_frame = frame_np.copy()

    writer.close()
    file_size_mb = os.path.getsize(OUTPUT_PATH) / (1024 * 1024)
    print("=" * 60)
    print("[SUCCESS] PROMO VIDEO SUCCESSFULLY CREATED!")
    print(f"    File: {OUTPUT_PATH}")
    print(f"    Size: {file_size_mb:.2f} MB")
    print("=" * 60)

if __name__ == "__main__":
    build_promo_video()
