// Minimize transfers from start and end stations.

// Transfer-first routing (RUN/XFER layer) — prints a result row even if no path
// Edit the two station codes in section (3) if you want a different route.
// Cost function: transfer=1, stay on same line=0, tie-break by minutes/100000.

// 0) Reset helper structures (safe to re-run)
MATCH ()-[r:RUN|XFER|XDIST|TOURX]->() DELETE r;
MATCH (n:StationLine) DELETE n;

// 1) Build StationLine layer and RUN (same-line) edges
MATCH (u:Station)-[r]->(v:Station)
WHERE NOT type(r) IN ['ANY','DIST','TOUR','RUN','XFER','XDIST','CONNECTS_AT']
WITH u, v, type(r) AS ln, coalesce(r.minutes, 1) AS m
MERGE (su:StationLine {code:u.code, line:ln})
MERGE (sv:StationLine {code:v.code, line:ln})
MERGE (su)-[e:RUN]->(sv)
ON CREATE SET e.minutes = m, e.xfer = 0.0
ON MATCH  SET e.minutes = CASE WHEN e.minutes IS NULL OR m < e.minutes THEN m ELSE e.minutes END,
                     e.xfer    = 0.0;

// 2) Build transfer edges (cost 1) between all lines serving the same station
MATCH (a:StationLine),(b:StationLine)
WHERE a.code = b.code AND a.line < b.line
MERGE (a)-[:XFER {xfer:1.0, minutes:0}]->(b)
MERGE (b)-[:XFER {xfer:1.0, minutes:0}]->(a);

// 3) Minimum-transfer route from source to target
// Change the codes below if needed:
MATCH (s:Station {code:'18th-Stout'}), (t:Station {code:'Union Station'})
MATCH (ss:StationLine {code:s.code}), (tt:StationLine {code:t.code})

// Weighted shortest path over RUN|XFER (transfer-first; minutes only break ties)
OPTIONAL MATCH p = (ss)-[:RUN|:XFER *wShortest (e, n | coalesce(e.xfer,0.0) + coalesce(e.minutes,0.0)/100000.0) total]->(tt)
WITH p, total
ORDER BY total ASC
LIMIT 1
RETURN
  '18th-Stout' AS source,
  'Union Station' AS target,
  CASE WHEN p IS NULL THEN [] ELSE [n IN nodes(p) | n.code + ' [' + coalesce(n.line,'?') + ']'] END AS layered_path,
  CASE WHEN p IS NULL THEN [] ELSE [n IN nodes(p) | n.code] END AS station_path,
  CASE WHEN p IS NULL THEN NULL ELSE toInteger(floor(total)) END AS transfers,
  CASE WHEN p IS NULL THEN NULL ELSE toInteger(round((total - floor(total)) * 100000)) END AS tie_minutes;
