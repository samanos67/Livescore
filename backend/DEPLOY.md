# Deploy to Render - Step by Step

## Step 1: Push to GitHub

The backend lives in: `livescore/backend/`

You need to push ONLY the backend folder to GitHub (or push the whole repo, that is fine too).

```bash
# If you already have a GitHub repo for livescore:
git add backend/
git commit -m "Add Node.js caching proxy backend"
git push

# If starting fresh:
# 1. Go to github.com → New Repository → "livescore-backend"
# 2. Clone it, copy the backend/ folder contents into it, push
```

## Step 2: Deploy on Render

1. Go to https://render.com → Sign Up (use GitHub login)
2. Click **"New +"** → **"Web Service"**
3. Connect your GitHub repo
4. Fill in:
   - **Name**: `livescore-backend`
   - **Root Directory**: `backend` (if you pushed the whole livescore repo)
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: `Free`
5. Click **"Advanced"** → Add Environment Variables:
   | Key | Value |
   |---|---|
   | `FOOTBALL_DATA_API_KEY` | `e66fb7e9c7314d7b87075db92962a110` |
   | `API_FOOTBALL_KEY` | `8698999c8ac04f490232ebc80f1971fe` |
   | `SELF_PING_URL` | (leave blank for now, set after deploy) |
6. Click **"Create Web Service"**
7. Wait ~3 minutes for first deploy

## Step 3: Get Your Render URL

After deploy, Render gives you a URL like:
```
https://livescore-backend-xxxx.onrender.com
```

## Step 4: Update SELF_PING_URL

Go to Render → Your Service → Environment:
- Set `SELF_PING_URL` = `https://livescore-backend-xxxx.onrender.com`
- Click "Save Changes" → service auto-restarts

## Step 5: Set Up UptimeRobot

1. Go to https://uptimerobot.com → Sign Up (free)
2. **Add New Monitor**:
   - Monitor Type: `HTTP(s)`
   - Friendly Name: `LiveScore Backend`
   - URL: `https://livescore-backend-xxxx.onrender.com/health`
   - Monitoring Interval: `5 minutes`
3. Click **"Create Monitor"**

## Step 6: Set Up cron-job.org (Football-hours only)

1. Go to https://cron-job.org → Sign Up (free)
2. Create Job:
   - URL: `https://livescore-backend-xxxx.onrender.com/health`
   - Schedule: Custom cron → `*/5 10-23 * * *`
   - (Every 5 minutes, between 10am and 11:59pm UTC)
3. Save

## Step 7: Update Flutter App

In `lib/core/constants/api_constants.dart`, change:

```dart
// FROM (local/emulator):
static const String backendUrl = 'http://10.0.2.2:3000';

// TO (production Render URL):
static const String backendUrl = 'https://livescore-backend-xxxx.onrender.com';
```

Then rebuild the APK and done!

## Testing Your Deployment

Visit these URLs in a browser to verify:
- `https://your-url.onrender.com/health` → should show `{"status":"ok"}`
- `https://your-url.onrender.com/fixtures/live` → live matches
- `https://your-url.onrender.com/standings/39/2024` → Premier League table
