
use 4587229_final;

-- 1. Movies available only on one streaming platform: 
DROP PROCEDURE IF EXISTS GetTopMoviesByPlatform;

SELECT 
    M.Title,
    CASE 
        WHEN S.Netflix = 1 THEN 'Netflix'
        WHEN S.Hulu = 1 THEN 'Hulu'
        WHEN S.PrimeVideo = 1 THEN 'Prime Video'
        WHEN S.DisneyPlus = 1 THEN 'Disney+'
    END AS AvailableOn
FROM Movies M
JOIN Streaming S ON M.ID = S.ID
WHERE (S.Netflix + S.Hulu + S.PrimeVideo + S.DisneyPlus) = 1;


-- 2. 5 newest PG (age 7+) movies on all platforms:

SELECT M.Title, M.Year
FROM Movies M
JOIN Streaming S ON M.ID = S.ID
JOIN Ages A ON M.ID = A.ID
WHERE S.DisneyPlus = 1
AND A.Age = '7+'
ORDER BY M.Year DESC, M.Title
LIMIT 5;

SELECT M.Title, M.Year
FROM Movies M
JOIN Streaming S ON M.ID = S.ID
JOIN Ages A ON M.ID = A.ID
WHERE S.Netflix = 1
AND A.Age = '7+'
ORDER BY M.Year DESC, M.Title
LIMIT 5;

SELECT M.Title, M.Year
FROM Movies M
JOIN Streaming S ON M.ID = S.ID
JOIN Ages A ON M.ID = A.ID
WHERE S.Hulu = 1
AND A.Age = '7+'
ORDER BY M.Year DESC, M.Title
LIMIT 5;

SELECT M.Title, M.Year
FROM Movies M
JOIN Streaming S ON M.ID = S.ID
JOIN Ages A ON M.ID = A.ID
WHERE S.PrimeVideo = 1
AND A.Age = '7+'
ORDER BY M.Year DESC, M.Title
LIMIT 5;

-- 3. Average Rotten Tomatoes Score for Each Streaming Platform

SELECT 'Netflix' AS Platform, ROUND(AVG(R.RottenTomatoes), 2) AS AvgScore
FROM Ratings R
JOIN Streaming S ON R.ID = S.ID
WHERE S.Netflix = 1
UNION ALL
SELECT 'Hulu', ROUND(AVG(R.RottenTomatoes), 2)
FROM Ratings R
JOIN Streaming S ON R.ID = S.ID
WHERE S.Hulu = 1
UNION ALL
SELECT 'PrimeVideo', ROUND(AVG(R.RottenTomatoes), 2)
FROM Ratings R
JOIN Streaming S ON R.ID = S.ID
WHERE S.PrimeVideo = 1
UNION ALL
SELECT 'DisneyPlus', ROUND(AVG(R.RottenTomatoes), 2)
FROM Ratings R
JOIN Streaming S ON R.ID = S.ID
WHERE S.DisneyPlus = 1;

-- 4. Count of movies per age rating 

SELECT Age, COUNT(*) AS MovieCount
FROM Ages
GROUP BY Age
ORDER BY MovieCount DESC;

-- 5. Count of Movies Available on Each Streaming Platform

SELECT 
    'Netflix' AS Platform, COUNT(*) AS MovieCount
FROM Streaming WHERE Netflix = 1
UNION ALL
SELECT 
    'Hulu', COUNT(*)
FROM Streaming WHERE Hulu = 1
UNION ALL
SELECT 
    'PrimeVideo', COUNT(*)
FROM Streaming WHERE PrimeVideo = 1
UNION ALL
SELECT 
    'DisneyPlus', COUNT(*)
FROM Streaming WHERE DisneyPlus = 1;

-- 6. Highest rated movie per year

SELECT M.Title, M.Year, R.RottenTomatoes
FROM Movies M
JOIN Ratings R ON M.ID = R.ID
WHERE R.RottenTomatoes <> 'Unknown'
AND R.RottenTomatoes = (
    SELECT MAX(R2.RottenTomatoes)
    FROM Ratings R2
    JOIN Movies M2 ON R2.ID = M2.ID
    WHERE M2.Year = M.Year
    AND R2.RottenTomatoes <> 'Unknown'
)
ORDER BY M.Year DESC;


-- 7. Highest and lowest rating per age group 

WITH RankedMovies AS (
    SELECT 
        M.Title, 
        A.Age, 
        R.RottenTomatoes,
        RANK() OVER (PARTITION BY A.Age ORDER BY R.RottenTomatoes DESC) AS HighestRank,
        RANK() OVER (PARTITION BY A.Age ORDER BY R.RottenTomatoes ASC) AS LowestRank
    FROM Movies M
    JOIN Ratings R ON M.ID = R.ID
    JOIN Ages A ON M.ID = A.ID
    WHERE R.RottenTomatoes <> 'Unknown'
    AND A.Age <> 'Unknown'  -- Exclude movies with "Unknown" age rating
)
SELECT 
    Title, 
    Age, 
    RottenTomatoes, 
    CASE 
        WHEN HighestRank = 1 THEN 'Highest Rated'
        WHEN LowestRank = 1 THEN 'Lowest Rated'
    END AS RatingCategory
FROM RankedMovies
WHERE HighestRank = 1 OR LowestRank = 1
ORDER BY Age, RottenTomatoes DESC;

-- 8. Calculate the percentage of movies available on each streaming platform compared to the total number of movies:

SELECT 
    'Netflix' AS Platform, 
    COUNT(*) AS MovieCount, 
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM Movies), 2) AS Percentage
FROM Streaming WHERE Netflix = 1
UNION ALL
SELECT 
    'Hulu', 
    COUNT(*), 
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM Movies), 2)
FROM Streaming WHERE Hulu = 1
UNION ALL
SELECT 
    'Prime Video', 
    COUNT(*), 
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM Movies), 2)
FROM Streaming WHERE PrimeVideo = 1
UNION ALL
SELECT 
    'Disney+', 
    COUNT(*), 
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM Movies), 2)
FROM Streaming WHERE DisneyPlus = 1;

-- 9. Stored Procedure: Get Top Rated Movies by Platform
DELIMITER //

CREATE PROCEDURE GetTopMoviesByPlatform(
    IN platform_name VARCHAR(20),
    IN limit_num INT
)
BEGIN
    SET @query = CONCAT(
        'SELECT M.Title, R.RottenTomatoes 
         FROM Movies M
         JOIN Ratings R ON M.ID = R.ID
         JOIN Streaming S ON M.ID = S.ID
         WHERE S.', platform_name, ' = 1
         AND R.RottenTomatoes <> "Unknown"
         ORDER BY R.RottenTomatoes DESC
         LIMIT ', limit_num  -- Directly inserting limit value
    );

    PREPARE stmt FROM @query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END;

//

DELIMITER ;

CALL GetTopMoviesByPlatform('Netflix', 5);
CALL GetTopMoviesByPlatform('Hulu', 10);
CALL GetTopMoviesByPlatform('DisneyPlus', 20);
CALL GetTopMoviesByPlatform('PrimeVideo', 3);


-- 10. Count of movies per age group 

SELECT 
    CASE 
        WHEN S.Netflix = 1 THEN 'Netflix'
        WHEN S.Hulu = 1 THEN 'Hulu'
        WHEN S.PrimeVideo = 1 THEN 'Prime Video'
        WHEN S.DisneyPlus = 1 THEN 'Disney+'
    END AS Platform,
    A.Age,
    COUNT(*) AS MovieCount
FROM Movies M
JOIN Streaming S ON M.ID = S.ID
JOIN Ages A ON M.ID = A.ID
WHERE A.Age IN ('7+', 'all', '13+', '16+', '18+')
GROUP BY Platform, A.Age
ORDER BY Platform, MovieCount DESC;



