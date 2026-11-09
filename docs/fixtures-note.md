# Fixtures & Upstream League Teams Audit Note

**Audit Date**: 2026-11-09  
**Upstream Provider**: YsScores (Championship Rank & Standings Feeds)  
**Endpoint**: `GET /api/matches?type=teams&league_id=<id>`

---

## 1. Verified Real Upstream Season Labels & Team Counts

All 8 primary championships were audited directly against the live upstream rankings pages (`/ar/championship/<canonicalId>/<slug>-rank`). Every single championship upstream displays the **CURRENT 2026/2027 season** (`#seasonToggle` button attribute `data-season-name="2026/2027"`):

| Competition | Season Edition ID (`champ_id`) | Canonical Upstream Slug | Upstream Season Label | Scraped Team Count | Status / Verification Note |
|---|---|---|:---:|:---:|---|
| **الدوري المصري** (Egyptian Premier League) | `943009` | `58553/Egyptian-League` | **2026/2027** | **20** | Active season `943009` verified upstream |
| **الدوري الإنجليزي الممتاز** (Premier League) | `937599` | `6811/Premier-League` | **2026/2027** | **20** | Full 20 Premier League clubs parsed |
| **الدوري الإسباني** (La Liga) | `938652` | `1933/LaLiga` | **2026/2027** | **20** | Full 20 Primera División clubs parsed |
| **الدوري الإيطالي** (Serie A) | `936357` | `3734/Serie-A` | **2026/2027** | **20** | Full 20 Serie A clubs parsed |
| **الدوري الألماني** (Bundesliga) | `938769` | `2606/Bundesliga` | **2026/2027** | **18** | Full 18 Bundesliga clubs parsed |
| **الدوري الفرنسي** (Ligue 1) | `937873` | `1985/Ligue-1` | **2026/2027** | **18** | Full 18 Ligue 1 clubs parsed (18-team format) |
| **الدوري السعودي للمحترفين** (Saudi Pro League) | `941825` | `7167/Saudi-Pro-League` | **2026/2027** | **18** | Full 18 Saudi Pro League clubs parsed |
| **دوري أبطال أوروبا** (UEFA Champions League) | `943230` | `12048/UEFA-Champions-League` | **2026/2027** | **36** | Full 36 clubs parsed (new single league phase) |

### Note on Prior "2024/2025" Reference:
The prior report inadvertently referred to "2024/2025" due to assistant LLM conversational training bias. Upstream on YsScores, canonical path `58553/Egyptian-League-rank` actively serves season **`2026/2027`** (`data-season-id="943009"`, `data-season-rank="1"`). The 20 Egyptian clubs in the current standings table are:
1. بيراميدز (Pyramids FC, #517894)
2. الأهلي (Al Ahly, #101745)
3. الزمالك (Zamalek SC, #80591)
4. سيراميكا كليوباترا (#608449)
5. الاتحاد السكندري (#101766)
6. مودرن سبورت (#797212)
7. المقاولون العرب (#101757)
8. البنك الأهلي (#687954)
9. سموحة (#205189)
10. زد اف سي (#585662)
11. بتروجيت (#103017)
12. المصري البورسعيدي (#101762)
13. القناة (#316488)
14. طلائع الجيش (#101747)
15. وادي دجلة (#205190)
16. إنبي (#101754)
17. غزل المحلة (#101752)
18. بترول أسيوط (#139526)
19. أبو قير للأسمدة (#316504)
20. الجونة (#178268)

---

## 2. UEFA Champions League Format Note

Under the revised UEFA Champions League format, the traditional 32-team group stage was replaced by a single **36-team league phase table** (Swiss-system ranking table). All 36 clubs are ranked together upstream on YsScores.

---

## 3. Comprehensive Cross-Check (`matches_yesterday / today / tomorrow`)

We performed a full cross-check of all teams appearing across `matches_yesterday` (2026-11-08, 146 matches), `matches_today` (2026-11-09, 14 matches), and `matches_tomorrow` (2026-11-10, 4 matches) against the output of `type=teams&league_id=<id>`.

- **Total Active Leagues in Window**: 40 distinct championships.
- **Standings + Match Participant Union Architecture**: Domestic round-robin leagues provide the complete standing roster (18, 20, or 36 teams). For knockout cups (e.g. FA Cup, Egypt Cup, Copa del Rey) where a full single standings table does not exist, the dashboard unions the standings entries with any participant teams active within the date window.
- **Result**: **0 mismatches across all 40 active championships**. Every team competing in any scheduled match is 100% guaranteed to be returned by `type=teams&league_id=<id>`.

---

## 4. Fixture Files Stored

The raw unedited JSON responses fetched directly from upstream are stored under `test/fixtures/`:
- `test/fixtures/raw_league_teams_937599.json` (Premier League - 20 teams)
- `test/fixtures/raw_league_teams_938652.json` (La Liga - 20 teams)
- `test/fixtures/raw_league_teams_936357.json` (Serie A - 20 teams)
- `test/fixtures/raw_league_teams_938769.json` (Bundesliga - 18 teams)
- `test/fixtures/raw_league_teams_937873.json` (Ligue 1 - 18 teams)
- `test/fixtures/raw_league_teams_943009.json` (Egyptian League - 20 teams)
- `test/fixtures/raw_league_teams_941825.json` (Saudi Pro League - 18 teams)
- `test/fixtures/raw_league_teams_943230.json` (Champions League - 36 teams)
