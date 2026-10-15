-- 02_clean.sql
-- Builds games_clean from games_raw, applying the decisions from validation
-- (see notebooks/02_load_validate.ipynb).
-- Excludes: Abandoned and Rules infraction games (20,373), unusable ratings (37). Overlap: 0.
-- Keeps but labels: correspondence games, 1500 placeholder ratings (flag), missing openings (NULL).
-- Expected rows: 4,749,947.

CREATE OR REPLACE TABLE games_clean AS
WITH parsed AS (
    SELECT
        Site AS game_url,
        try_strptime(UTCDate || ' ' || UTCTime, '%Y.%m.%d %H:%M:%S') AS played_at,
        White AS white_player,
        Black AS black_player,
        TRY_CAST(WhiteElo AS INTEGER) AS white_rating,
        TRY_CAST(BlackElo AS INTEGER) AS black_rating,
        Result AS result,
        Termination AS termination,
        TRY_CAST(split_part(TimeControl, '+', 1) AS INTEGER) AS base_seconds,
        TRY_CAST(split_part(TimeControl, '+', 2) AS INTEGER) AS increment_seconds,
        TRY_CAST(split_part(TimeControl, '+', 1) AS INTEGER) + 40*(TRY_CAST(split_part(TimeControl, '+', 2) AS INTEGER)) AS estimated_duration_seconds,
        Event LIKE '%tournament%' AS is_tournament,
        NULLIF(ECO, '?') AS eco,
        NULLIF(Opening, '?') AS opening_name,
        WhiteTitle AS white_title,
        BlackTitle AS black_title
    FROM games_raw
)
SELECT 
    game_url, 
    played_at, 
    white_player, 
    black_player, 
    white_rating, 
    black_rating, 
    white_rating - black_rating AS rating_gap,
    result,
    CASE 
        WHEN result = '1-0' THEN 1.0
        WHEN result = '1/2-1/2' THEN 0.5
        WHEN result = '0-1' THEN 0.0
        ELSE NULL
    END AS white_score,
    termination,
    base_seconds,
    increment_seconds,
    CASE 
        WHEN base_seconds IS NULL THEN 'Correspondence'
        WHEN estimated_duration_seconds <= 29 THEN 'UltraBullet'
        WHEN estimated_duration_seconds <= 179 THEN 'Bullet'
        WHEN estimated_duration_seconds <= 479 THEN 'Blitz'
        WHEN estimated_duration_seconds <= 1499 THEN 'Rapid'
        WHEN estimated_duration_seconds >= 1500 THEN 'Classical'
        ELSE 'Unknown'
    END AS speed_category,
    is_tournament,
    eco,
    opening_name,
    regexp_replace(split_part(split_part(opening_name, ':', 1), ',', 1), ' #[0-9]+$', '') AS opening_family,
    white_title,
    black_title,
    CASE WHEN white_rating = 1500 OR black_rating = 1500 THEN true ELSE false END AS has_placeholder_rating
FROM parsed
WHERE NOT(white_rating IS NULL OR black_rating IS NULL) AND termination NOT IN ('Abandoned', 'Rules infraction');
