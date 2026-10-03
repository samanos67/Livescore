require('dotenv').config();
const express = require('express');
const cors = require('cors');
const axios = require('axios');
const NodeCache = require('node-cache');

const app = express();
const PORT = process.env.PORT || 3000;

// ─── API Keys ────────────────────────────────────────────────────────────────
const FOOTBALL_DATA_KEY  = process.env.FOOTBALL_DATA_API_KEY;
const API_FOOTBALL_KEY   = process.env.API_FOOTBALL_KEY;

// ─── Cache TTLs (seconds) ────────────────────────────────────────────────────
// Short TTLs for live data, long for static data
const cache = new NodeCache({ stdTTL: 30, checkperiod: 10 });

const TTL = {
  LIVE:       30,          //  30 seconds  – live scores need freshness
  FIXTURES:   3600 * 6,   //  6 hours     – fixtures don't move once set
  STANDINGS:  3600 * 24,  //  24 hours    – updates once per matchday
  LINEUPS:    3600 * 24,  //  24 hours    – set before kickoff, never changes
  STATS:      60 * 5,     //  5 minutes   – refresh during live match
  EVENTS:     30,         //  30 seconds  – timeline, same as live
  H2H:        3600 * 24 * 7, // 7 days   – historical, rarely changes
  IMAGES:     3600 * 24 * 30, // 30 days – logos never change
};

// ─── Axios clients ───────────────────────────────────────────────────────────
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

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ─── League ID Maps ──────────────────────────────────────────────────────────
// Maps API-Football league ID → Football-Data.org competition code
const LEAGUE_MAP_FD = {
  39:  'PL',   // Premier League
  140: 'PD',   // La Liga (Primera Division)
  135: 'SA',   // Serie A
  78:  'BL1',  // Bundesliga
  61:  'FL1',  // Ligue 1
  2:   'CL',   // Champions League
  848: 'EC',   // Europa Conference League (approx)
  3:   'EL',   // Europa League
  45:  'FAC',  // FA Cup
};

// Maps API-Football league ID → TheSportsDB league ID
const LEAGUE_MAP_TSDB = {
  39:  4328,  // Premier League
  140: 4335,  // La Liga
  135: 4332,  // Serie A
  78:  4331,  // Bundesliga
  61:  4334,  // Ligue 1
  2:   4480,  // UEFA Champions League
};

// ─── Helpers ─────────────────────────────────────────────────────────────────
function getCached(key) {
  return cache.get(key);
}

function setCache(key, value, ttl) {
  cache.set(key, value, ttl);
}

// Normalize Football-Data.org fixture to match API-Football structure
// so the Flutter app doesn't need to change its model layer
function normalizeFDFixture(match) {
  const homeScore = match.score?.fullTime?.home ?? match.score?.halfTime?.home ?? null;
  const awayScore = match.score?.fullTime?.away ?? match.score?.halfTime?.away ?? null;
  const isLive = ['IN_PLAY', 'PAUSED', 'HALF_TIME'].includes(match.status);
  const isFinished = ['FINISHED', 'AWARDED'].includes(match.status);

  let statusShort = 'NS';
  let statusLong  = 'Not Started';
  let elapsed = null;

  if (match.status === 'IN_PLAY')  { statusShort = '1H';  statusLong = '1st Half';    }
  if (match.status === 'PAUSED')   { statusShort = 'HT';  statusLong = 'Halftime';    }
  if (match.status === 'HALF_TIME'){ statusShort = 'HT';  statusLong = 'Halftime';    }
  if (match.status === 'FINISHED') { statusShort = 'FT';  statusLong = 'Match Finished'; }
  if (match.status === 'TIMED')    { statusShort = 'NS';  statusLong = 'Not Started'; }
  if (match.status === 'SCHEDULED'){ statusShort = 'NS';  statusLong = 'Not Started'; }
  if (match.status === 'POSTPONED'){ statusShort = 'PST'; statusLong = 'Postponed';   }
  if (match.status === 'CANCELLED'){ statusShort = 'CANC';statusLong = 'Cancelled';   }

  return {
    fixture: {
      id:        match.id,
      date:      match.utcDate,
      status:    { short: statusShort, long: statusLong, elapsed },
      referee:   match.referees?.[0]?.name ?? '',
      venue:     { name: match.venue ?? '', city: '' },
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
    goals: {
      home: homeScore,
      away: awayScore,
    },
    score: {
      fulltime:  { home: homeScore, away: awayScore },
      halftime:  { home: match.score?.halfTime?.home ?? null, away: match.score?.halfTime?.away ?? null },
    },
    isLive,
  };
}

// ─── Routes ──────────────────────────────────────────────────────────────────

// Health check + keep-alive endpoint
app.get('/health', (req, res) => {
  res.json({
    status:    'ok',
    uptime:    Math.floor(process.uptime()),
    cache_keys: cache.keys().length,
    timestamp: new Date().toISOString(),
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /fixtures/live
// Source: Football-Data.org → fallback API-Football
// Cache: 30 seconds
// ─────────────────────────────────────────────────────────────────────────────
app.get('/fixtures/live', async (req, res) => {
  const cacheKey = 'live_fixtures';
  const cached = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });

  try {
    // Football-Data.org: get all matches across supported competitions
    const competitionCodes = Object.values(LEAGUE_MAP_FD);
    const matchRequests = competitionCodes.map(code =>
      footballDataClient.get(`/competitions/${code}/matches`, {
        params: { status: 'IN_PLAY,PAUSED,HALF_TIME' }
      }).catch(() => null)
    );
    const results = await Promise.allSettled(matchRequests);
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
    const fallback = await apiFootballClient.get('/fixtures', { params: { live: 'all' } });
    const data = fallback.data?.response ?? [];
    setCache(cacheKey, data, TTL.LIVE);
    return res.json({ response: data, source: 'api-football-fallback' });
  } catch (err) {
    console.error('[live] Error:', err.message);
    res.status(500).json({ error: 'Failed to fetch live fixtures', message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /fixtures/date/:date  (format: yyyy-MM-dd)
// Source: Football-Data.org → fallback API-Football
// Cache: 6 hours
// ─────────────────────────────────────────────────────────────────────────────
app.get('/fixtures/date/:date', async (req, res) => {
  const { date } = req.params;
  const cacheKey = `fixtures_${date}`;
  const cached = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });

  try {
    // Football-Data.org: fetch matches for date across all competitions
    const competitionCodes = Object.values(LEAGUE_MAP_FD);
    const matchRequests = competitionCodes.map(code =>
      footballDataClient.get(`/competitions/${code}/matches`, {
        params: { dateFrom: date, dateTo: date }
      }).catch(() => null)
    );
    const results = await Promise.allSettled(matchRequests);
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
    const fallback = await apiFootballClient.get('/fixtures', { params: { date } });
    const data = fallback.data?.response ?? [];
    setCache(cacheKey, data, TTL.FIXTURES);
    return res.json({ response: data, source: 'api-football-fallback' });
  } catch (err) {
    console.error('[date] Error:', err.message);
    res.status(500).json({ error: 'Failed to fetch fixtures', message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /standings/:leagueId/:season
// Source: TheSportsDB (free, unlimited) → fallback Football-Data.org → fallback API-Football
// Cache: 24 hours
// ─────────────────────────────────────────────────────────────────────────────
app.get('/standings/:leagueId/:season', async (req, res) => {
  const leagueId = parseInt(req.params.leagueId);
  const season   = parseInt(req.params.season);
  const cacheKey = `standings_${leagueId}_${season}`;
  const cached = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });

  // 1. Try TheSportsDB (unlimited)
  const tsdbId = LEAGUE_MAP_TSDB[leagueId];
  if (tsdbId) {
    try {
      const seasonStr = `${season}-${season + 1}`;
      const r = await sportsDbClient.get('/lookuptable.php', {
        params: { l: tsdbId, s: seasonStr }
      });
      if (r.data?.table?.length > 0) {
        const standings = r.data.table.map(item => ({
          rank:  parseInt(item.intRank ?? 0),
          team: {
            id:     parseInt(item.idTeam ?? 0),
            name:   item.strTeam ?? '',
            logo:   item.strBadge ?? '',
          },
          points:     parseInt(item.intPoints ?? 0),
          goalsDiff:  parseInt(item.intGoalDifference ?? 0),
          group:      'Regular Season',
          form:       item.strForm ?? '',
          status:     'same',
          description:'',
          all: {
            played:       parseInt(item.intPlayed ?? 0),
            win:          parseInt(item.intWin ?? 0),
            draw:         parseInt(item.intDraw ?? 0),
            lose:         parseInt(item.intLoss ?? 0),
            goals: {
              for:     parseInt(item.intGoalsFor ?? 0),
              against: parseInt(item.intGoalsAgainst ?? 0),
            },
          },
        }));
        setCache(cacheKey, standings, TTL.STANDINGS);
        return res.json({ response: standings, source: 'thesportsdb' });
      }
    } catch (e) { console.warn('[standings] TheSportsDB failed:', e.message); }
  }

  // 2. Try Football-Data.org
  const fdCode = LEAGUE_MAP_FD[leagueId];
  if (fdCode) {
    try {
      const r = await footballDataClient.get(`/competitions/${fdCode}/standings`);
      const standings = r.data?.standings?.[0]?.table ?? [];
      if (standings.length > 0) {
        const normalized = standings.map((entry, idx) => ({
          rank:  entry.position ?? idx + 1,
          team: {
            id:   entry.team?.id ?? 0,
            name: entry.team?.shortName ?? entry.team?.name ?? '',
            logo: entry.team?.crest ?? '',
          },
          points:     entry.points ?? 0,
          goalsDiff:  entry.goalDifference ?? 0,
          group:      'Regular Season',
          form:       '',
          status:     'same',
          description:'',
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
    } catch (e) { console.warn('[standings] Football-Data failed:', e.message); }
  }

  // 3. Final fallback: API-Football
  try {
    const r = await apiFootballClient.get('/standings', {
      params: { league: leagueId, season }
    });
    const league = r.data?.response?.[0]?.league;
    const standings = league?.standings?.[0] ?? [];
    setCache(cacheKey, standings, TTL.STANDINGS);
    return res.json({ response: standings, source: 'api-football-fallback' });
  } catch (err) {
    console.error('[standings] All sources failed:', err.message);
    res.status(500).json({ error: 'Failed to fetch standings', message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /fixtures/:fixtureId/statistics
// Source: API-Football (only source with this data)
// Cache: 5 min (live) / 24h once finished
// ─────────────────────────────────────────────────────────────────────────────
app.get('/fixtures/:fixtureId/statistics', async (req, res) => {
  const { fixtureId } = req.params;
  const cacheKey = `stats_${fixtureId}`;
  const cached = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });

  try {
    const r = await apiFootballClient.get('/fixtures/statistics', {
      params: { fixture: fixtureId }
    });
    const data = r.data?.response ?? [];
    setCache(cacheKey, data, TTL.STATS);
    return res.json({ response: data, source: 'api-football' });
  } catch (err) {
    console.error('[stats] Error:', err.message);
    res.status(500).json({ error: 'Failed to fetch statistics', message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /fixtures/:fixtureId/lineups
// Source: API-Football
// Cache: 24 hours
// ─────────────────────────────────────────────────────────────────────────────
app.get('/fixtures/:fixtureId/lineups', async (req, res) => {
  const { fixtureId } = req.params;
  const cacheKey = `lineups_${fixtureId}`;
  const cached = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });

  try {
    const r = await apiFootballClient.get('/fixtures/lineups', {
      params: { fixture: fixtureId }
    });
    const data = r.data?.response ?? [];
    setCache(cacheKey, data, TTL.LINEUPS);
    return res.json({ response: data, source: 'api-football' });
  } catch (err) {
    console.error('[lineups] Error:', err.message);
    res.status(500).json({ error: 'Failed to fetch lineups', message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /fixtures/:fixtureId/events
// Source: API-Football
// Cache: 30 seconds (live) / 24h once finished
// ─────────────────────────────────────────────────────────────────────────────
app.get('/fixtures/:fixtureId/events', async (req, res) => {
  const { fixtureId } = req.params;
  const cacheKey = `events_${fixtureId}`;
  const cached = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });

  try {
    const r = await apiFootballClient.get('/fixtures/events', {
      params: { fixture: fixtureId }
    });
    const data = r.data?.response ?? [];
    setCache(cacheKey, data, TTL.EVENTS);
    return res.json({ response: data, source: 'api-football' });
  } catch (err) {
    console.error('[events] Error:', err.message);
    res.status(500).json({ error: 'Failed to fetch events', message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /fixtures/h2h/:homeId/:awayId
// Source: API-Football
// Cache: 7 days
// ─────────────────────────────────────────────────────────────────────────────
app.get('/fixtures/h2h/:homeId/:awayId', async (req, res) => {
  const { homeId, awayId } = req.params;
  const cacheKey = `h2h_${homeId}_${awayId}`;
  const cached = getCached(cacheKey);
  if (cached) return res.json({ response: cached, source: 'cache' });

  try {
    const r = await apiFootballClient.get('/fixtures/headtohead', {
      params: { h2h: `${homeId}-${awayId}`, last: 10 }
    });
    const data = r.data?.response ?? [];
    setCache(cacheKey, data, TTL.H2H);
    return res.json({ response: data, source: 'api-football' });
  } catch (err) {
    console.error('[h2h] Error:', err.message);
    res.status(500).json({ error: 'Failed to fetch H2H', message: err.message });
  }
});

// ─── 404 catch-all ───────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: `Endpoint not found: ${req.method} ${req.path}` });
});

// ─── Start Server ─────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n🚀 LiveScore Backend running on port ${PORT}`);
  console.log(`📋 Endpoints:`);
  console.log(`   GET /health`);
  console.log(`   GET /fixtures/live`);
  console.log(`   GET /fixtures/date/:date`);
  console.log(`   GET /fixtures/h2h/:homeId/:awayId`);
  console.log(`   GET /fixtures/:fixtureId/statistics`);
  console.log(`   GET /fixtures/:fixtureId/lineups`);
  console.log(`   GET /fixtures/:fixtureId/events`);
  console.log(`   GET /standings/:leagueId/:season\n`);

  // ─── Keep-Alive Self-Ping ───────────────────────────────────────────────
  // Pings our own /health every 10 minutes to prevent Render from sleeping
  const PING_URL = process.env.SELF_PING_URL || `http://localhost:${PORT}`;
  const PING_INTERVAL_MS = 10 * 60 * 1000; // 10 minutes

  setInterval(async () => {
    try {
      await axios.get(`${PING_URL}/health`, { timeout: 10000 });
      console.log(`[keep-alive] Ping sent to ${PING_URL}/health at ${new Date().toISOString()}`);
    } catch (e) {
      console.warn(`[keep-alive] Ping failed: ${e.message}`);
    }
  }, PING_INTERVAL_MS);

  console.log(`⏰ Keep-alive self-ping active (every 10 min → ${PING_URL}/health)`);
});
