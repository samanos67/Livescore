require('dotenv').config();
const express   = require('express');
const cors      = require('cors');
const axios     = require('axios');
const NodeCache = require('node-cache');
const RSSParser = require('rss-parser');

const app    = express();
const PORT   = process.env.PORT || 3000;
const parser = new RSSParser({ timeout: 10000 });

// ─── API Keys ─────────────────────────────────────────────────────────────────
const FOOTBALL_DATA_KEY = process.env.FOOTBALL_DATA_API_KEY;
const API_FOOTBALL_KEY  = process.env.API_FOOTBALL_KEY;
const YOUTUBE_API_KEY   = process.env.YOUTUBE_API_KEY || 'AIzaSyA1D3kBxN8i4pkom9h1hhAGigp7bhkkPCo';

// ─── Cache ────────────────────────────────────────────────────────────────────
const cache = new NodeCache({ stdTTL: 30, checkperiod: 10 });

const TTL = {
  LIVE:       30,              // 30 seconds
  FIXTURES:   3600 * 6,       // 6 hours
  STANDINGS:  3600 * 6,       // 6 hours (was 24h — now shorter to pick up live updates)
  LINEUPS:    3600 * 24,      // 24 hours
  STATS:      60 * 5,         // 5 minutes
  EVENTS:     30,             // 30 seconds
  H2H:        3600 * 24 * 7,  // 7 days
  TEAM:       3600 * 24,      // 24 hours
  SQUAD:      3600 * 24 * 7,  // 7 days
  TEAM_FIX:   3600 * 6,       // 6 hours
  NEWS:       60 * 30,        // 30 minutes
  HIGHLIGHTS: 3600 * 6,       // 6 hours
};

// ─── Axios clients ────────────────────────────────────────────────────────────
const footballDataClient = axios.create({
  baseURL: 'https://api.football-data.org/v4',
  headers: { 'X-Auth-Token': FOOTBALL_DATA_KEY },
  timeout: 15000,
});

const apiFootballClient = axios.create({
  baseURL: 'https://v3.football.api-sports.io',
  headers: {
    'x-apisports-key': API_FOOTBALL_KEY,
    'x-rapidapi-key':  API_FOOTBALL_KEY,
    'x-rapidapi-host': 'v3.football.api-sports.io',
  },
  timeout: 15000,
});

const sportsDbClient = axios.create({
  baseURL: 'https://www.thesportsdb.com/api/v1/json/3',
  timeout: 15000,
});

const youtubeClient = axios.create({
  baseURL: 'https://www.googleapis.com/youtube/v3',
  timeout: 10000,
});

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ─── League ID Maps ───────────────────────────────────────────────────────────
// API-Football leagueId → Football-Data.org competition code
const LEAGUE_MAP_FD = {
  39:  'PL',   // Premier League
  140: 'PD',   // La Liga
  135: 'SA',   // Serie A
  78:  'BL1',  // Bundesliga
  61:  'FL1',  // Ligue 1
  2:   'CL',   // Champions League
  3:   'EL',   // Europa League
  45:  'FAC',  // FA Cup
  848: 'ECCO', // Conference League (approx)
};

// API-Football leagueId → TheSportsDB league ID
const LEAGUE_MAP_TSDB = {
  39:  4328,  // Premier League
  140: 4335,  // La Liga
  135: 4332,  // Serie A
  78:  4331,  // Bundesliga
  61:  4334,  // Ligue 1
  2:   4480,  // UEFA Champions League
};

// API-Football teamId → TheSportsDB teamId  (top clubs, expandable)
const TEAM_MAP_TSDB = {
  // Premier League
  33:   133612, // Manchester United
  40:   133604, // Liverpool
  42:   133613, // Manchester City
  47:   133602, // Tottenham
  49:   133610, // Chelsea
  50:   133604, // Liverpool (duplicate guard)
  51:   133615, // Brighton
  52:   134777, // Crystal Palace
  57:   133606, // Arsenal  (FD id)
  66:   133608, // Aston Villa
  67:   133616, // Newcastle
  73:   134774, // Everton
  79:   133607, // Wolverhampton
  94:   133617, // Fulham
  // La Liga
  529:  133739, // Barcelona
  530:  133604, // Real Madrid (guard)
  541:  133600, // Real Madrid
  // Serie A
  489:  133604, // guard
  496:  133601, // Juventus
  // Bundesliga
  157:  133619, // Bayern Munich
  165:  133618, // Borussia Dortmund
};

// ─── Helpers ──────────────────────────────────────────────────────────────────
function getCached(key)            { return cache.get(key); }
function setCache(key, val, ttl)   { cache.set(key, val, ttl); }

// Normalize Football-Data.org match → unified fixture shape
function normalizeFDFixture(match) {
  const homeScore  = match.score?.fullTime?.home  ?? match.score?.halfTime?.home  ?? null;
  const awayScore  = match.score?.fullTime?.away  ?? match.score?.halfTime?.away  ?? null;
  const isLive     = ['IN_PLAY', 'PAUSED', 'HALF_TIME'].includes(match.status);
  const isFinished = ['FINISHED', 'AWARDED'].includes(match.status);

  const STATUS = {
    IN_PLAY:   { short: '1H',  long: '1st Half'       },
    PAUSED:    { short: 'HT',  long: 'Halftime'       },
    HALF_TIME: { short: 'HT',  long: 'Halftime'       },
    FINISHED:  { short: 'FT',  long: 'Match Finished' },
    TIMED:     { short: 'NS',  long: 'Not Started'    },
    SCHEDULED: { short: 'NS',  long: 'Not Started'    },
    POSTPONED: { short: 'PST', long: 'Postponed'      },
    CANCELLED: { short: 'CANC',long: 'Cancelled'      },
  };
  const st = STATUS[match.status] ?? { short: 'NS', long: 'Not Started' };

  return {
    fixture: {
      id:      match.id,
      date:    match.utcDate,
      status:  { short: st.short, long: st.long, elapsed: null },
      referee: match.referees?.[0]?.name ?? '',
      venue:   { name: match.venue ?? '', city: '' },
    },
    league: {
      id:      match.competition?.id ?? 0,
      name:    match.competition?.name ?? '',
      country: match.area?.name ?? '',
      logo:    match.competition?.emblem ?? '',
      flag:    '',
      round:   match.matchday ? `Regular Season - ${match.matchday}` : '',
    },
    teams: {
      home: {
        id:     match.homeTeam?.id ?? 0,
        name:   match.homeTeam?.shortName ?? match.homeTeam?.name ?? '',
        logo:   match.homeTeam?.crest ?? '',
        winner: isFinished ? (homeScore > awayScore) : null,
      },
      away: {
        id:     match.awayTeam?.id ?? 0,
        name:   match.awayTeam?.shortName ?? match.awayTeam?.name ?? '',
        logo:   match.awayTeam?.crest ?? '',
        winner: isFinished ? (awayScore > homeScore) : null,
      },
    },
    goals: { home: homeScore, away: awayScore },
    score: {
      fulltime: { home: homeScore, away: awayScore },
      halftime: { home: match.score?.halfTime?.home ?? null, away: match.score?.halfTime?.away ?? null },
    },
    isLive,
  };
}

// ─── Routes ───────────────────────────────────────────────────────────────────

// Health
app.get('/health', (req, res) => {
  res.json({
    status:     'ok',
    uptime:     Math.floor(process.uptime()),
    cache_keys: cache.keys().length,
    timestamp:  new Date().toISOString(),
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /fixtures/live
// Source: Football-Data.org → fallback API-Football
// ─────────────────────────────────────────────────────────────────────────────
app.get('/fixtures/live', async (req, res) => {
  const cacheKey = 'live_fixtures';
  const cached   = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });

  try {
    const codes   = Object.values(LEAGUE_MAP_FD);
    const results = await Promise.allSettled(
      codes.map(code =>
        footballDataClient.get(`/competitions/${code}/matches`, {
          params: { status: 'IN_PLAY,PAUSED,HALF_TIME' },
        }).catch(() => null)
      )
    );
    const allMatches = [];
    for (const r of results) {
      if (r.status === 'fulfilled' && r.value?.data?.matches) {
        allMatches.push(...r.value.data.matches.map(normalizeFDFixture));
      }
    }
    if (allMatches.length > 0) {
      setCache(cacheKey, allMatches, TTL.LIVE);
      return res.json({ response: allMatches, source: 'football-data.org' });
    }

    // Fallback: API-Football
    const fb   = await apiFootballClient.get('/fixtures', { params: { live: 'all' } });
    const data = fb.data?.response ?? [];
    setCache(cacheKey, data, TTL.LIVE);
    return res.json({ response: data, source: 'api-football-fallback' });
  } catch (err) {
    console.error('[live] Error:', err.message);
    res.status(500).json({ error: 'Failed to fetch live fixtures', message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /fixtures/date/:date   (yyyy-MM-dd)
// Source: Football-Data.org → fallback API-Football
// ─────────────────────────────────────────────────────────────────────────────
app.get('/fixtures/date/:date', async (req, res) => {
  const { date }  = req.params;
  const cacheKey  = `fixtures_${date}`;
  const cached    = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });

  try {
    const codes   = Object.values(LEAGUE_MAP_FD);
    const results = await Promise.allSettled(
      codes.map(code =>
        footballDataClient.get(`/competitions/${code}/matches`, {
          params: { dateFrom: date, dateTo: date },
        }).catch(() => null)
      )
    );
    const allMatches = [];
    for (const r of results) {
      if (r.status === 'fulfilled' && r.value?.data?.matches) {
        allMatches.push(...r.value.data.matches.map(normalizeFDFixture));
      }
    }
    if (allMatches.length > 0) {
      setCache(cacheKey, allMatches, TTL.FIXTURES);
      return res.json({ response: allMatches, source: 'football-data.org' });
    }

    // Fallback: API-Football
    const fb   = await apiFootballClient.get('/fixtures', { params: { date } });
    const data = fb.data?.response ?? [];
    setCache(cacheKey, data, TTL.FIXTURES);
    return res.json({ response: data, source: 'api-football-fallback' });
  } catch (err) {
    console.error('[date] Error:', err.message);
    res.status(500).json({ error: 'Failed to fetch fixtures', message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /fixtures/range?from=yyyy-MM-dd&to=yyyy-MM-dd
// Returns fixtures for a date window. Used for home screen pre-caching.
// Source: Football-Data.org
// ─────────────────────────────────────────────────────────────────────────────
app.get('/fixtures/range', async (req, res) => {
  const { from, to } = req.query;
  if (!from || !to) return res.status(400).json({ error: 'from and to query params required' });

  const cacheKey = `fixtures_range_${from}_${to}`;
  const cached   = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });

  try {
    const codes   = Object.values(LEAGUE_MAP_FD);
    const results = await Promise.allSettled(
      codes.map(code =>
        footballDataClient.get(`/competitions/${code}/matches`, {
          params: { dateFrom: from, dateTo: to },
        }).catch(() => null)
      )
    );
    const allMatches = [];
    for (const r of results) {
      if (r.status === 'fulfilled' && r.value?.data?.matches) {
        allMatches.push(...r.value.data.matches.map(normalizeFDFixture));
      }
    }
    setCache(cacheKey, allMatches, TTL.FIXTURES);
    return res.json({ response: allMatches, source: 'football-data.org', count: allMatches.length });
  } catch (err) {
    console.error('[range] Error:', err.message);
    res.status(500).json({ error: 'Failed to fetch fixture range', message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /standings/:leagueId/:season
// FIX: Primary = Football-Data.org (full table) → Fallback TheSportsDB → API-Football
// ─────────────────────────────────────────────────────────────────────────────
app.get('/standings/:leagueId/:season', async (req, res) => {
  const leagueId = parseInt(req.params.leagueId);
  const season   = parseInt(req.params.season);
  const cacheKey = `standings_${leagueId}_${season}`;
  const cached   = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });

  // 1. Football-Data.org — full table, most accurate, current season
  const fdCode = LEAGUE_MAP_FD[leagueId];
  if (fdCode) {
    try {
      const r         = await footballDataClient.get(`/competitions/${fdCode}/standings`);
      const tableData = r.data?.standings?.[0]?.table ?? [];
      if (tableData.length > 0) {
        const normalized = tableData.map((entry, idx) => ({
          rank:        entry.position ?? idx + 1,
          team: {
            id:   entry.team?.id ?? 0,
            name: entry.team?.shortName ?? entry.team?.name ?? '',
            logo: entry.team?.crest ?? '',
          },
          points:      entry.points ?? 0,
          goalsDiff:   entry.goalDifference ?? 0,
          group:       'Regular Season',
          form:        '',
          status:      'same',
          description: '',
          all: {
            played: entry.playedGames ?? 0,
            win:    entry.won ?? 0,
            draw:   entry.draw ?? 0,
            lose:   entry.lost ?? 0,
            goals: {
              for:     entry.goalsFor ?? 0,
              against: entry.goalsAgainst ?? 0,
            },
          },
        }));
        setCache(cacheKey, normalized, TTL.STANDINGS);
        return res.json({ response: normalized, source: 'football-data.org' });
      }
    } catch (e) { console.warn('[standings] FD failed:', e.message); }
  }

  // 2. TheSportsDB fallback
  const tsdbId = LEAGUE_MAP_TSDB[leagueId];
  if (tsdbId) {
    try {
      const seasonStr = `${season}-${season + 1}`;
      const r = await sportsDbClient.get('/lookuptable.php', { params: { l: tsdbId, s: seasonStr } });
      if (r.data?.table?.length > 0) {
        const standings = r.data.table.map(item => ({
          rank:  parseInt(item.intRank ?? 0),
          team: {
            id:   parseInt(item.idTeam ?? 0),
            name: item.strTeam ?? '',
            logo: item.strBadge ? `${item.strBadge}/tiny` : '',
          },
          points:      parseInt(item.intPoints ?? 0),
          goalsDiff:   parseInt(item.intGoalDifference ?? 0),
          group:       'Regular Season',
          form:        item.strForm ?? '',
          status:      'same',
          description: '',
          all: {
            played: parseInt(item.intPlayed ?? 0),
            win:    parseInt(item.intWin ?? 0),
            draw:   parseInt(item.intDraw ?? 0),
            lose:   parseInt(item.intLoss ?? 0),
            goals: {
              for:     parseInt(item.intGoalsFor ?? 0),
              against: parseInt(item.intGoalsAgainst ?? 0),
            },
          },
        }));
        setCache(cacheKey, standings, TTL.STANDINGS);
        return res.json({ response: standings, source: 'thesportsdb' });
      }
    } catch (e) { console.warn('[standings] TSDB failed:', e.message); }
  }

  // 3. API-Football last resort
  try {
    const r         = await apiFootballClient.get('/standings', { params: { league: leagueId, season } });
    const standings = r.data?.response?.[0]?.league?.standings?.[0] ?? [];
    setCache(cacheKey, standings, TTL.STANDINGS);
    return res.json({ response: standings, source: 'api-football-fallback' });
  } catch (err) {
    console.error('[standings] All sources failed:', err.message);
    res.status(500).json({ error: 'Failed to fetch standings', message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /teams/:teamId
// Returns team info: bio, stadium, manager, colours, formed, logo, country
// Source: TheSportsDB (free, unlimited)
// ─────────────────────────────────────────────────────────────────────────────
app.get('/teams/:teamId', async (req, res) => {
  const teamId   = parseInt(req.params.teamId);
  const cacheKey = `team_${teamId}`;
  const cached   = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });

  // Determine TheSportsDB ID
  const tsdbId = TEAM_MAP_TSDB[teamId];

  if (tsdbId) {
    try {
      const r    = await sportsDbClient.get('/lookupteam.php', { params: { id: tsdbId } });
      const team = r.data?.teams?.[0];
      if (team) {
        const data = {
          id:          teamId,
          tsdbId:      tsdbId,
          name:        team.strTeam ?? '',
          shortName:   team.strTeamShort ?? '',
          logo:        team.strTeamBadge ?? '',
          banner:      team.strTeamBanner ?? '',
          jersey:      team.strTeamJersey ?? '',
          stadium:     team.strStadium ?? '',
          stadiumCapacity: team.intStadiumCapacity ?? '',
          stadiumLocation: team.strStadiumLocation ?? '',
          stadiumImage:    team.strStadiumThumb ?? '',
          city:        team.strCity ?? '',
          country:     team.strCountry ?? '',
          founded:     team.intFormedYear ?? '',
          manager:     team.strManager ?? '',
          description: team.strDescriptionEN ?? '',
          website:     team.strWebsite ?? '',
          facebook:    team.strFacebook ?? '',
          twitter:     team.strTwitter ?? '',
          instagram:   team.strInstagram ?? '',
          youtube:     team.strYoutube ?? '',
          colours:     team.strColour1 ? [team.strColour1, team.strColour2, team.strColour3].filter(Boolean) : [],
        };
        setCache(cacheKey, data, TTL.TEAM);
        return res.json({ response: data, source: 'thesportsdb' });
      }
    } catch (e) { console.warn('[team] TSDB lookup failed:', e.message); }
  }

  // Fallback: return basic info from API-Football if we have quota
  try {
    const r    = await apiFootballClient.get('/teams', { params: { id: teamId } });
    const team = r.data?.response?.[0];
    if (team) {
      const data = {
        id:          teamId,
        name:        team.team?.name ?? '',
        logo:        team.team?.logo ?? '',
        country:     team.team?.country ?? '',
        founded:     team.team?.founded ?? '',
        stadium:     team.venue?.name ?? '',
        city:        team.venue?.city ?? '',
        description: '',
        manager:     '',
        colours:     [],
      };
      setCache(cacheKey, data, TTL.TEAM);
      return res.json({ response: data, source: 'api-football-fallback' });
    }
  } catch (e) { console.warn('[team] API-Football failed:', e.message); }

  res.status(404).json({ error: 'Team not found', teamId });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /teams/:teamId/squad
// Returns full squad with player photos, positions, nationality, age
// Source: TheSportsDB lookup_all_players (free)
// ─────────────────────────────────────────────────────────────────────────────
app.get('/teams/:teamId/squad', async (req, res) => {
  const teamId   = parseInt(req.params.teamId);
  const cacheKey = `squad_${teamId}`;
  const cached   = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });

  const tsdbId = TEAM_MAP_TSDB[teamId];

  if (tsdbId) {
    try {
      const r       = await sportsDbClient.get('/lookup_all_players.php', { params: { id: tsdbId } });
      const players = r.data?.player ?? [];
      if (players.length > 0) {
        const data = players.map(p => ({
          id:          parseInt(p.idPlayer ?? 0),
          name:        p.strPlayer ?? '',
          photo:       p.strThumb ?? p.strCutout ?? '',
          position:    p.strPosition ?? '',
          nationality: p.strNationality ?? '',
          birthDate:   p.dateBorn ?? '',
          number:      p.strNumber ?? '',
          height:      p.strHeight ?? '',
          weight:      p.strWeight ?? '',
          description: p.strDescriptionEN ?? '',
        }));
        setCache(cacheKey, data, TTL.SQUAD);
        return res.json({ response: data, source: 'thesportsdb' });
      }
    } catch (e) { console.warn('[squad] TSDB failed:', e.message); }
  }

  // Fallback: API-Football squad
  try {
    const r       = await apiFootballClient.get('/players/squads', { params: { team: teamId } });
    const players = r.data?.response?.[0]?.players ?? [];
    const data    = players.map(p => ({
      id:          p.id ?? 0,
      name:        p.name ?? '',
      photo:       p.photo ?? '',
      position:    p.position ?? '',
      nationality: '',
      birthDate:   '',
      number:      p.number ?? '',
      height:      '',
      weight:      '',
      description: '',
    }));
    setCache(cacheKey, data, TTL.SQUAD);
    return res.json({ response: data, source: 'api-football-fallback' });
  } catch (err) {
    console.error('[squad] All sources failed:', err.message);
    res.status(500).json({ error: 'Failed to fetch squad', message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /teams/:teamId/fixtures?season=2024
// Returns team's season schedule (past + upcoming)
// Source: Football-Data.org → API-Football fallback
// ─────────────────────────────────────────────────────────────────────────────
app.get('/teams/:teamId/fixtures', async (req, res) => {
  const teamId   = parseInt(req.params.teamId);
  const season   = req.query.season ?? '2024';
  const cacheKey = `team_fixtures_${teamId}_${season}`;
  const cached   = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });

  try {
    const r       = await footballDataClient.get(`/teams/${teamId}/matches`, { params: { season } });
    const matches = r.data?.matches ?? [];
    if (matches.length > 0) {
      const data = matches.map(normalizeFDFixture);
      setCache(cacheKey, data, TTL.TEAM_FIX);
      return res.json({ response: data, source: 'football-data.org' });
    }
  } catch (e) { console.warn('[team-fixtures] FD failed:', e.message); }

  // Fallback: API-Football
  try {
    const r    = await apiFootballClient.get('/fixtures', { params: { team: teamId, season } });
    const data = r.data?.response ?? [];
    setCache(cacheKey, data, TTL.TEAM_FIX);
    return res.json({ response: data, source: 'api-football-fallback' });
  } catch (err) {
    console.error('[team-fixtures] All sources failed:', err.message);
    res.status(500).json({ error: 'Failed to fetch team fixtures', message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /news?team=Manchester+United&limit=10
// Returns latest news articles from free RSS feeds
// Sources: BBC Sport, Sky Sports, Goal.com, The Guardian
// ─────────────────────────────────────────────────────────────────────────────
const NEWS_FEEDS = [
  { name: 'BBC Sport',     url: 'https://feeds.bbci.co.uk/sport/football/rss.xml' },
  { name: 'Sky Sports',    url: 'https://www.skysports.com/rss/12040' },
  { name: 'Goal.com',      url: 'https://www.goal.com/feeds/en/news' },
  { name: 'The Guardian',  url: 'https://www.theguardian.com/football/rss' },
  { name: 'ESPN FC',       url: 'https://www.espn.com/espn/rss/soccer/news' },
];

app.get('/news', async (req, res) => {
  const team     = (req.query.team ?? '').toLowerCase().trim();
  const limit    = Math.min(parseInt(req.query.limit ?? '15'), 30);
  const cacheKey = `news_${team}_${limit}`;
  const cached   = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });

  const allArticles = [];

  const feedResults = await Promise.allSettled(
    NEWS_FEEDS.map(feed =>
      parser.parseURL(feed.url)
        .then(parsed => ({ source: feed.name, items: parsed.items ?? [] }))
        .catch(() => ({ source: feed.name, items: [] }))
    )
  );

  for (const r of feedResults) {
    if (r.status !== 'fulfilled') continue;
    const { source, items } = r.value;
    for (const item of items) {
      const title   = (item.title ?? '').toLowerCase();
      const content = (item.contentSnippet ?? item.content ?? '').toLowerCase();

      // Filter by team name if provided
      if (team && !title.includes(team) && !content.includes(team)) continue;

      allArticles.push({
        title:       item.title ?? '',
        description: item.contentSnippet ?? item.summary ?? '',
        url:         item.link ?? '',
        image:       item.enclosure?.url
                       ?? item['media:content']?.['$']?.url
                       ?? item['media:thumbnail']?.['$']?.url
                       ?? '',
        source:      source,
        publishedAt: item.pubDate ?? item.isoDate ?? new Date().toISOString(),
      });
    }
  }

  // Sort newest first, deduplicate by title
  const seen = new Set();
  const deduplicated = allArticles
    .sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt))
    .filter(a => {
      if (seen.has(a.title)) return false;
      seen.add(a.title);
      return true;
    })
    .slice(0, limit);

  setCache(cacheKey, deduplicated, TTL.NEWS);
  res.json({ response: deduplicated, source: 'rss-aggregator', count: deduplicated.length });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /highlights?team=Manchester+United&limit=6
// Returns YouTube video thumbnails + links for latest team highlights
// Source: YouTube Data API v3 (moved to backend to cache & protect key)
// ─────────────────────────────────────────────────────────────────────────────
app.get('/highlights', async (req, res) => {
  const team     = req.query.team ?? '';
  const limit    = Math.min(parseInt(req.query.limit ?? '6'), 10);
  const cacheKey = `highlights_${team.toLowerCase()}_${limit}`;
  const cached   = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });

  if (!team) return res.status(400).json({ error: 'team query param required' });

  try {
    const currentYear = new Date().getFullYear();
    const r = await youtubeClient.get('/search', {
      params: {
        part:          'snippet',
        q:             `${team} highlights ${currentYear}`,
        type:          'video',
        order:         'date',
        maxResults:    limit,
        publishedAfter: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
        key:           YOUTUBE_API_KEY,
      },
    });

    const items = r.data?.items ?? [];
    const data  = items.map(item => ({
      videoId:     item.id?.videoId ?? '',
      title:       item.snippet?.title ?? '',
      thumbnail:   item.snippet?.thumbnails?.high?.url ?? item.snippet?.thumbnails?.default?.url ?? '',
      channel:     item.snippet?.channelTitle ?? '',
      publishedAt: item.snippet?.publishedAt ?? '',
      url:         `https://www.youtube.com/watch?v=${item.id?.videoId}`,
    }));

    setCache(cacheKey, data, TTL.HIGHLIGHTS);
    return res.json({ response: data, source: 'youtube', count: data.length });
  } catch (err) {
    console.error('[highlights] YouTube failed:', err.message);
    // Return empty rather than error — UI handles gracefully
    res.json({ response: [], source: 'error', error: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /fixtures/:fixtureId/statistics
// ─────────────────────────────────────────────────────────────────────────────
app.get('/fixtures/:fixtureId/statistics', async (req, res) => {
  const { fixtureId } = req.params;
  const cacheKey      = `stats_${fixtureId}`;
  const cached        = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });
  try {
    const r    = await apiFootballClient.get('/fixtures/statistics', { params: { fixture: fixtureId } });
    const data = r.data?.response ?? [];
    setCache(cacheKey, data, TTL.STATS);
    return res.json({ response: data, source: 'api-football' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch statistics', message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /fixtures/:fixtureId/lineups
// ─────────────────────────────────────────────────────────────────────────────
app.get('/fixtures/:fixtureId/lineups', async (req, res) => {
  const { fixtureId } = req.params;
  const cacheKey      = `lineups_${fixtureId}`;
  const cached        = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });
  try {
    const r    = await apiFootballClient.get('/fixtures/lineups', { params: { fixture: fixtureId } });
    const data = r.data?.response ?? [];
    setCache(cacheKey, data, TTL.LINEUPS);
    return res.json({ response: data, source: 'api-football' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch lineups', message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /fixtures/:fixtureId/events
// ─────────────────────────────────────────────────────────────────────────────
app.get('/fixtures/:fixtureId/events', async (req, res) => {
  const { fixtureId } = req.params;
  const cacheKey      = `events_${fixtureId}`;
  const cached        = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });
  try {
    const r    = await apiFootballClient.get('/fixtures/events', { params: { fixture: fixtureId } });
    const data = r.data?.response ?? [];
    setCache(cacheKey, data, TTL.EVENTS);
    return res.json({ response: data, source: 'api-football' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch events', message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /fixtures/h2h/:homeId/:awayId
// ─────────────────────────────────────────────────────────────────────────────
app.get('/fixtures/h2h/:homeId/:awayId', async (req, res) => {
  const { homeId, awayId } = req.params;
  const cacheKey           = `h2h_${homeId}_${awayId}`;
  const cached             = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });
  try {
    const r    = await apiFootballClient.get('/fixtures/headtohead', { params: { h2h: `${homeId}-${awayId}`, last: 10 } });
    const data = r.data?.response ?? [];
    setCache(cacheKey, data, TTL.H2H);
    return res.json({ response: data, source: 'api-football' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch H2H', message: err.message });
  }
});

// ─── 404 ─────────────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: `Endpoint not found: ${req.method} ${req.path}` });
});

// ─── Start ────────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n🚀 LiveScore Backend v2 running on port ${PORT}`);
  console.log(`📋 Endpoints:`);
  console.log(`   GET /health`);
  console.log(`   GET /fixtures/live`);
  console.log(`   GET /fixtures/date/:date`);
  console.log(`   GET /fixtures/range?from=&to=            ← NEW`);
  console.log(`   GET /fixtures/h2h/:homeId/:awayId`);
  console.log(`   GET /fixtures/:id/statistics`);
  console.log(`   GET /fixtures/:id/lineups`);
  console.log(`   GET /fixtures/:id/events`);
  console.log(`   GET /standings/:leagueId/:season         ← FIXED (full table)`);
  console.log(`   GET /teams/:teamId                       ← NEW`);
  console.log(`   GET /teams/:teamId/squad                 ← NEW`);
  console.log(`   GET /teams/:teamId/fixtures              ← NEW`);
  console.log(`   GET /news?team=                          ← NEW`);
  console.log(`   GET /highlights?team=                    ← NEW\n`);

  // ── Keep-Alive Self-Ping ──
  const PING_URL = process.env.SELF_PING_URL || `http://localhost:${PORT}`;
  setInterval(async () => {
    try {
      await axios.get(`${PING_URL}/health`, { timeout: 10000 });
      console.log(`[keep-alive] ${new Date().toISOString()}`);
    } catch (e) {
      console.warn(`[keep-alive] Ping failed: ${e.message}`);
    }
  }, 10 * 60 * 1000);

  console.log(`⏰ Keep-alive ping active → ${PING_URL}/health`);
});
