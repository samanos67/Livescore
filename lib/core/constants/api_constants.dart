class ApiConstants {
  // ─── Backend Proxy ──────────────────────────────────────────────────────────
  // Change this to your Render URL after deployment:
  //   e.g. 'https://livescore-backend.onrender.com'
  // For local testing, use 'http://10.0.2.2:3000' (Android emulator)
  // or 'http://<YOUR_LOCAL_IP>:3000' (physical device on same Wi-Fi)
  static const String backendUrl = 'https://livescore-backend-ju3x.onrender.com';

  // ─── YouTube (still called directly, no quota concern) ───────────────────
  static const String youtubeBaseUrl = 'https://www.googleapis.com/youtube/v3';
  static const String youtubeApiKey = 'AIzaSyA1D3kBxN8i4pkom9h1hhAGigp7bhkkPCo';

  // ─── League IDs (API-Football format — backend maps these internally) ───────
  static const int premierLeagueId   = 39;
  static const int laLigaId          = 140;
  static const int serieAId          = 135;
  static const int bundesligaId      = 78;
  static const int ligue1Id          = 61;
  static const int championsLeagueId = 2;
  static const int season            = 2024;
}
