// Returns a list of stations to visit such that all stations are visited in minimum time.

// A) reset working marks
MATCH (s:Station) REMOVE s._cur, s._seen;
MATCH ()-[t:TOUR]->() DELETE t;
MATCH (s:Station {code:'18th-Stout'}) SET s._cur=true, s._seen=true;

// B) (run this many times) add the next nearest unvisited station
// Run 75 times for Denver
MATCH (cur:Station {_cur:true})- [d:DIST]->(n:Station)
WHERE n._seen IS NULL
WITH cur, n, d ORDER BY d.minutes ASC LIMIT 1
CREATE (cur)-[:TOUR {minutes:d.minutes}]->(n)
REMOVE cur._cur
SET n._cur=true, n._seen=true;

// C) read out the forward order
MATCH p = (:Station {code:'18th-Stout'})-[:TOUR*]->(last)
RETURN [x IN nodes(p) | x.code] AS ordered_stations;

// D) add the return hop (optional)
MATCH (last:Station {_cur:true}), (home:Station {code:'Union Station'})
MATCH (last)-[d:DIST]->(home)
CREATE (last)-[:TOUR {minutes:d.minutes}]->(home);


// Final: output the current TOUR order (if any) and total minutes
MATCH p = (:Station {code:'18th-Stout'})-[:TOUR*]->(n)
WITH p ORDER BY length(p) DESC LIMIT 1
RETURN [x IN nodes(p) | x.code] AS order,
       reduce(t=0, r IN relationships(p) | t + r.minutes) AS minutes,
       length(p) AS legs;
