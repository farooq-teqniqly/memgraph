// Minimal-transfer plan to visit ALL stations
// Idea: if you ride each rail line end-to-end once, you visit all stations.
// So we minimize transfers by finding a Hamiltonian path over the (:Line) graph.
// Start on a line that serves 18th-Stout and finish on a line that serves Union Station.
// Returns the line order and chosen transfer station for each handoff.

// ---- 0) Rebuild the (:Line) graph (safe to re-run) ----
MATCH (l:Line) DETACH DELETE l;

WITH ['NEXT','CONNECTS_AT','ANY','DIST','TOUR','RUN','XFER','XDIST','TOURX'] AS exclude
MATCH ()-[r]->()
WITH [t IN collect(DISTINCT type(r)) WHERE NOT t IN exclude] AS lineTypes
UNWIND lineTypes AS ln
MERGE (:Line {name: ln});

// Connect Line nodes if they share at least one Station; keep the list of shared stations
MATCH (s:Station)
MATCH (s)<-[r]-()
WITH s, collect(DISTINCT type(r)) AS ls
UNWIND range(0, size(ls)-2) AS i
UNWIND range(i+1, size(ls)-1) AS j
WITH s, ls[i] AS l1, ls[j] AS l2
MATCH (L1:Line {name:l1}), (L2:Line {name:l2})
MERGE (L1)-[c:CONNECTS_AT]->(L2)
  ON CREATE SET c.stations = [s.code]
  ON MATCH  SET c.stations = CASE WHEN s.code IN c.stations THEN c.stations ELSE c.stations + s.code END
MERGE (L2)-[c2:CONNECTS_AT]->(L1)
  ON CREATE SET c2.stations = [s.code]
  ON MATCH  SET c2.stations = CASE WHEN s.code IN c2.stations THEN c2.stations ELSE c2.stations + s.code END;

// ---- 1) Compute start/end line sets ----
MATCH (s0:Station {code:'18th-Stout'})<-[r1]-()
WITH collect(DISTINCT type(r1)) AS start_lines
MATCH (t0:Station {code:'Union Station'})<-[r2]-()
WITH start_lines, collect(DISTINCT type(r2)) AS end_lines
MATCH (L:Line)
WITH start_lines, end_lines, collect(L.name) AS all_lines, count(L) AS nlines

// ---- 2) Find a Hamiltonian path over (:Line) that starts on a 18th-Stout line and ends on a Union Station line ----
MATCH p = (start:Line)-[:CONNECTS_AT*..48]->(end:Line)
WHERE start.name IN start_lines AND end.name IN end_lines
WITH nlines, p, [n IN nodes(p) | n.name] AS names
WHERE size(names) = nlines
  AND ALL(i IN range(1, size(names)-1)
          WHERE NONE(prev IN names[0..i-1] WHERE prev = names[i]))

// ---- 3) Choose transfer station for each hop (prefer home or Union Station if possible) ----
UNWIND range(0, size(names)-2) AS i
WITH names, names[i] AS l1, names[i+1] AS l2
MATCH (:Line {name:l1})-[c:CONNECTS_AT]->(:Line {name:l2})
WITH names, l1, l2, c.stations AS stations
WITH names, l1, l2,
     CASE
       WHEN '18th-Stout'   IN stations THEN '18th-Stout'
       WHEN 'Union Station' IN stations THEN 'Union Station'
       ELSE stations[0]
     END AS at
RETURN
  names                                AS line_order,
  collect({from:l1, to:l2, at:at})     AS transfers,
  size(names) - 1                      AS min_transfers;
