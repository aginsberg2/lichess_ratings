# Do Lichess Ratings Predict Who Wins?

## Status: in progress. Clean table built and verified; analysis next.

## Question
How well does the standard Elo win-probability formula,
1 / (1 + 10^(−gap/400)), predict game outcomes from Lichess ratings,
and where does the prediction break down?

Note: Lichess ratings use the Glicko-2 system, not Elo. This project tests
whether the Elo *formula* still predicts results from Glicko-2 ratings.

## Data
- Source: [Lichess open database](https://database.lichess.org/) (CC0 license)
- Month: January 2016, standard rated games
- Official game count: 4,770,357
- Download:
```bash
  curl -L -o data/raw/lichess_db_standard_rated_2016-01.pgn.zst https://database.lichess.org/standard/lichess_db_standard_rated_2016-01.pgn.zst
```
- Integrity: SHA-256 checksum verified against Lichess's published value

## Data notes (running log)
- A survey of every header in the full file found 17 fields. `WhiteTitle` and
  `BlackTitle` appear only when a titled player is in the game. Titled players appear in 57,924 games (1.2%): WhiteTitle is present in 30,424 games and BlackTitle in 30,424, with 2,924 games where both players are titled. Oddly, the counts are exactly symmetric by color (27,500 games each). Observed but not investigated further.
- The full extract wrote 4,770,357 games, matching the official count, in 1.7 minutes.
- All 4,770,357 games fall between 2015-12-31 23:00:00 and 2016-01-31 22:59:59 UTC, verified across every game. The 5,124 games (0.11%) dated Dec 31 UTC are consistent with Lichess cutting monthly files at midnight Central European Time, and are kept.
- Titles include Lichess's own honorary "LM" title alongside official FIDE and national titles.
- Missing values are written as `"?"` (for example, ECO and Opening), not left blank.
- 2016 opening names use numbered suffixes (#2) and commas; normalized into 168 families (from 349).
- 'Abandoned' games ended because a player left; some contain moves, some don’t.
- `Event` combines speed and tournament status, and no "Rapid" category exists
  in 2016, so speed is derived from `TimeControl` instead.
- Arena tournaments allow "berserk" (a player halves their own clock), so
  `TimeControl` can overstate the actual time in tournament games.
- Of the 1,230,129 games labeled “Classical” in 2016, 93% are Rapid by modern rules.
- No games qualify as UltraBullet.
- The 1500 rating has 40540 games, about 8 times more than all the other Elo values 1490-1510, which are around 5000 games. 70,899 games (1.5%) have at least one player at 1500.
- Opening and ECO are missing (?) together in 14,496 games, mostly abandoned games; no ECO code has an invalid format.


- ## Cleaning decisions
All cleaning is applied in `sql/02_clean.sql`, which builds `games_clean` from `games_raw`.
The evidence for each decision is in `notebooks/02_load_validate.ipynb`.

### Removed: 20,410 games (0.43%)
| Reason | Games | Why |
|---|---|---|
| Termination was Abandoned or Rules infraction | 20,373 | The result wasn't decided by play |
| A player's rating is missing (`?`) | 37 | The Elo formula needs both ratings |
| Overlap between the two | 0 | |

`games_clean` has **4,749,947 games**, matching the count calculated before the table was built.

### Kept, but labeled
| What | Games | Label | Why kept |
|---|---|---|---|
| A player at the 1500 starting rating | 70,346 | `has_placeholder_rating` | To measure their effect with a sensitivity analysis, rather than assume it |
| Correspondence games (no clock) | 20,898 | `speed_category = 'Correspondence'` | Different rules and rating pool; analyzed separately from timed games |
| Missing opening | 2,974 | `opening_family` is `NULL` | Calibration doesn't use openings; excluded from the opening analysis only |
| Tournament games | 872,647 | `is_tournament` | Berserk can shorten a player's clock |

### Transformed
- Ratings, clock settings, and timestamps converted from text to numbers and timestamps.
- `?` converted to `NULL`, SQL's standard missing value.
- Speed categories follow Lichess's current rule (base + 40 × increment), applied consistently. 93% of games labeled "Classical" in 2016 are Rapid by this rule.
- Opening families normalized from 2016 naming (`#2` suffixes, commas): 349 → 168 families. King's Gambit Accepted and Declined are kept as separate families.
- Each result scored from White's perspective: 1, 0.5, or 0.

### Deliberately left out
- `WhiteRatingDiff`, `BlackRatingDiff`: calculated after the game, from its result. Filtering on them would remove upsets disproportionately and make the formula look more accurate than it is.
- `Event`, `UTCDate`, `UTCTime`, `TimeControl`: replaced by the derived columns above.

### Verification
- Every game is unique; no missing ratings, scores, or timestamps; only Normal and Time forfeit terminations; every result matches exactly one score; no uncategorized games.
- The removed games total 20,410 whether counted by termination, by result, or by speed category.
- **Side effect:** the removed games were disproportionately Black wins (11,537 vs. 8,868 White wins), likely because a White player who abandons before moving loses. Excluding them raised White's overall score slightly, from 51.56% to 51.60%.

## Findings
To come.

## Limitations
- Glicko-2 ratings tested against the Elo formula
- One month of data
- Players choose their own openings
- Online play, not over-the-board
- The flag only catches each player’s first game in a time control, so the true effect of unreliable ratings is likely larger. Lichess keeps a separate rating per time control, so 1500 also marks experienced players new to a speed.

## How to reproduce
Requires Python 3 and a few GB of free disk space. Commands are for macOS/Linux.
Run everything from the project root.

1. **Get the code**
```bash
   git clone https://github.com/aginsberg2/lichess-ratings.git
   cd lichess-ratings
```
2. **Create an environment and install dependencies**
```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
```
3. **Download the data**
```bash
   mkdir -p data/raw data/processed
   curl -L -o data/raw/lichess_db_standard_rated_2016-01.pgn.zst https://database.lichess.org/standard/lichess_db_standard_rated_2016-01.pgn.zst
```
4. **Verify download (optional but recommended)**
```bash
   shasum -a 256 data/raw/lichess_db_standard_rated_2016-01.pgn.zst
```
   Compare with the 2016-01 entry in
   [Lichess's published checksums](https://database.lichess.org/standard/sha256sums.txt).
   
5. **Extract game headers to CSV**
```bash
   python src/extract_headers.py
```
   Expected output: `Wrote 4,770,357 games to data/processed/games.csv` (about 2 minutes for me).
   
6. **Load and analyze in DuckDB**: to come. SQL files in `sql/` run in numbered order.