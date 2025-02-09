<?php
include 'db_connect.php';  // Connect to the database

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$query_number = isset($_GET['query']) ? intval($_GET['query']) : 1;

switch ($query_number) {
    case 1:
        $sql = "SELECT M.Title, CASE 
                    WHEN S.Netflix = 1 THEN 'Netflix' 
                    WHEN S.Hulu = 1 THEN 'Hulu' 
                    WHEN S.PrimeVideo = 1 THEN 'Prime Video' 
                    WHEN S.DisneyPlus = 1 THEN 'Disney+' 
                END AS AvailableOn 
                FROM Movies M 
                JOIN Streaming S ON M.ID = S.ID 
                WHERE (S.Netflix + S.Hulu + S.PrimeVideo + S.DisneyPlus) = 1";
        break;
    case 2:
        $sql = "SELECT M.Title, M.Year 
                FROM Movies M 
                JOIN Streaming S ON M.ID = S.ID 
                JOIN Ages A ON M.ID = A.ID 
                WHERE S.DisneyPlus = 1 AND A.Age = '7+' 
                ORDER BY M.Year DESC 
                LIMIT 5";
        break;
    case 3:
        $sql = "SELECT 'Netflix' AS Platform, ROUND(AVG(R.RottenTomatoes), 2) AS AvgScore 
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
                WHERE S.DisneyPlus = 1";
        break;
    case 4:
        $sql = "SELECT Age, COUNT(*) AS MovieCount 
                FROM Ages 
                GROUP BY Age 
                ORDER BY MovieCount DESC";
        break;
    case 5:
        $sql = "SELECT 'Netflix' AS Platform, COUNT(*) AS MovieCount 
                FROM Streaming WHERE Netflix = 1
                UNION ALL
                SELECT 'Hulu', COUNT(*) 
                FROM Streaming WHERE Hulu = 1
                UNION ALL
                SELECT 'PrimeVideo', COUNT(*) 
                FROM Streaming WHERE PrimeVideo = 1
                UNION ALL
                SELECT 'DisneyPlus', COUNT(*) 
                FROM Streaming WHERE DisneyPlus = 1";
        break;
    case 6:
        $sql = "SELECT M.Title, M.Year, R.RottenTomatoes 
                FROM Movies M 
                JOIN Ratings R ON M.ID = R.ID 
                WHERE R.RottenTomatoes <> 'Unknown' 
                AND R.RottenTomatoes = (
                    SELECT MAX(R2.RottenTomatoes) 
                    FROM Ratings R2 
                    JOIN Movies M2 ON R2.ID = M2.ID 
                    WHERE M2.Year = M.Year AND R2.RottenTomatoes <> 'Unknown'
                )
                ORDER BY M.Year DESC";
        break;
    case 7:
        $sql = "WITH RankedMovies AS (
                    SELECT M.Title, A.Age, R.RottenTomatoes,
                    RANK() OVER (PARTITION BY A.Age ORDER BY R.RottenTomatoes DESC) AS HighestRank,
                    RANK() OVER (PARTITION BY A.Age ORDER BY R.RottenTomatoes ASC) AS LowestRank
                    FROM Movies M
                    JOIN Ratings R ON M.ID = R.ID
                    JOIN Ages A ON M.ID = A.ID
                    WHERE R.RottenTomatoes <> 'Unknown'
                )
                SELECT Title, Age, RottenTomatoes,
                CASE 
                    WHEN HighestRank = 1 THEN 'Highest Rated'
                    WHEN LowestRank = 1 THEN 'Lowest Rated'
                END AS RatingCategory
                FROM RankedMovies
                WHERE HighestRank = 1 OR LowestRank = 1
                ORDER BY Age, RottenTomatoes DESC";
        break;
    case 8:
        $sql = "SELECT 'Netflix' AS Platform, COUNT(*) AS MovieCount, 
                       ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM Movies), 2) AS Percentage 
                FROM Streaming WHERE Netflix = 1
                UNION ALL
                SELECT 'Hulu', COUNT(*), 
                       ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM Movies), 2) 
                FROM Streaming WHERE Hulu = 1
                UNION ALL
                SELECT 'Prime Video', COUNT(*), 
                       ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM Movies), 2) 
                FROM Streaming WHERE PrimeVideo = 1
                UNION ALL
                SELECT 'Disney+', COUNT(*), 
                       ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM Movies), 2) 
                FROM Streaming WHERE DisneyPlus = 1";
        break;
    case 9:
    $sql = "SELECT M.Title, R.RottenTomatoes, 
                   CASE 
                       WHEN S.Netflix = 1 THEN 'Netflix'
                       WHEN S.Hulu = 1 THEN 'Hulu'
                       WHEN S.PrimeVideo = 1 THEN 'Prime Video'
                       WHEN S.DisneyPlus = 1 THEN 'Disney+'
                   END AS Platform
            FROM Movies M
            JOIN Ratings R ON M.ID = R.ID
            JOIN Streaming S ON M.ID = S.ID
            WHERE (S.Netflix = 1 OR S.Hulu = 1 OR S.PrimeVideo = 1 OR S.DisneyPlus = 1)
            AND R.RottenTomatoes <> 'Unknown'
            ORDER BY R.RottenTomatoes DESC
            LIMIT 20";
    break;

    case 10:
        $sql = "SELECT CASE 
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
                ORDER BY Platform, MovieCount DESC";
        break;
    default:
        $sql = "SELECT * FROM Movies LIMIT 10";  // Default query
}

$result = $conn->query($sql);

$data = array();
if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $data[] = $row;
    }
}

echo json_encode($data);

$conn->close();
?>
