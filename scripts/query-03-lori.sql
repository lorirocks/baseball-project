/*
Query 3: 
a. Find all players in the database who played at Vanderbilt University  
ANSWER: List of 15 players.
b. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
Sort this list in descending order by the total salary earned. 
d. Which Vanderbilt player earned the most money in the majors?  
ANSWER: David Price, earned $245,533,888
*/

--WRONG!!!  Supposed to be 1/3rd of this amount. Mary & Mahesh got it wrong too.
--playerid shows up three times in collegeplaying table (for each year played in school), causes 
---triple count of salaries.
--WRONG:
SELECT p.playerid, schoolname, namefirst, namelast, SUM(salary)::numeric::money as total_salary
FROM schools AS s 
		JOIN collegeplaying AS cp USING(schoolid)  --LEFT and INNER JOIN also work for all joins.
		JOIN people AS p ON p.playerid = cp.playerid
		JOIN salaries as sal ON sal.playerid = p.playerid
	WHERE schoolname like '%Vanderbilt%'
--		AND salary IS NOT NULL
GROUP BY p.playerid, schoolname, namefirst, namelast, namegiven
ORDER BY total_salary DESC;

--Fixed --WIP  NOT DONE YET:
WITH vandyplayers AS (SELECT DISTINCT p.playerid, schoolname, namefirst || ' ' || namelast as player_name
						FROM schools AS s 
								JOIN collegeplaying AS cp USING(schoolid)  --LEFT and INNER JOIN also work for all joins.
								JOIN people AS p ON p.playerid = cp.playerid
								JOIN salaries as sal ON sal.playerid = p.playerid
							WHERE schoolname like '%Vanderbilt%'
					 	GROUP BY p.playerid, schoolname, namefirst, namelast, namegiven)
SELECT SUM(sal.salary)::numeric::money as total_salary, 
FROM vandyplayers;
FROM schools AS s 
	JOIN collegeplaying AS cp USING(schoolid)  --LEFT and INNER JOIN also work for all joins.
	JOIN people AS p ON p.playerid = cp.playerid
	JOIN salaries as sal ON sal.playerid = p.playerid
--ORDER BY total_salary DESC;



--CODE REVIEW by SOPHIA HOFFMAN :-)
--WRONG!!!  Supposed to be 1/3rd of this amount. Mary & Mahesh got it wrong too.
select distinct namefirst || ' ' || namelast as player_name, schoolname, sum(salary)::numeric::money as total_salary  -- || is concatenate
from people
	join collegeplaying    --default join is INNER. Doing INNER join prevents NULL values. Cool!
	on people.playerid = collegeplaying.playerid
	join schools
	on collegeplaying.schoolid = schools.schoolid 
	join salaries
	on salaries.playerid = people.playerid
where schools.schoolname like '%Vanderbilt%'
group by player_name, schoolname
order by total_salary desc
