/*
Query #2.a. Find the name and height of the shortest player in the database.
ANSWSER:  Eddie "Edward Carl" Gaedel, 43 inches, player ID gaedeed01
		TRIVIA:  Shortest player in Amer. League history, 3' 7" tall  https://en.wikipedia.org/wiki/Eddie_Gaedel
*/
SELECT playerid, namefirst, namegiven, namelast, height as height_inches
	FROM people 
	ORDER BY height
	LIMIT 1;

/*
2.b How many games did shortest player play in? ANSWER: One game
2.c. What team did shortest player play for?  ANSWER: ST. Louis Browns
*/
SELECT people.playerid, namefirst, namegiven, namelast, g_all as games_played, height as height_inches, teams.name
	FROM people INNER JOIN appearances ON people.playerid = appearances.playerid
		INNER JOIN teams ON teams.teamid = appearances.teamid
	WHERE people.playerid = 'gaedeed01'
	LIMIT 1;  --Not sure why this is needed, but without it I get long list of duplicate values.


--CODE REVIEW from Sophia Hoffman :-) 
with shortest_player as
		(select distinct namefirst || ' ' || namelast as player_name, height, teamid, g_all as total_games
		from people
		join appearances
		on people.playerid = appearances.playerid
		where height = (select min(height) from people))
select distinct player_name, height, shortest_player.teamid, name, total_games
from shortest_player
	join teams
	on shortest_player.teamid = teams.teamid

