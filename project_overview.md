# Flutter Live Football Score & Streaming App - Project Overview

## Project Goal
To create a complete Flutter mobile application for live football scores and match streaming, similar to LiveScore app with added live streaming capabilities. The app will utilize API-Football for match data and YouTube Data API for live stream discovery.

## Technical Stack
- **Framework**: Flutter (latest stable)
- **State Management**: Riverpod
- **Architecture**: Clean Architecture (Data, Domain, Presentation layers)
- **HTTP Client**: Dio with interceptors
- **Local Storage**: Hive
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Video Player**: youtube_player_flutter
- **Ads**: google_mobile_ads (AdMob)

## Key Features
1.  **Live Scores**: Real-time updates, match details, lineups, stats.
2.  **Live Streaming**: Discovery and playback of legal YouTube live streams for matches.
3.  **Leagues & Standings**: Comprehensive data for major leagues.
4.  **Favorites System**: Follow specific teams and leagues.
5.  **Offline Support**: Caching strategies for offline access to recent data.
6.  **Notifications**: Push notifications for goals, match starts, etc.

## API & Keys (Placeholder)
-   **API-Football**: `https://v3.football.api-sports.io`
-   **YouTube Data API**: Google Cloud Console
-   **Firebase**: FCM & Analytics
-   **AdMob**: Ad Units for Banner, Interstitial, and Rewarded ads.

## Architecture
The project follows **Clean Architecture**:
-   **Presentation Layer**: Widgets, Providers, State Management (Riverpod).
-   **Domain Layer**: Entities, Use Cases, Repository Interfaces.
-   **Data Layer**: Models, Data Sources (Remote/Local), Repository Implementations.

## Implementation Phases
1.  **Phase 1**: Core setup, API integration, Home screen with live scores.
2.  **Phase 2**: Match detail, Fixtures screen, basic navigation.
3.  **Phase 3**: Leagues & standings, Favorites system.
4.  **Phase 4**: Live TV (YouTube integration).
5.  **Phase 5**: Notifications (FCM), Settings screen.
6.  **Phase 6**: AdMob integration, Caching optimization.
7.  **Phase 7**: Polish, testing, performance optimization.
