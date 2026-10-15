# Do Lichess Ratings Predict Who Wins?\

## Status: in progress. Data validation underway.

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
  `BlackTitle` appear only when a titled player is in the game
  (WhiteTitle: 30,424 games, BlackTitle: 30,424 games).
- The full extract wrote 4,770,357 games, matching the official count, in 1.7 minutes.
- All 4,770,357 games fall between 2015-12-31 23:00:00 and 2016-01-31 22:59:59 UTC, verified across every game. The 5,124 games (0.11%) dated Dec 31 UTC are consistent with Lichess cutting monthly files at midnight Central European Time, and are kept.
- Titles include Lichess's own honorary "LM" title alongside official FIDE and national titles.
- Missing values are written as `"?"` (for example, ECO and Opening), not left blank.
- 2016 opening names use numbered suffixes (#2) and commas; normalized into 168 families (from 349).
- "Abandoned” games ended because a player left; some contain moves, some don’t.
- `Event` combines speed and tournament status, and no "Rapid" category exists
  in 2016, so speed is derived from `TimeControl` instead.
- Arena tournaments allow "berserk" (a player halves their own clock), so
  `TimeControl` can overstate the actual time in tournament games.
- Of the 1,230,129 games labeled “Classical” in 2016, 93% are Rapid by modern rules.
- Titled players appear in 57,924 games (1.2%): WhiteTitle is present in 30,424 games and BlackTitle in 30,424, with 2,924 games where both players are titled. Oddly, the counts are exactly symmetric by color (27,500 games each). Observed but not investigated further.

## Cleaning decisions
- Checked for duplicates: none found, 0 games removed

## Findings
To come.

## Limitations
- Glicko-2 ratings tested against the Elo formula
- One month of data
- Players choose their own openings
- Online play, not over-the-board

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