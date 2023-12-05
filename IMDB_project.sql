
USE imdb;

-- The shape of the tables 'movies' and 'genre'.*/
DESC movie;
DESC genre;


-- Segment 1:

-- 1. Looking at the total number of rows in each table of the schema

SELECT table_name, table_rows from INFORMATION_SCHEMA.tables
WHERE TABLE_SCHEMA = 'imdb';



-- 2. Columns in the movie table having null values

SELECT COUNT(CASE WHEN title IS NULL THEN id END) AS null_title,
       COUNT(CASE WHEN year IS NULL THEN id END) AS null_year,
       COUNT(CASE WHEN date_published IS NULL THEN id END) AS null_date_published,
       COUNT(CASE WHEN duration IS NULL THEN id END) AS null_duration,
       COUNT(CASE WHEN country IS NULL THEN id END) AS null_country,
       COUNT(CASE WHEN worlwide_gross_income IS NULL THEN id END) AS null_worldwide_gross_income,
       COUNT(CASE WHEN languages IS NULL THEN id END) AS null_languages,
       COUNT(CASE WHEN production_company IS NULL THEN id END) AS null_production_company
FROM movie;       


-- 3. Looking at the at the total number of movies released each year and the trend month-wise

SELECT 
    Year, COUNT(*) AS number_of_movies 
FROM movie 
GROUP BY Year;

SELECT 
    MONTH(date_published) AS month_num, COUNT(*) AS number_of_movies 
FROM movie 
GROUP BY MONTH(date_published)
ORDER BY month_num;

-- The highest number of movies is produced in the month of March.


-- 4. Looking at the different genres present in the dataset.

SELECT 
    DISTINCT genre 
FROM genre;


-- 5. Genre with the highest number of movies produced overall

SELECT 
     genre, COUNT(movie_id) AS Number_of_movies
FROM genre
GROUP BY genre
ORDER BY COUNT(movie_id) DESC
LIMIT 1;

-- The genre 'Drama' has the highest number of movies

   

-- 6. The average duration of movies in each genre

SELECT 
     genre, ROUND(AVG(duration),2) AS avg_duration
FROM movie m
INNER JOIN genre g
ON m.id = g.movie_id
GROUP BY genre
ORDER BY  avg_duration DESC;

-- Movies of genre 'Drama' has the average duration of 106.77 mins




-- Segment 2:

-- 7. Finding the minimum and maximum values in each column of the ratings table except the movie_id column

SELECT 
      MIN(avg_rating) AS min_avg_rating,  MAX(avg_rating) AS max_avg_rating, MIN(total_votes) AS min_total_votes,
       MAX(total_votes) AS max_total_votes, MIN(median_rating) AS min_median_rating, MAX(median_rating) AS max_median_rating
FROM ratings;

-- The minimum and maximum values in each column of the ratings table are in the expected range (1 and 10 respectively).
-- This implies there are no outliers in the table. 

   

-- 8. The top 10 movies based on average rating?

SELECT 
     title, avg_rating, 
     RANK() OVER(ORDER BY avg_rating DESC) AS movie_rank
FROM movie m
INNER JOIN ratings r
ON m.id = r.movie_id 
LIMIT 10;    
     
-- So, now that we know the top 10 movies, character actors and filler actors can be from these movies    




-- Now, looking at the production house with which RSVP Movies can partner for its next project.

-- 9. Production house has produced the most number of hit movies (average rating > 8)

WITH top_prod_company AS 
(
  SELECT 
        production_company, COUNT(movie_id) AS movie_count, 
        RANK() OVER(ORDER BY COUNT(movie_id) DESC) AS prod_company_rank
  FROM ratings r
  INNER JOIN movie m
  ON m.id = r.movie_id
  WHERE avg_rating > 8 AND production_company IS NOT NULL
  GROUP BY production_company)
SELECT * 
FROM top_prod_company
WHERE prod_company_rank = (SELECT MIN(prod_company_rank) FROM top_prod_company); 

-- It is Dream Warrior Pictures and National Theatre Live



-- Segment 3:

-- Now looking at the names table.

-- 10. Columns in the names table have null values

SELECT COUNT(CASE WHEN name IS NULL THEN id END) AS name_nulls,
       COUNT(CASE WHEN height IS NULL THEN id END) AS height_nulls,
       COUNT(CASE WHEN date_of_birth IS NULL THEN id END) AS date_of_birth_nulls,
       COUNT(CASE WHEN known_for_movies IS NULL THEN id END) AS known_for_movies_nulls    
FROM names;



-- 11. The top three directors in the top three genres whose movies have an average rating > 8 who can be hired by RSVP Movies.

WITH top_3_genre AS
(SELECT 
      genre
FROM ratings r
	  INNER JOIN movie m
      ON m.id = r.movie_id
      INNER JOIN genre g
      ON g.movie_id = m.id
WHERE avg_rating > 8
GROUP BY genre
ORDER BY COUNT(g.movie_id) DESC
LIMIT 3)

SELECT 
      name AS director_name, COUNT( distinct d.movie_id) AS movie_count               
FROM director_mapping d
	  INNER JOIN genre g
      ON g.movie_id = d.movie_id
      INNER JOIN names n
      ON n.id = d.name_id 
      INNER JOIN top_3_genre
	  USING (genre)
      INNER JOIN ratings r
      ON r.movie_id = d.movie_id
WHERE avg_rating > 8 
GROUP BY name
ORDER BY COUNT(d.movie_id) DESC, director_name
LIMIT 3;


-- 12. The top two actors whose movies have a median rating >= 8 

SELECT 
      name AS actor_name, COUNT(m.movie_id) AS movie_count
FROM role_mapping m
	 INNER JOIN names n
     ON m.name_id = n.id
     INNER JOIN ratings r
     ON r.movie_id = m.movie_id
WHERE median_rating >=8 AND category = 'actor'
GROUP BY name
ORDER BY movie_count desc
LIMIT 2;



-- 13. Looking at the top three production houses in the world based on the number of votes received by their movies, as RSVP Movies plans to partner with other global production houses

SELECT 
       production_company, SUM(total_votes) AS vote_count, 
       RANK() OVER(ORDER BY SUM(total_votes) DESC) AS prod_comp_rank
FROM movie m       
     INNER JOIN ratings r
     ON r.movie_id = m.id
GROUP BY production_company
LIMIT 3;




-- 14. Ranking actors with movies released in India based on their average ratings. (using weighted average based on votes)
-- Note: The actor should have acted in at least five Indian movies. 

SELECT 
       name as actor_name, SUM(total_votes) AS total_votes, COUNT(m.id) AS movie_count, ROUND(SUM(avg_rating * total_votes)/ SUM(total_votes),2) AS actor_avg_rating, 
       RANK() OVER(ORDER BY ROUND(SUM(avg_rating * total_votes)/ SUM(total_votes),2) DESC, SUM(total_votes) DESC) AS actor_rank
FROM movie m
     INNER JOIN ratings r
     ON r.movie_id = m.id
     INNER JOIN role_mapping rm   
     ON rM.movie_id = m.id
	 INNER JOIN names n
	 ON n.id = rm.name_id  
WHERE country like '%India' AND category = 'actor'
GROUP BY name
HAVING COUNT(m.id) >=5;

-- Top actor is Vijay Sethupathi

-- 15. Top five actresses in Hindi movies released in India based on their average ratings. (using weighted average based on votes)
-- Note: The actresses should have acted in at least three Indian movies. 

SELECT 
       name as actor_name, SUM(total_votes) AS total_votes, COUNT(m.id) AS movie_count, ROUND(SUM(avg_rating * total_votes)/ SUM(total_votes),2) AS actor_avg_rating, 
       RANK() OVER(ORDER BY ROUND(SUM(avg_rating * total_votes)/ SUM(total_votes),2) DESC, SUM(total_votes) DESC) AS actress_rank
FROM movie m
     INNER JOIN ratings r
     ON r.movie_id = m.id
     INNER JOIN role_mapping rm   
     ON rM.movie_id = m.id
	 INNER JOIN names n
	 ON n.id = rm.name_id  
WHERE languages like '%hindi%' AND country like '%INdia%' AND category = 'actress'
GROUP BY name
HAVING COUNT(m.id) >=3
LIMIT 5;

-- Taapsee Pannu tops with average rating 7.74. 



/* 16. Selecting thriller movies as per avg rating and classify them in the following category: 

			Rating > 8: Superhit movies
			Rating between 7 and 8: Hit movies
			Rating between 5 and 7: One-time-watch movies
			Rating < 5: Flop movies
--------------------------------------------------------------------------------------------*/

SELECT 
      DISTINCT title, avg_rating, 
      CASE 
          WHEN avg_rating > 8 THEN 'Superhit movies'
          WHEN avg_rating BETWEEN 7 AND 8 THEN 'Hit movies'
          WHEN avg_rating BETWEEN 5 AND 7 THEN 'One-time-watch movies'
          ELSE 'Flop movies'
      END AS category
      FROM ratings r
           INNER JOIN genre g
           ON g.movie_id = r.movie_id
           INNER JOIN movie m
           ON m.id = r.movie_id
      WHERE genre = 'Thriller';    




-- Segment 4:

-- 17. Genre-wise running total and moving average of the average movie duration 

SELECT 
      genre, ROUND(AVG(duration),2) AS avg_duration, 
      SUM(ROUND(AVG(duration),2)) OVER(ORDER BY genre) AS running_total_duration,
      AVG(ROUND(AVG(duration),2)) OVER(ORDER BY genre) AS moving_avg_duration 
FROM movie m
     INNER JOIN genre G
     ON g.movie_id = m.id
GROUP BY genre;     



-- 18. The five highest-grossing movies of each year that belong to the top three genres

WITH top_3_genre AS
(SELECT 
      genre
FROM ratings r
	  INNER JOIN movie m
      ON m.id = r.movie_id
      INNER JOIN genre g
      ON g.movie_id = m.id
WHERE avg_rating > 8
GROUP BY genre
ORDER BY COUNT(g.movie_id) DESC
LIMIT 3),
movie_gross AS
(
 SELECT
       genre, year, title AS movie_name, worlwide_gross_income,
      DENSE_RANK() OVER(PARTITION BY genre, year ORDER BY CONVERT(REPLACE(TRIM(worlwide_gross_income), "$ ",""), UNSIGNED INT) DESC) AS movie_rank
 FROM movie m
     INNER JOIN genre g
     ON g.movie_id = m.id
 WHERE genre IN (SELECT genre FROM top_3_genre)
 )
SELECT distinct *     
FROM movie_gross
WHERE movie_rank <= 5;




-- 19. The top two production houses that have produced the highest number of hits (median rating >= 8) among multilingual movies

-- APPROACH 1
WITH top_multilingual_movies AS
(
 SELECT
      id
 FROM  movie m
      INNER JOIN ratings r
      ON m.id = r.movie_id
 WHERE languages like '%,%'
	  AND median_rating >= 8
)
SELECT 
       production_company, COUNT(m.id) AS movie_count,
       RANK() OVER(ORDER BY COUNT(m.id) DESC) AS prod_comp_rank
FROM movie m
     INNER JOIN top_multilingual_movies as mm
     ON mm.id = m.id
WHERE production_company IS NOT NULL 
GROUP BY production_company
LIMIT 2;

-- APPROACH 2
WITH top_multilingual_movies AS
(
 SELECT
      id
 FROM  movie m
      INNER JOIN ratings r
      ON m.id = r.movie_id
 WHERE POSITION(',' IN languages)>0
	  AND median_rating >= 8
)
SELECT 
       production_company, COUNT(m.id) AS movie_count,
       RANK() OVER(ORDER BY COUNT(m.id) DESC) AS prod_comp_rank
FROM movie m
     INNER JOIN top_multilingual_movies as mm
     ON mm.id = m.id
WHERE production_company IS NOT NULL 
GROUP BY production_company
LIMIT 2;



-- 20. The top 3 actresses based on number of Super Hit movies (average rating >8) in drama genre

SELECT
       name AS actress_name, SUM(total_votes) AS total_votes, COUNT(rm.movie_id) AS movie_counnt, ROUND(AVG(avg_rating),2) AS actress_avg_rating,
       DENSE_RANK() OVER(ORDER BY COUNT(rm.movie_id) DESC) AS actress_rank
FROM  role_mapping rm
      INNER JOIN names n
      ON n.id = rm.name_id
      INNER JOIN genre g
      ON g.movie_id = rm.movie_id
      INNER JOIN ratings r
      ON r.movie_id = rm.movie_id
WHERE genre = 'drama' AND  category='actress' AND avg_rating > 8
GROUP BY name
LIMIT 3;      
      


/* 21. Getting the following details for top 9 directors (based on number of movies)
Director id
Name
Number of movies
Average inter movie duration in days
Average movie ratings
Total votes
Min rating
Max rating
total movie durations */


WITH direc_info AS
(
 SELECT 
      name_id, name AS director_name, COUNT(M.id) AS number_of_movies, AVG(avg_rating) AS avg_rating,
	  SUM(total_votes) AS total_votes, MIN(avg_rating) AS min_rating, MAX(avg_rating) AS max_rating, SUM(duration) AS total_duration
 FROM movie m
     INNER JOIN director_mapping dm
     ON m.id = dm.movie_id
     INNER JOIN names n
     ON n.id = dm.name_id
     INNER JOIN ratings r
     ON m.id = r.movie_id
 GROUP BY name_id
 ORDER BY COUNT(id) DESC
 ),
 direc_date_info AS
(
SELECT
      name_id, name,
      date_published, 
      LAG(date_published) OVER(PARTITION BY NAME_id ORDER BY DATE_PUBLISHED) as pre_movie_date
      FROM MOVIE m
      INNER JOIN director_mapping dm
      ON m.id = dm.movie_id
      INNER JOIN names n
      ON dm.name_id = n.id
),
diff_date AS
(
  SELECT
        name_id, name,
        DATEDIFF(date_published, pre_movie_date) AS date_diff
  FROM direc_date_info
  )
SELECT
       di.name_id, di.director_name, di.number_of_movies, round(avg(date_diff),0) as avg_inter_movie_days, 
       round(di.avg_rating,2) as avg_rating, di.total_votes, di.min_rating, di.max_rating, di.total_duration
FROM diff_date dd
     INNER JOIN direc_info di
     ON dd.name_id = di.name_id
GROUP BY name_id
LIMIT 9;





