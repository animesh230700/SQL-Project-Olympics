CREATE Schema project;
USE project;
CREATE TABLE athelets (
id int,
name varchar(255),
sex varchar(20),
height float NULL,
weight float NULL,
team varchar(255),
team_duplicate varchar(255)
);
LOAD DATA INFILE "C:\\Users\\HP\\Desktop\\PROJECT\\athletes.csv"
INTO TABLE athelets
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM athelets;
SET SQL_SAFE_UPDATES = 0;
DELETE FROM athelets 
WHERE height = '0' AND weight = '0';
SELECT * FROM athelets;
SELECT * FROM athelets
WHERE name IS NULL;
SELECT team, count(team) FROM athelets
where team = 'china';

USE project;
CREATE TABLE athlete_events (
id int,
games varchar(20),
year int,
season varchar(20),
city varchar(200),
sport varchar(30),
event varchar(200),
medal varchar(20),
medal_duplicate varchar(20)
);
LOAD DATA INFILE "C:\\Users\\HP\\Desktop\\PROJECT\\athlete_events.csv"
INTO TABLE athlete_events
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Which team has won maximum gold medals over the year 
SELECT ath.team, count(*) As Gold_count
FROM athelets As ath
JOIN athlete_events AS eve
ON ath.id = eve.id
WHERE medal = "Gold"
GROUP BY ath.team
order by Gold_count desc
limit 1
-- for each team print total silver medals and year in which they won maximum silver medal..output 3 columns
-- team,total_silver_medals, year_of_max_silver
select ath.team, COUNT(eve.medal) As total_silver_medals, MAX(eve.year) AS year_of_max_silver
FROM athelets As ath
JOIN athlete_events AS eve
ON ath.id = eve.id
WHERE eve.medal = "Silver"
GROUP BY ath.team
order by total_silver_medals desc
-- which player has won maximum gold medals  amongst the players 
-- which have won only gold medal (never won silver or bronze) over the years
SELECT ath.id , ath.name, COUNT(eve.medal) AS total_gold_medals
FROM athelets As ath
JOIN athlete_events AS eve
ON ath.id = eve.id
WHERE eve.medal = "Gold" AND eve.medal <> "Bronze" AND eve.medal <> "Bronze"
GROUP BY ath.id, ath.name
order by total_gold_medals desc

-- in each year which player has won maximum gold medal . Write a query to print year,player name 
-- and no of golds won in that year . In case of a tie print comma separated player names.
WITH Goldmedalrank_cte AS (
    SELECT
        eve.year,
        ath.name AS player_name,
        COUNT(*) AS gold_count,
        RANK() OVER (PARTITION BY eve.year ORDER BY COUNT(*) DESC) AS Rank
    FROM
        athelets AS ath
    JOIN
        athlete_events AS eve ON ath.id = eve.id
    WHERE
        eve.medal = 'Gold'
    GROUP BY
        eve.year, ath.name
)
SELECT
    year,
    CASE
        WHEN COUNT(*) > 1 THEN GROUP_CONCAT(player_name)
        ELSE MAX(player_name)
    END AS player_names,
    MAX(gold_count) AS max_gold_count
FROM
    Goldmedalrank_cte
WHERE
    Rank = 1
GROUP BY
    year;
-- 5 in which event and year India has won its first gold medal,first silver medal and first bronze medal
-- print 3 columns medal,year,sport	
select * from (
select medal,year,event,rank() over(partition by medal order by year) As rn
from athlete_events As eve
join athelets AS ath on eve.id = ath.id
where team='India' and medal != 'NA'
) A
where rn=1

-- 6 find players who won gold medal in summer and winter olympics both.
select ath.name 
from athlete_events As eve
join athelets AS ath on eve.id = ath.id
where medal='Gold'
group by ath.name having count(distinct season)=2

-- 7 find players who won gold, silver and bronze medal in a single olympics. print player name along with year.
select eve.year, ath.name
from athlete_events As eve
join athelets AS ath on eve.id = ath.id
where medal != 'NA'
group by eve.year, ath.name having count(distinct medal)=3

-- 8 find players who have won gold medals in consecutive 3 summer olympics in the same event . Consider only olympics 2000 onwards. 
-- Assume summer olympics happens every 4 year starting 2000. print player name and event name.
with cte as (
select name,year,event
from athlete_events As eve
join athelets AS ath on eve.id = ath.id
where year >=2000 and season='Summer'and medal = 'Gold'
group by name,year,event)
select * from
(select *, lag(year,1) over(partition by name,event order by year ) as prev_year
, lead(year,1) over(partition by name,event order by year ) as next_year
from cte) A
where year=prev_year+4 and year=next_year-4