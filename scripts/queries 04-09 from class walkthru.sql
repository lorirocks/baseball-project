/* 
FROM WALK-THROUGH - Numbers 4-9:
QUESTION #4: Using the fielding table, group players into three groups based on their position: 
label players with position OF as "Outfield", 
those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
Determine the number of putouts made by each of these three groups in 2016.
*/
--DOESN'T WORK
WITH putouts_2016 AS (SELECT pos, 
					  po, 
	 					CASE WHEN pos = 'OF' THEN 'Outfield'
	 						 WHEN pos = 'P'OR pos = 'C' THEN 'Battery'
	 						 WHEN pos in ('SS', '1B', '2B', '3B') THEN 'Infield' END AS position_group
					FROM fielding
					WHERE yearid = 2016
					GROUP BY pos, po, position_group
					ORDER BY position_group)
SELECT sum(po),position_group
FROM putouts_2016
GROUP BY position_group;

--FROM MARY -- this is correct
select sum(f.po) as total_putouts,
	(case when f.pos = 'OF' then 'outfield'
			when f.pos in ('SS', '1B', '2B', '3B') then 'Infield'
	 		when pos = 'P' or pos = 'C' THEN 'Battery'
			 end) as position
from fielding f
where yearid = 2016
group by position;
	 
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
/*
QUESTION #5:
Find the average number of strikeouts per game by decade since 1920. 
Round the numbers you report to 2 decimal places. 
Do the same for home runs per game. Do you see any trends?
*/
--From Diego
WITH decades as (	
				SELECT 	generate_series(1920,2010,10) as low_b,
						generate_series(1929,2019,10) as high_b)
SELECT 	low_b as decade,
		--SUM(so) as strikeouts,
		--SUM(g)/2 as games,  -- used last 2 lines to check that each step adds correctly
		ROUND(SUM(so::numeric)/(sum(g::numeric)/2),2) as SO_per_game,  -- note divide by 2, since games are played by 2 teams
		ROUND(SUM(hr::numeric)/(sum(g::numeric)/2),2) as hr_per_game
FROM decades LEFT JOIN teams
	ON yearid BETWEEN low_b AND high_b
GROUP BY decade
ORDER BY decade;

--From Cristina - a way to get by decade
-- floor 1922/10 = 192.2, FLOOR rounds is DOWN to nearest year, multiply by 10 to get back to 1920.
select floor(yearid/10)*10 as decade--, yearid
from batting
where yearid >= 1920
group by decade;--, yearid;

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

/*
QUESTION #6
Find the player who had the most success stealing bases in 2016, 
where success is measured as the percentage of stolen base attempts which are successful. 
(A stolen base attempt results either in a stolen base or being caught stealing.) 
Consider only players who attempted at least 20 stolen bases.
*/
SELECT sb AS stolen_bases, cs AS got_ya, (sb+cs) as times_attempted,
	CONCAT(ROUND((sb::numeric)/((sb::numeric)+(cs::numeric))*100,0), '%')::varchar AS success_percent,
	CONCAT(namegiven,' ', namelast) AS Name
FROM BATTING as b INNER JOIN people as p ON b.playerid=p.playerid
WHERE yearid=2016
AND sb > 20
GROUP BY sb, cs, p.namegiven, namelast
ORDER BY success_percent DESC
LIMIT 1;

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
/*
QUESTION #7
From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
What is the smallest number of wins for a 
team that did win the world series? Doing this will probably result in an 
unusually small number of wins for a world series champion – determine why this is the case. 
Then redo your query, excluding the problem year. How often from 1970 – 2016 
was it the case that a team with the most wins also won the world series? 
What percentage of the time?
*/
------------------------------------------------------------------------------------
--ALL FROM SOPHIA -- NOT CORRECT BUT MATCHES MARY'S -- SEE DIEGO'S CODE NEXT
	-- team with largest number of wins that didn't win the world series: seattle mariners 2001 with 116 wins
	select yearid, teamid, name, w, wswin 
		from teams
		where wswin != 'Y'
		and yearid between 1970 and 2016
	order by w desc
	limit 1
	-- team with smallest number of wins that won the world series: LA Dodgers in 1981 with 63 wins
	select yearid, teamid, name, w, wswin 
		from teams
		where wswin = 'Y'
		and yearid between 1970 and 2016
	order by w asc
	limit 1
	-- strike in 1981 led to less than normal games - max of 111; normal years have 162
	select max(g)
		from teams
		where yearid = 2001
	-- team with smallest number of wins that won the world series: St Louis Cardinals with 83 wins in 2006
	select yearid, teamid, name, w, wswin 
		from teams
		where wswin = 'Y'
		and yearid between 1970 and 2016 and yearid != 1981
	order by w asc
	limit 1
	-- teams that won the world series by year
	--RUN ALL TEH BELOW TOGETHER
	with ws_winners as
					(select yearid, name
					from teams
					where wswin = 'Y'
					and yearid between 1970 and 2016
					order by yearid asc)
	-- return percentage of count on results/47 years
	select (count(*)::float/(2016-1970+1)) as pct_winners
	from
	--teams with the most wins by year inner joined on teams that won the world series
	(select teams.yearid, teams.name, teams.w
	from teams
	join ws_winners
	on ws_winners.yearid = teams.yearid and ws_winners.name=teams.name
	group by teams.yearid, teams.name, teams.w
	having w = max(w)
	order by yearid asc) as ws_winners_most_games
------------------------------------------------------------------------------------
----DIEGO'S CODE---for ONLY last part of 7, percent of teams = 26.09% ------------
WITH winners as	(	SELECT teamid as champ, yearid, w as champ_w
	  				FROM teams
	  				WHERE 	(wswin = 'Y')
				 			AND (yearid BETWEEN 1970 AND 2016) ),
							
max_wins as (	SELECT yearid, max(w) as maxw
	  			FROM teams
	  			WHERE yearid BETWEEN 1970 AND 2016
				GROUP BY yearid)
SELECT 	COUNT(*) AS all_years,
		COUNT(CASE WHEN champ_w = maxw THEN 'Yes' end) as max_wins_by_champ,
		to_char((COUNT(CASE WHEN champ_w = maxw THEN 'Yes' end)/(COUNT(*))::real)*100,'99.99%') as Percent
FROM 	winners LEFT JOIN max_wins
		USING(yearid)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
/* 
QUESTION 8:  Using the attendance figures from the homegames table, find the teams and parks 
which had the top 5 average attendance per game in 2016 
(where average attendance is defined as total attendance divided by number of games). 
Only consider parks where there were at least 10 games played. 
Report the park name, team name, and average attendance. 
Repeat for the lowest 5 average attendance. 
*/

--FROM AMANDA
WITH avg_attendance AS (SELECT (attendance/games) AS avg_attend,
						team, park
						FROM homegames
						WHERE year = '2016'
							AND homegames.games > 10
						GROUP BY team, park, avg_attend
					   	ORDER BY team, avg_attend)
SELECT DISTINCT teams.name AS team, 
	parks.park_name AS park, 
	avg_attend
FROM avg_attendance
		LEFT JOIN teams
		ON avg_attendance.team = teams.teamid
		LEFT JOIN parks
		ON avg_attendance.park = parks.park
WHERE teams.park IS NOT NULL
		AND teams.yearid = 2016
ORDER BY avg_attend DESC;

-----------------------------------------------
-------FROM MEDIA, ALTERNATE METHOD-----------
Select 
	distinct ps.park_name
	, ts.name as team_name
	, hg.attendance/hg.games as avg_attendance
from homegames as hg
	left join parks as ps on hg.park = ps.park
	left join teams as ts on hg.team = ts.teamid 
	and ts.yearid = hg.year
where hg.year = 2016 and hg.games >= 10  --must specify to take year from homegames table
order by avg_attendance desc
limit 5;
-- the lowest 5 average attendance
Select distinct ps.park_name, ts.name as team_name,  hg.attendance/hg.games as avg_attendance
from homegames as hg
left join parks as ps on hg.park = ps.park
left join teams as ts on hg.team = ts.teamid and ts.yearid = hg.year
where hg.year = 2016 and hg.games >= 10
order by avg_attendance asc
limit 5;

---------------Alternate method from Ness:  Simpler, but doesn't return team name
---could do that with an additional join.
SELECT parks.park_name
	, team
	, attendance
	, (homegames.attendance/games) AS avg_attendance
		FROM homegames
		INNER JOIN parks 
		USING (park)
WHERE year = 2016
		AND games >= 10
ORDER BY avg_attendance DESC

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
/*
Question #9: Which managers have won the TSN Manager of the Year award in both the 
National League (NL) and the American League (AL)? 
Give their full name and the teams that they were managing when they won the award. 
*/
---FROM NESS: -- With names added by Mary
WITH nl AS  (SELECT * 
			FROM awardsmanagers
			WHERE awardid = 'TSN Manager of the Year'
			AND lgid = 'NL' )
SELECT concat(namefirst, ' ', namelast) as mgr_name, 
		nl.playerid, nl.yearid, nl.awardid, 
		am.playerid, am.yearid, am.lgid, nl.lgid
FROM awardsmanagers AS am
INNER JOIN nl
USING(playerid)
inner join people using (playerid)
WHERE am.awardid = 'TSN Manager of the Year'
AND am.lgid = 'AL' 
		
		
----FROM SOPHIA -- includes names -- Very clean results
with al_tsn_mgr_of_year as
					(select distinct m.teamid, a.playerid, a.yearid
					from awardsmanagers as a
					join managers as m
					on m.playerid = a.playerid
					where awardid = 'TSN Manager of the Year'
					and a.lgid = 'AL'
					and m.yearid = a.yearid),
nl_tsn_mgr_of_year as
					(select distinct m.teamid, a.playerid, a.yearid
					from awardsmanagers as a
					join managers as m
					on m.playerid = a.playerid
					where awardid = 'TSN Manager of the Year'
					and a.lgid = 'NL'
					and m.yearid = a.yearid)
select distinct namefirst || ' ' || namelast as name
		, al_tsn_mgr_of_year.yearid
		, al_tsn_mgr_of_year.teamid
		, nl_tsn_mgr_of_year.yearid
		, nl_tsn_mgr_of_year.teamid
from nl_tsn_mgr_of_year, al_tsn_mgr_of_year, people
where nl_tsn_mgr_of_year.playerid = al_tsn_mgr_of_year.playerid
		and people.playerid = nl_tsn_mgr_of_year.playerid
order by name;


-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
/* BONUS QUESTION #10:
Analyze all the colleges in the state of Tennessee. Which college has had the most success in the major leagues. 
Use whatever metric for success you like - number of players, number of games, salaries, world series wins, etc.
*/

--From Sophia (might be tripple-counting salaries)
with tn_schools as 
				(select schoolname from schools
				where schoolstate = 'TN')
select  schools.schoolname
		, count (distinct namefirst || ' ' || namelast) as count_players
		, sum(salaries.salary)::decimal::money
		,(sum(salaries.salary)/count (distinct namefirst || ' ' || namelast))::decimal::money as avg_salary
from collegeplaying
		join schools
		on collegeplaying.schoolid = schools.schoolid
		join people
		on collegeplaying.playerid = people.playerid
		join salaries
		on collegeplaying.playerid = salaries.playerid
		join tn_schools
		on schools.schoolname = tn_schools.schoolname
group by schools.schoolname
order by count_players desc
