const axios = require('axios');

const ESPN_BASE = 'https://site.api.espn.com/apis/site/v2/sports/soccer';

// Map of major league codes and their API-Football compatible IDs
const MAJOR_LEAGUES = [
  { code: 'eng.1', id: 39, name: 'Premier League', country: 'England', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/23.png' },
  { code: 'esp.1', id: 140, name: 'La Liga', country: 'Spain', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/15.png' },
  { code: 'ita.1', id: 135, name: 'Serie A', country: 'Italy', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/12.png' },
  { code: 'ger.1', id: 78, name: 'Bundesliga', country: 'Germany', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/10.png' },
  { code: 'fra.1', id: 61, name: 'Ligue 1', country: 'France', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/9.png' },
  { code: 'uefa.champions', id: 2, name: 'UEFA Champions League', country: 'Europe', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/2.png' },
  { code: 'uefa.europa', id: 3, name: 'UEFA Europa League', country: 'Europe', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/2035.png' },
  { code: 'uefa.europa.conf', id: 848, name: 'UEFA Conference League', country: 'Europe', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/21021.png' },
  { code: 'uefa.nations', id: 5, name: 'UEFA Nations League', country: 'Europe', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/20963.png' },
  { code: 'eng.fa', id: 45, name: 'FA Cup', country: 'England', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/40.png' },
  { code: 'eng.league_cup', id: 48, name: 'Carabao Cup', country: 'England', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/24.png' },
  { code: 'esp.copa_del_rey', id: 143, name: 'Copa del Rey', country: 'Spain', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/80.png' },
  { code: 'ita.coppa_italia', id: 137, name: 'Coppa Italia', country: 'Italy', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/77.png' },
  { code: 'ger.dfb_pokal', id: 81, name: 'DFB Pokal', country: 'Germany', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/76.png' },
  { code: 'usa.1', id: 253, name: 'MLS', country: 'USA', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/19.png' },
  { code: 'sau.1', id: 307, name: 'Saudi Pro League', country: 'Saudi Arabia', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/2400.png' },
  { code: 'fifa.friendly', id: 10, name: 'International Friendlies', country: 'World', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/60.png' },
  { code: 'fifa.worldq.uefa', id: 32, name: 'World Cup Qualification', country: 'World', logo: 'https://a.espncdn.com/i/leaguelogos/soccer/500/4.png' },
];

/**
 * Normalizes an ESPN Event object into the standard API-Football Fixture format
 */
function normalizeEspnEvent(event, leagueInfo = {}) {
  const comp = event.competitions?.[0] || {};
  const competitors = comp.competitors || [];
  const homeComp = competitors.find(c => c.homeAway === 'home') || competitors[0] || {};
  const awayComp = competitors.find(c => c.homeAway === 'away') || competitors[1] || {};

  const statusType = event.status?.type || {};
  const isLive = statusType.state === 'in';
  const isFinished = statusType.completed === true || statusType.state === 'post';

  let statusShort = 'NS';
  let statusLong = statusType.description || 'Not Started';

  if (isLive) {
    if (statusType.name === 'STATUS_HALFTIME') {
      statusShort = 'HT';
      statusLong = 'Halftime';
    } else {
      statusShort = event.status?.period === 1 ? '1H' : '2H';
      statusLong = statusType.detail || 'In Play';
    }
  } else if (isFinished) {
    statusShort = 'FT';
    statusLong = 'Match Finished';
  }

  let elapsed = null;
  if (event.status?.displayClock) {
    elapsed = parseInt(event.status.displayClock.replace("'", ''));
  } else if (isLive) {
    elapsed = event.status?.clock ? Math.floor(event.status.clock / 60) : 1;
  } else if (isFinished) {
    elapsed = 90;
  }

  const homeScore = homeComp.score != null ? parseInt(homeComp.score) : null;
  const awayScore = awayComp.score != null ? parseInt(awayComp.score) : null;

  const eventDate = event.date || new Date().toISOString();
  const timestamp = Math.floor(new Date(eventDate).getTime() / 1000);

  const homeId = parseInt(homeComp.team?.id) || 1;
  const awayId = parseInt(awayComp.team?.id) || 2;
  const homeLogo = homeComp.team?.logo || `https://a.espncdn.com/i/teamlogos/soccer/500/${homeId}.png`;
  const awayLogo = awayComp.team?.logo || `https://a.espncdn.com/i/teamlogos/soccer/500/${awayId}.png`;

  return {
    fixture: {
      id: parseInt(event.id) || Math.floor(Math.random() * 1000000),
      referee: comp.format?.regulation?.periods ? 'Official Referee' : 'Referee',
      timezone: 'UTC',
      date: eventDate,
      timestamp: timestamp,
      status: {
        long: statusLong,
        short: statusShort,
        elapsed: elapsed,
      },
    },
    league: {
      id: leagueInfo.id || 39,
      name: leagueInfo.name || (event.season?.slug ? event.season.slug.toUpperCase() : 'Football League'),
      country: leagueInfo.country || 'World',
      logo: leagueInfo.logo || (comp.league?.logos?.[0]?.href || 'https://a.espncdn.com/i/leaguelogos/soccer/500/23.png'),
      flag: '',
      season: event.season?.year || 2024,
      round: comp.altGameNote || event.season?.slug || 'Regular Season',
    },
    teams: {
      home: {
        id: homeId,
        name: homeComp.team?.displayName || homeComp.team?.name || 'Home Team',
        logo: homeLogo,
        winner: homeComp.winner ?? null,
      },
      away: {
        id: awayId,
        name: awayComp.team?.displayName || awayComp.team?.name || 'Away Team',
        logo: awayLogo,
        winner: awayComp.winner ?? null,
      },
    },
    goals: {
      home: homeScore,
      away: awayScore,
    },
    score: {
      halftime: {
        home: homeComp.linescores?.[0]?.value != null ? parseInt(homeComp.linescores[0].value) : null,
        away: awayComp.linescores?.[0]?.value != null ? parseInt(awayComp.linescores[0].value) : null,
      },
      fulltime: {
        home: isFinished ? homeScore : null,
        away: isFinished ? awayScore : null,
      },
    },
    isLive: isLive,
  };
}

/**
 * Fetches all live fixtures from the open worldwide feed
 */
async function getLiveFixtures() {
  try {
    // Query worldwide all/scoreboard first
    const r = await axios.get(`${ESPN_BASE}/all/scoreboard`, { timeout: 8000 });
    const events = r.data?.events || [];
    
    // Filter live matches
    const live = events.filter(e => e.status?.type?.state === 'in');
    if (live.length > 0) {
      return live.map(e => normalizeEspnEvent(e));
    }

    // Also check major league feeds in parallel if 'all' returned 0 live
    const majorResults = await Promise.all(
      MAJOR_LEAGUES.slice(0, 8).map(lg =>
        axios.get(`${ESPN_BASE}/${lg.code}/scoreboard`, { timeout: 6000 })
          .then(res => (res.data?.events || []).map(ev => ({ event: ev, league: lg })))
          .catch(() => [])
      )
    );

    const majorEvents = majorResults.flat();
    const majorLive = majorEvents
      .filter(item => item.event.status?.type?.state === 'in')
      .map(item => normalizeEspnEvent(item.event, item.league));

    return majorLive;
  } catch (err) {
    console.error('[espnService] getLiveFixtures error:', err.message);
    return [];
  }
}

/**
 * Fetches fixtures for a specific date (YYYY-MM-DD)
 */
async function getFixturesByDate(dateStr) {
  try {
    const compactDate = dateStr.replace(/-/g, '');
    
    // 1. Try worldwide all/scoreboard with date parameter
    const r = await axios.get(`${ESPN_BASE}/all/scoreboard?dates=${compactDate}`, { timeout: 9000 });
    const events = r.data?.events || [];
    if (events.length > 0) {
      return events.map(e => normalizeEspnEvent(e));
    }

    // 2. Fallback to major leagues in parallel
    const majorResults = await Promise.all(
      MAJOR_LEAGUES.map(lg =>
        axios.get(`${ESPN_BASE}/${lg.code}/scoreboard?dates=${compactDate}`, { timeout: 7000 })
          .then(res => (res.data?.events || []).map(ev => ({ event: ev, league: lg })))
          .catch(() => [])
      )
    );

    const flat = majorResults.flat();
    return flat.map(item => normalizeEspnEvent(item.event, item.league));
  } catch (err) {
    console.error(`[espnService] getFixturesByDate error for ${dateStr}:`, err.message);
    return [];
  }
}

/**
 * Fetches match summary (lineups, events, statistics) by match event ID
 */
async function getMatchSummary(eventId) {
  try {
    const r = await axios.get(`${ESPN_BASE}/all/summary?event=${eventId}`, { timeout: 10000 });
    return r.data;
  } catch (err) {
    console.error(`[espnService] getMatchSummary error for ${eventId}:`, err.message);
    return null;
  }
}

/**
 * Extracts lineups from ESPN match summary into LineupModel format
 */
function extractLineups(summaryData) {
  if (!summaryData) return [];
  const rosters = summaryData.rosters || [];
  const competitors = summaryData.header?.competitions?.[0]?.competitors || [];

  return rosters.map((r, idx) => {
    const comp = competitors.find(c => c.homeAway === r.homeAway) || competitors[idx] || {};
    const teamObj = r.team || comp.team || {};
    const playerList = r.roster || [];

    const startXI = playerList.filter(p => p.starter).map(p => ({
      player: {
        id: parseInt(p.athlete?.id) || Math.floor(Math.random() * 100000),
        name: p.athlete?.displayName || p.athlete?.fullName || 'Player',
        number: parseInt(p.jersey) || 0,
        pos: p.position?.abbreviation || 'M',
        grid: p.formationPlace ? `1:${p.formationPlace}` : null,
      }
    }));

    const substitutes = playerList.filter(p => !p.starter).map(p => ({
      player: {
        id: parseInt(p.athlete?.id) || Math.floor(Math.random() * 100000),
        name: p.athlete?.displayName || p.athlete?.fullName || 'Substitute',
        number: parseInt(p.jersey) || 0,
        pos: p.position?.abbreviation || 'M',
      }
    }));

    return {
      team: {
        id: parseInt(teamObj.id) || (idx + 1),
        name: teamObj.displayName || teamObj.name || 'Team',
        logo: teamObj.logos?.[0]?.href || `https://a.espncdn.com/i/teamlogos/soccer/500/${teamObj.id}.png`,
      },
      formation: r.formation || '4-3-3',
      startXI: startXI,
      substitutes: substitutes,
      coach: {
        id: 1,
        name: r.coach?.[0]?.displayName || 'Head Coach',
        photo: null,
      },
    };
  });
}

/**
 * Extracts match timeline events from ESPN summary into MatchEventModel format
 */
function extractEvents(summaryData) {
  if (!summaryData) return [];
  const details = summaryData.header?.competitions?.[0]?.details || summaryData.plays || [];
  const competitors = summaryData.header?.competitions?.[0]?.competitors || [];

  return details.map(d => {
    const isGoal = d.scoringPlay === true;
    const isRedCard = d.redCard === true;
    const isYellowCard = d.yellowCard === true;
    const isPenalty = d.penaltyKick === true;
    const isSub = d.participants?.length >= 2 && !isGoal;

    let type = 'Goal';
    let detail = 'Normal Goal';

    if (isGoal) {
      type = 'Goal';
      detail = isPenalty ? 'Penalty' : (d.ownGoal ? 'Own Goal' : 'Normal Goal');
    } else if (isRedCard) {
      type = 'Card';
      detail = 'Red Card';
    } else if (isYellowCard) {
      type = 'Card';
      detail = 'Yellow Card';
    } else if (isSub) {
      type = 'subst';
      detail = 'Substitution';
    } else {
      type = 'Event';
      detail = d.text || 'Match Event';
    }

    const elapsed = d.clock?.displayValue ? parseInt(d.clock.displayValue.replace("'", '')) : (d.clock?.value ? Math.floor(d.clock.value / 60) : 0);
    const athlete1 = d.participants?.[0]?.athlete || {};
    const athlete2 = d.participants?.[1]?.athlete || {};

    const teamComp = competitors.find(c => c.team?.id === d.team?.id) || {};

    return {
      time: {
        elapsed: elapsed || 1,
        extra: d.addedClock?.value ? Math.floor(d.addedClock.value / 60) : null,
      },
      team: {
        id: parseInt(d.team?.id) || 0,
        name: d.team?.displayName || d.team?.name || 'Team',
        logo: teamComp.team?.logo || `https://a.espncdn.com/i/teamlogos/soccer/500/${d.team?.id}.png`,
      },
      player: {
        id: parseInt(athlete1.id) || 0,
        name: athlete1.displayName || 'Player',
      },
      assist: {
        id: parseInt(athlete2.id) || null,
        name: athlete2.displayName || null,
      },
      type: type,
      detail: detail,
      comments: null,
    };
  });
}

/**
 * Extracts match statistics from ESPN summary into StatisticModel format
 */
function extractStatistics(summaryData) {
  if (!summaryData) return [];
  const teams = summaryData.boxscore?.teams || [];
  const competitors = summaryData.header?.competitions?.[0]?.competitors || [];

  const stats = [];

  teams.forEach((t, idx) => {
    const comp = competitors.find(c => c.team?.id === t.team?.id) || competitors[idx] || {};
    const teamObj = {
      id: parseInt(t.team?.id || comp.team?.id) || (idx + 1),
      name: t.team?.displayName || comp.team?.displayName || 'Team',
      logo: comp.team?.logo || `https://a.espncdn.com/i/teamlogos/soccer/500/${t.team?.id}.png`,
    };

    const statisticsList = t.statistics || [];
    statisticsList.forEach(s => {
      stats.push({
        team: teamObj,
        type: s.label || s.name,
        value: s.displayValue ?? s.value ?? 0,
      });
    });
  });

  return stats;
}

module.exports = {
  MAJOR_LEAGUES,
  normalizeEspnEvent,
  getLiveFixtures,
  getFixturesByDate,
  getMatchSummary,
  extractLineups,
  extractEvents,
  extractStatistics,
};
