# Do Lichess Ratings Predict Who Wins?

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
  (WhiteTitle: ___ games, BlackTitle: ___ games).
- The full extract wrote 4,770,357 games, matching the official count, in 1.7 minutes.
- The file spans 23:00 UTC Dec 31 to 23:00 UTC Jan 31, likely because months are cut at midnight Central European Time (to be confirmed in Step 12).
- Titles include Lichess's own honorary "LM" title alongside official FIDE and national titles.
- Missing values are written as `"?"` (for example, ECO and Opening), not left blank.
- Abandoned games contain no moves but are still rated.
- `Event` combines speed and tournament status, and no "Rapid" category exists
  in 2016, so speed is derived from `TimeControl` instead.
- Arena tournaments allow "berserk" (a player halves their own clock), so
  `TimeControl` can overstate the actual time in tournament games.
- The file begins with games dated 2015-12-31.

## Cleaning decisions
To come (Step 12), each with the number of games it removes.

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