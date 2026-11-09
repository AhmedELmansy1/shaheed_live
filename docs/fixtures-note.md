# Fixtures & Upstream League Teams Audit Note

**Audit Date**: 2026-11-09  
**Upstream Provider**: YsScores (Championship Rank & Standings Feeds)  
**Endpoint**: `GET /api/matches?type=teams&league_id=<id>`

---

## 1. Verified Real Upstream Team Counts

All 8 requested primary leagues were audited directly against real upstream standings (`/ar/championship/<canonicalId>/<slug>-rank`):

| Competition | Season Edition ID (`champ_id`) | Canonical Upstream Slug | Real Scraped Team Count | Status / Verification Note |
|---|---|---|:---:|---|
| **الدوري الإنجليزي الممتاز** (Premier League) | `937599` | `6811/Premier-League` | **20** | Full 20 Premier League clubs parsed |
| **الدوري الإسباني** (La Liga) | `938652` | `1933/LaLiga` | **20** | Full 20 Primera División clubs parsed |
| **الدوري الإيطالي** (Serie A) | `936357` | `3734/Serie-A` | **20** | Full 20 Serie A clubs parsed |
| **الدوري الألماني** (Bundesliga) | `938769` | `2606/Bundesliga` | **18** | Full 18 Bundesliga clubs parsed |
| **الدوري الفرنسي** (Ligue 1) | `937873` | `1985/Ligue-1` | **18** | Full 18 Ligue 1 clubs parsed (18-team format) |
| **الدوري المصري** (Egyptian Premier League) | `943009` | `58553/Egyptian-League` | **20** | Full 20 Egyptian League clubs parsed |
| **الدوري السعودي للمحترفين** (Saudi Pro League) | `941825` | `7167/Saudi-Pro-League` | **18** | Full 18 Saudi Pro League clubs parsed |
| **دوري أبطال أوروبا** (UEFA Champions League) | `943230` | `12048/UEFA-Champions-League` | **36** | Full 36 clubs parsed (new single league phase) |

---

## 2. UEFA Champions League Format Note

Under the revised UEFA Champions League format, the traditional 32-team 8-group stage has been replaced by a single **36-team league phase table** (Swiss-system / single ranking table).  
- All 36 qualified clubs are ranked together in one unified standings table upstream on YsScores.
- Therefore, the full team count for the Champions League is exactly **36 teams**, unlike domestic leagues which have 18 or 20 teams.

---

## 3. Fixture Files Stored

The raw unedited JSON responses fetched directly from upstream have been stored under `test/fixtures/`:
- `test/fixtures/raw_league_teams_937599.json` (Premier League - 20 teams)
- `test/fixtures/raw_league_teams_938652.json` (La Liga - 20 teams)
- `test/fixtures/raw_league_teams_936357.json` (Serie A - 20 teams)
- `test/fixtures/raw_league_teams_938769.json` (Bundesliga - 18 teams)
- `test/fixtures/raw_league_teams_937873.json` (Ligue 1 - 18 teams)
- `test/fixtures/raw_league_teams_943009.json` (Egyptian League - 20 teams)
- `test/fixtures/raw_league_teams_941825.json` (Saudi Pro League - 18 teams)
- `test/fixtures/raw_league_teams_943230.json` (Champions League - 36 teams)
