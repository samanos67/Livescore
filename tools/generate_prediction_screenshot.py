"""
Generate Play Store screenshots for AI Match Prediction page
Supports:
- Phone: 768 x 1376 (08_screenshot_ai_predictions.jpg)
- Tablet 7-inch: 1200 x 1920 (tablet_7_05_ai_predictions.jpg)
- Tablet 10-inch: 1600 x 2560 (tablet_10_05_ai_predictions.jpg)
"""

import os
from PIL import Image, ImageDraw, ImageFont

def render_ui(width, height):
    scale = width / 768.0
    
    def sc(val):
        return int(val * scale)

    # Fonts
    f_path = "C:/Windows/Fonts/segoeui.ttf"
    fb_path = "C:/Windows/Fonts/segoeuib.ttf"
    
    font_status = ImageFont.truetype(fb_path, sc(13))
    font_appbar = ImageFont.truetype(fb_path, sc(18))
    font_hero_badge = ImageFont.truetype(fb_path, sc(10))
    font_hero_title = ImageFont.truetype(fb_path, sc(15))
    font_hero_sub = ImageFont.truetype(f_path, sc(12))
    font_card_head = ImageFont.truetype(fb_path, sc(13))
    font_conf_badge = ImageFont.truetype(fb_path, sc(11))
    font_team_name = ImageFont.truetype(fb_path, sc(15))
    font_score = ImageFont.truetype(fb_path, sc(22))
    font_xg = ImageFont.truetype(f_path, sc(11))
    font_prob = ImageFont.truetype(f_path, sc(11))
    font_prob_b = ImageFont.truetype(fb_path, sc(11))
    font_signals_head = ImageFont.truetype(fb_path, sc(12))
    font_bullet = ImageFont.truetype(f_path, sc(11))
    font_tactical_head = ImageFont.truetype(fb_path, sc(11))
    font_tactical_body = ImageFont.truetype(f_path, sc(11))
    font_badge = ImageFont.truetype(fb_path, sc(10))
    font_disc = ImageFont.truetype(f_path, sc(9))
    font_bottom_nav = ImageFont.truetype(fb_path, sc(10))

    im = Image.new("RGB", (width, height), (15, 19, 25))
    draw = ImageDraw.Draw(im)

    # 1. Status Bar
    draw.text((sc(24), sc(10)), "09:41", fill=(255, 255, 255), font=font_status)
    draw.text((width - sc(90), sc(10)), "5G  98%", fill=(220, 225, 230), font=font_status)

    # 2. App Bar
    appbar_y = sc(34)
    appbar_h = sc(54)
    draw.rectangle([0, appbar_y, width, appbar_y + appbar_h], fill=(27, 32, 42))
    draw.line([0, appbar_y + appbar_h, width, appbar_y + appbar_h], fill=(35, 42, 55), width=sc(1))
    
    # App Bar Content
    # Green icon pill
    draw.rounded_rectangle([sc(20), appbar_y + sc(10), sc(54), appbar_y + sc(44)], radius=sc(8), fill=(0, 208, 132, 40), outline=(0, 208, 132))
    draw.text((sc(27), appbar_y + sc(14)), "[AI]", fill=(0, 208, 132), font=font_conf_badge)
    draw.text((sc(64), appbar_y + sc(16)), "AI Match Forecasts", fill=(255, 255, 255), font=font_appbar)
    
    # Refresh pill on right
    draw.rounded_rectangle([width - sc(50), appbar_y + sc(12), width - sc(20), appbar_y + sc(42)], radius=sc(15), fill=(24, 30, 40), outline=(0, 208, 132))
    draw.text((width - sc(42), appbar_y + sc(16)), "R", fill=(0, 208, 132), font=font_conf_badge)

    # 3. Hero Highlight Banner
    hero_y = appbar_y + appbar_h + sc(14)
    hero_h = sc(86)
    hero_rect = [sc(16), hero_y, width - sc(16), hero_y + hero_h]
    draw.rounded_rectangle(hero_rect, radius=sc(14), fill=(25, 34, 48), outline=(0, 208, 132), width=sc(1))
    
    # Hero content
    draw.rounded_rectangle([sc(28), hero_y + sc(10), sc(140), hero_y + sc(28)], radius=sc(5), fill=(0, 208, 132))
    draw.text((sc(33), hero_y + sc(13)), "TODAY'S HIGHLIGHTS", fill=(10, 15, 20), font=font_hero_badge)
    draw.text((width - sc(150), hero_y + sc(13)), "15 Forecasts Ready", fill=(0, 208, 132), font=font_conf_badge)
    
    draw.text((sc(28), hero_y + sc(36)), "Objective Match Signals & Tactical Models", fill=(255, 255, 255), font=font_hero_title)
    draw.text((sc(28), hero_y + sc(58)), "Powered by expected goals (xG), form weighting, and Google Gemini AI.", fill=(160, 170, 185), font=font_hero_sub)

    # 4. Prediction Card 1 (Arsenal vs Chelsea - Expanded)
    c1_y = hero_y + hero_h + sc(14)
    c1_h = sc(480)
    c1_rect = [sc(16), c1_y, width - sc(16), c1_y + c1_h]
    draw.rounded_rectangle(c1_rect, radius=sc(16), fill=(27, 32, 42), outline=(0, 208, 132), width=sc(2))

    # Card 1 Header
    draw.rounded_rectangle([sc(16), c1_y, width - sc(16), c1_y + sc(42)], radius=sc(16), fill=(36, 43, 56))
    draw.rectangle([sc(16), c1_y + sc(26), width - sc(16), c1_y + sc(42)], fill=(36, 43, 56))
    
    draw.rounded_rectangle([sc(28), c1_y + sc(9), sc(52), c1_y + sc(33)], radius=sc(6), fill=(0, 208, 132, 50))
    draw.text((sc(33), c1_y + sc(13)), "AI", fill=(0, 208, 132), font=font_conf_badge)
    draw.text((sc(60), c1_y + sc(12)), "PREMIER LEAGUE MATCH FORECAST", fill=(255, 255, 255), font=font_card_head)
    
    # Confidence badge
    draw.rounded_rectangle([width - sc(125), c1_y + sc(9), width - sc(28), c1_y + sc(33)], radius=sc(12), fill=(0, 208, 132, 40), outline=(0, 208, 132))
    draw.text((width - sc(115), c1_y + sc(13)), "78% Confidence", fill=(0, 208, 132), font=font_conf_badge)

    # Scoreline Row
    score_y = c1_y + sc(54)
    draw.text((sc(36), score_y + sc(10)), "Arsenal FC", fill=(255, 255, 255), font=font_team_name)
    
    # Score pill
    draw.rounded_rectangle([sc(335), score_y, sc(433), score_y + sc(42)], radius=sc(10), fill=(15, 19, 25), outline=(0, 208, 132), width=sc(2))
    draw.text((sc(356), score_y + sc(5)), "2 - 1", fill=(0, 208, 132), font=font_score)

    draw.text((width - sc(130), score_y + sc(10)), "Chelsea FC", fill=(255, 255, 255), font=font_team_name)

    # xG line
    draw.text((sc(210), score_y + sc(48)), "Expected Goals (xG):  Arsenal 1.82   -   Chelsea 0.94", fill=(160, 170, 185), font=font_xg)

    # Probability Bar
    bar_y = score_y + sc(72)
    bar_w = width - sc(64)
    bar_h = sc(12)
    hw_w = int(bar_w * 0.65)
    dr_w = int(bar_w * 0.20)
    aw_w = bar_w - hw_w - dr_w
    
    bx = sc(32)
    draw.rounded_rectangle([bx, bar_y, bx + bar_w, bar_y + bar_h], radius=sc(6), fill=(50, 60, 75))
    draw.rectangle([bx, bar_y, bx + hw_w, bar_y + bar_h], fill=(0, 208, 132))
    draw.rectangle([bx + hw_w, bar_y, bx + hw_w + dr_w, bar_y + bar_h], fill=(245, 158, 11))
    draw.rectangle([bx + hw_w + dr_w, bar_y, bx + bar_w, bar_y + bar_h], fill=(59, 130, 246))

    # Probability Labels
    prob_lbl_y = bar_y + sc(18)
    draw.ellipse([sc(32), prob_lbl_y + sc(3), sc(40), prob_lbl_y + sc(11)], fill=(0, 208, 132))
    draw.text((sc(46), prob_lbl_y), "Arsenal Win: 65%", fill=(0, 208, 132), font=font_prob_b)

    draw.ellipse([sc(320), prob_lbl_y + sc(3), sc(328), prob_lbl_y + sc(11)], fill=(245, 158, 11))
    draw.text((sc(334), prob_lbl_y), "Draw: 20%", fill=(245, 158, 11), font=font_prob_b)

    draw.ellipse([width - sc(145), prob_lbl_y + sc(3), width - sc(137), prob_lbl_y + sc(11)], fill=(59, 130, 246))
    draw.text((width - sc(131), prob_lbl_y), "Chelsea Win: 15%", fill=(59, 130, 246), font=font_prob_b)

    # Divider
    draw.line([sc(32), prob_lbl_y + sc(22), width - sc(32), prob_lbl_y + sc(22)], fill=(44, 52, 68), width=sc(1))

    # Key Signals
    sig_y = prob_lbl_y + sc(30)
    draw.text((sc(32), sig_y), "Key Statistical Signals", fill=(255, 255, 255), font=font_signals_head)
    
    b1_y = sig_y + sc(20)
    draw.text((sc(32), b1_y), "* Arsenal holding superior home conversion rate (unbeaten last 5 at Emirates)", fill=(210, 220, 230), font=font_bullet)
    draw.text((sc(32), b1_y + sc(18)), "* Chelsea conceding an average of 1.4 goals on recent away travels", fill=(210, 220, 230), font=font_bullet)
    draw.text((sc(32), b1_y + sc(36)), "* High-tempo match model projects territorial superiority in final third", fill=(210, 220, 230), font=font_bullet)

    # Tactical Breakdown Box (Unlocked)
    box_y = b1_y + sc(58)
    box_h = sc(68)
    draw.rounded_rectangle([sc(32), box_y, width - sc(32), box_y + box_h], radius=sc(10), fill=(19, 23, 32), outline=(0, 208, 132), width=sc(1))
    draw.text((sc(44), box_y + sc(8)), "TACTICAL BREAKDOWN (UNLOCKED)", fill=(0, 208, 132), font=font_tactical_head)
    draw.text((sc(44), box_y + sc(26)), "Arsenal are projected to dictate tempo through high pressing in final third.", fill=(220, 225, 235), font=font_tactical_body)
    draw.text((sc(44), box_y + sc(44)), "Chelsea must stay disciplined in a deep block and rely on counter-attacks through width.", fill=(180, 190, 205), font=font_tactical_body)

    # Badges Row
    badge_y = box_y + box_h + sc(12)
    # Badge 1
    draw.rounded_rectangle([sc(32), badge_y, sc(180), badge_y + sc(24)], radius=sc(12), fill=(0, 208, 132, 35), outline=(0, 208, 132))
    draw.text((sc(42), badge_y + sc(5)), "Both Teams Score: YES", fill=(0, 208, 132), font=font_badge)

    # Badge 2
    draw.rounded_rectangle([sc(190), badge_y, sc(325), badge_y + sc(24)], radius=sc(12), fill=(0, 208, 132, 35), outline=(0, 208, 132))
    draw.text((sc(202), badge_y + sc(5)), "Over 2.5 Goals: YES", fill=(0, 208, 132), font=font_badge)

    # Badge 3
    draw.rounded_rectangle([sc(335), badge_y, sc(480), badge_y + sc(24)], radius=sc(12), fill=(59, 130, 246, 35), outline=(59, 130, 246))
    draw.text((sc(345), badge_y + sc(5)), "Gemini AI Verified Model", fill=(96, 165, 250), font=font_badge)

    # Card 1 Disclaimer
    draw.text((sc(140), c1_y + c1_h - sc(18)), "Predictions are AI-generated statistical estimates for entertainment purposes only.", fill=(120, 130, 145), font=font_disc)

    # 5. Prediction Card 2 (Real Madrid vs Barcelona - Peek)
    c2_y = c1_y + c1_h + sc(14)
    c2_h = sc(220)
    c2_rect = [sc(16), c2_y, width - sc(16), c2_y + c2_h]
    draw.rounded_rectangle(c2_rect, radius=sc(16), fill=(27, 32, 42), outline=(44, 52, 68), width=sc(1))

    # Card 2 Header
    draw.rounded_rectangle([sc(16), c2_y, width - sc(16), c2_y + sc(42)], radius=sc(16), fill=(36, 43, 56))
    draw.rectangle([sc(16), c2_y + sc(26), width - sc(16), c2_y + sc(42)], fill=(36, 43, 56))
    draw.text((sc(32), c2_y + sc(12)), "EL CLASICO - LA LIGA FORECAST", fill=(255, 255, 255), font=font_card_head)
    
    draw.rounded_rectangle([width - sc(125), c2_y + sc(9), width - sc(28), c2_y + sc(33)], radius=sc(12), fill=(0, 208, 132, 40), outline=(0, 208, 132))
    draw.text((width - sc(115), c2_y + sc(13)), "84% Confidence", fill=(0, 208, 132), font=font_conf_badge)

    # Scoreline Row 2
    s2_y = c2_y + sc(52)
    draw.text((sc(36), s2_y + sc(8)), "Real Madrid", fill=(255, 255, 255), font=font_team_name)
    draw.rounded_rectangle([sc(335), s2_y, sc(433), s2_y + sc(38)], radius=sc(10), fill=(15, 19, 25), outline=(0, 208, 132), width=sc(2))
    draw.text((sc(356), s2_y + sc(4)), "3 - 2", fill=(0, 208, 132), font=font_score)
    draw.text((width - sc(130), s2_y + sc(8)), "Barcelona", fill=(255, 255, 255), font=font_team_name)

    # Watch Video to Unlock CTA
    btn_y = s2_y + sc(52)
    draw.rounded_rectangle([sc(32), btn_y, width - sc(32), btn_y + sc(42)], radius=sc(10), fill=(0, 208, 132))
    draw.text((sc(220), btn_y + sc(12)), "WATCH VIDEO TO UNLOCK FULL TACTICS (FREE)", fill=(10, 15, 20), font=font_hero_title)

    # 6. Bottom Navigation Bar
    nav_h = sc(64)
    nav_y = height - nav_h
    draw.rectangle([0, nav_y, width, height], fill=(27, 32, 42))
    draw.line([0, nav_y, width, nav_y], fill=(44, 52, 68), width=sc(1))

    # Nav Items
    items = ["Scores", "News", "Fixtures", "AI Picks", "More"]
    item_w = width / len(items)
    for idx, name in enumerate(items):
        cx = int(idx * item_w + item_w / 2)
        is_active = (name == "AI Picks")
        col = (0, 208, 132) if is_active else (140, 150, 165)
        # Small indicator circle on top of active item
        if is_active:
            draw.ellipse([cx - sc(14), nav_y + sc(10), cx + sc(14), nav_y + sc(38)], fill=(0, 208, 132, 40), outline=(0, 208, 132))
            draw.text((cx - sc(6), nav_y + sc(16)), "AI", fill=(0, 208, 132), font=font_bottom_nav)
        else:
            draw.text((cx - sc(4), nav_y + sc(16)), "*", fill=col, font=font_bottom_nav)
        draw.text((cx - sc(20), nav_y + sc(44)), name, fill=col, font=font_bottom_nav)

    return im

def main():
    base_dir = "C:/Users/Asdevelopments LTD/Desktop/apps/livescore/playstore_assets"
    
    # 1. Phone: 768 x 1376
    im_phone = render_ui(768, 1376)
    out_phone = os.path.join(base_dir, "08_screenshot_ai_predictions.jpg")
    im_phone.save(out_phone, "JPEG", quality=95)
    print(f"Generated phone screenshot: {out_phone} (768 x 1376)")

    # 2. Tablet 7-inch: 1200 x 1920
    im_tab7 = render_ui(1200, 1920)
    out_tab7 = os.path.join(base_dir, "tablet_7inch", "tablet_7_05_ai_predictions.jpg")
    im_tab7.save(out_tab7, "JPEG", quality=95)
    print(f"Generated 7-inch tablet screenshot: {out_tab7} (1200 x 1920)")

    # 3. Tablet 10-inch: 1600 x 2560
    im_tab10 = render_ui(1600, 2560)
    out_tab10 = os.path.join(base_dir, "tablet_10inch", "tablet_10_05_ai_predictions.jpg")
    im_tab10.save(out_tab10, "JPEG", quality=95)
    print(f"Generated 10-inch tablet screenshot: {out_tab10} (1600 x 2560)")

if __name__ == "__main__":
    main()
