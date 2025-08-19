
// Creates a graph of the Denver RTD.
//STORAGE MODE IN_MEMORY_TRANSACTIONAL;

CALL mg.load_all();

// Reset (dev only)
MATCH (n) DETACH DELETE n;

// Unique station codes
CREATE CONSTRAINT ON (s:Station) ASSERT s.code IS UNIQUE;


// Stations
UNWIND [
  {code:'10th & Osage', name:'10th & Osage'},
{code:'13th Ave', name:'13th Ave'},
{code:'16th-Stout', name:'16th-Stout'},
{code:'16th-California', name:'16th-California'},
{code:'18th-Stout', name:'18th-Stout'},
{code:'18th-California', name:'18th-California'},
{code:'20th-Welton', name:'20th-Welton'},
{code:'25th-Welton', name:'25th-Welton'},
{code:'27th-Welton', name:'27th-Welton'},
{code:'2nd Ave-Abilene', name:'2nd Ave-Abilene'},
{code:'30th-Downing', name:'30th-Downing'},
{code:'38th-Blake', name:'38th-Blake'},
{code:'40th Ave & Airport Blvd-Gateway Park', name:'40th Ave & Airport Blvd-Gateway Park'},
{code:'40th-Colorado', name:'40th-Colorado'},
{code:'41st-Fox', name:'41st-Fox'},
{code:'48th & Brighton-National Western Center', name:'48th & Brighton-National Western Center'},
{code:'60th & Sheridan-Arvada Gold Strike', name:'60th & Sheridan-Arvada Gold Strike'},
{code:'61st-Pena', name:'61st-Pena'},
{code:'Alameda', name:'Alameda'},
{code:'Arapahoe at Village Center', name:'Arapahoe at Village Center'},
{code:'Arvada Ridge', name:'Arvada Ridge'},
{code:'Auraria West', name:'Auraria West'},
{code:'Aurora Metro Center', name:'Aurora Metro Center'},
{code:'Ball Arena-Elitch Gardens', name:'Ball Arena-Elitch Gardens'},
{code:'Belleview', name:'Belleview'},
{code:'Central Park', name:'Central Park'},
{code:'Clear Creek-Federal', name:'Clear Creek-Federal'},
{code:'Colfax', name:'Colfax'},
{code:'Colfax at Auraria', name:'Colfax at Auraria'},
{code:'Colorado', name:'Colorado'},
{code:'Commerce City-72nd', name:'Commerce City-72nd'},
{code:'County Line', name:'County Line'},
{code:'Dayton', name:'Dayton'},
{code:'Decatur-Federal', name:'Decatur-Federal'},
{code:'Denver Airport', name:'Denver Airport'},
{code:'Dry Creek', name:'Dry Creek'},
{code:'Eastlake-124th', name:'Eastlake-124th'},
{code:'Empower Field at Mile High', name:'Empower Field at Mile High'},
{code:'Englewood', name:'Englewood'},
{code:'Evans', name:'Evans'},
{code:'Federal Center', name:'Federal Center'},
{code:'Fitzsimons', name:'Fitzsimons'},
{code:'Florida', name:'Florida'},
{code:'Garrison', name:'Garrison'},
{code:'I-25-Broadway', name:'I-25-Broadway'},
{code:'Illiff', name:'Illiff'},
{code:'Jeffco Gov\'t Ctr-Golden', name:'Jeffco Gov\'t Ctr-Golden'},
{code:'Knox', name:'Knox'},
{code:'Lakewood-Wadsworth', name:'Lakewood-Wedsworth'},
{code:'Lamar', name:'Lamar'},
{code:'Lincoln', name:'Lincoln'},
{code:'Littleton-Downtown', name:'Littleton-Downtown'},
{code:'Littleton-Mineral', name:'Littleton-Mineral'},
{code:'Lone Tree City Center', name:'Lone Tree City Center'},
{code:'Louisiana-Pearl', name:'Louisiana-Pearl'},
{code:'Nine Mile', name:'Nine Mile'},
{code:'Northglenn-112th', name:'Northglenn-112th'},
{code:'Oak', name:'Oak'},
{code:'Olde Town Arvada', name:'Olde Town Arvada'},
{code:'Orchard', name:'Orchard'},
{code:'Original Thornton-88th', name:'Original Thornton-88th'},
{code:'Oxford-City of Sheridan', name:'Oxford-City of Sheridan'},
{code:'Pecos Junction', name:'Pecos Junction'},
{code:'Peoria', name:'Peoria'},
{code:'Perry', name:'Perry'},
{code:'Red Rocks College', name:'Red Rocks College'},
{code:'RidgeGate Parkway', name:'RidgeGate Parkway'},
{code:'Sheridan', name:'Sheridan'},
{code:'Sky Ridge', name:'Sky Ridge'},
{code:'Southmoor', name:'Southmoor'},
{code:'Theater District-Convention Ctr', name:'Theater District-Convention Ctr'},
{code:'Thornton Crossroads-104th', name:'Thornton Crossroads-104th'},
{code:'Union Station', name:'Union Station'},
{code:'University of Denver', name:'University of Denver'},
{code:'Westminster', name:'Westminster'},
{code:'Wheat Ridge-Ward Road', name:'Wheat Ridge-Ward Road'},
{code:'Yale', name:'Yale'}

] AS st
MERGE (:Station {code:st.code, name:st.name});

// --- Build weighted undirected projection :ANY from per-line edges ---
MATCH (a:Station)-[r]->(b:Station)
WHERE NOT type(r) IN ['ANY','DIST','TOUR','CONNECTS_AT']
WITH a,b, min(coalesce(r.minutes,1)) AS m
MERGE (a)-[:ANY {minutes:m}]->(b)
MERGE (b)-[:ANY {minutes:m}]->(a);

// --- Build pairwise minute distances into :DIST using deep path WSHORTEST ---
MATCH (x:Station), (y:Station)
WHERE id(x) < id(y)
MATCH path=(x)-[:ANY *WSHORTEST (r, n | r.minutes) total_weight]->(y)
MERGE (x)-[:DIST {minutes: toInteger(total_weight)}]->(y)
MERGE (y)-[:DIST {minutes: toInteger(total_weight)}]->(x);

// Quick sanity: how many DIST edges?
MATCH ()-[d:DIST]->() RETURN count(d) AS dist_edges;


WITH [
  ['Littleton-Mineral', 'Littleton-Downtown', 'NB', 3],
  ['Littleton-Downtown', 'Oxford-City of Sheridan', 'NB', 4],
  ['Oxford-City of Sheridan', 'Englewood', 'NB', 2],
  ['Englewood', 'Evans', 'NB', 4],
  ['Evans', 'I-25-Broadway', 'NB', 4],
  ['I-25-Broadway', 'Alameda', 'NB', 1],
  ['Alameda', '10th & Osage', 'NB', 4],
  ['10th & Osage', 'Colfax at Auraria', 'NB', 6],
  ['Colfax at Auraria', 'Theater District-Convention Ctr', 'NB', 2],
  ['Theater District-Convention Ctr', '16th-California', 'NB', 2],
  ['16th-California', '18th-California', 'NB', 3],
  ['Littleton-Downtown', 'Littleton-Mineral', 'SB', 3],
  ['Oxford-City of Sheridan', 'Littleton-Downtown', 'SB', 4],
  ['Englewood', 'Oxford-City of Sheridan', 'SB', 2],
  ['Evans', 'Englewood', 'SB', 4],
  ['I-25-Broadway', 'Evans', 'SB', 4],
  ['Alameda', 'I-25-Broadway', 'SB', 1],
  ['10th & Osage', 'Alameda', 'SB', 4],
  ['Colfax at Auraria', '10th & Osage', 'SB', 6],
  ['Theater District-Convention Ctr', 'Colfax at Auraria', 'SB', 2],
  ['16th-Stout', 'Theater District-Convention Ctr', 'SB', 2],
  ['18th-Stout', '16th-Stout', 'SB', 3]
] AS segs
UNWIND segs AS s
MATCH (u:Station {code:s[0]}), (v:Station {code:s[1]})
MERGE (u)-[:D {dir:s[2], minutes:s[3]}]->(v);

WITH [
  ['16th-California', '18th-California', 'NB', 3],
  ['18th-California', '20th-Welton', 'NB', 3],
  ['20th-Welton', '25th-Welton', 'NB', 3],
  ['25th-Welton', '27th-Welton', 'NB', 1],
  ['27th-Welton', '30th-Downing', 'NB', 2],
  ['30th-Downing', '27th-Welton', 'SB', 2],
  ['27th-Welton', '25th-Welton', 'SB', 1],
  ['25th-Welton', '20th-Welton', 'SB', 3],
  ['20th-Welton', '18th-Stout', 'SB', 2],
  ['18th-Stout', '16th-Stout', 'SB', 2]
] AS segs
UNWIND segs AS s
MATCH (u:Station {code:s[0]}), (v:Station {code:s[1]})
MERGE (u)-[:L {dir:s[2], minutes:s[3]}]->(v);

WITH [
  ['Florida', 'Illiff', 'NB', 4],
  ['Illiff', 'Nine Mile', 'NB', 4],
  ['Nine Mile', 'Dayton', 'NB', 4],
  ['Dayton', 'Southmoor', 'NB', 5],
  ['Southmoor', 'Yale', 'NB', 2],
  ['Yale', 'Colorado', 'NB', 3],
  ['Colorado', 'University of Denver', 'NB', 3],
  ['University of Denver', 'Louisiana-Pearl', 'NB', 2],
  ['Louisiana-Pearl', 'I-25-Broadway', 'NB', 4],
  ['I-25-Broadway', 'Alameda', 'NB', 1],
  ['Alameda', '10th & Osage', 'NB', 4],
  ['10th & Osage', 'Colfax at Auraria', 'NB', 6],
  ['Colfax at Auraria', 'Theater District-Convention Ctr', 'NB', 2],
  ['Theater District-Convention Ctr', '16th-California', 'NB', 2],
  ['16th-California', '18th-California', 'NB', 3],

['Illiff', 'Florida', 'SB', 4],
['Nine Mile', 'Illiff', 'SB', 4],
['Dayton', 'Nine Mile', 'SB', 4],
['Southmoor', 'Dayton', 'SB', 5],
['Yale', 'Southmoor', 'SB', 2],
['Colorado', 'Yale', 'SB', 3],
['University of Denver', 'Colorado', 'SB', 3],
['Louisiana-Pearl', 'University of Denver', 'SB', 2],
['I-25-Broadway', 'Louisiana-Pearl', 'SB', 4],
['Alameda', 'I-25-Broadway', 'SB', 1],
['10th & Osage', 'Alameda', 'SB', 4],
['Colfax at Auraria', '10th & Osage', 'SB', 6],
['Theater District-Convention Ctr', 'Colfax at Auraria', 'SB', 2],
['16th-Stout', 'Theater District-Convention Ctr', 'SB', 2],
['18th-Stout', '16th-Stout', 'SB', 3]

] AS segs
UNWIND segs AS s
MATCH (u:Station {code:s[0]}), (v:Station {code:s[1]})
MERGE (u)-[:H {dir:s[2], minutes:s[3]}]->(v);

WITH [
  ['Wheat Ridge-Ward Road', 'Arvada Ridge', 'EB', 3],
  ['Arvada Ridge', 'Olde Town Arvada', 'EB', 3],
  ['Olde Town Arvada', '60th & Sheridan-Arvada Gold Strike', 'EB', 4],
  ['60th & Sheridan-Arvada Gold Strike', 'Clear Creek-Federal', 'EB', 2],
  ['Clear Creek-Federal', 'Pecos Junction', 'EB', 4],
  ['Pecos Junction', '41st-Fox', 'EB', 4],
  ['41st-Fox', 'Union Station', 'EB', 7],

['Arvada Ridge', 'Wheat Ridge-Ward Road', 'WB', 3],
['Olde Town Arvada', 'Arvada Ridge', 'WB', 3],
['60th & Sheridan-Arvada Gold Strike', 'Olde Town Arvada', 'WB', 4],
['Clear Creek-Federal', '60th & Sheridan-Arvada Gold Strike', 'WB', 2],
['Pecos Junction', 'Clear Creek-Federal', 'WB', 4],
['41st-Fox', 'Pecos Junction', 'WB', 4],
['Union Station', '41st-Fox', 'WB', 7]

] AS segs
UNWIND segs AS s
MATCH (u:Station {code:s[0]}), (v:Station {code:s[1]})
MERGE (u)-[:G {dir:s[2], minutes:s[3]}]->(v);

WITH [
  ['Jeffco Gov\'t Ctr-Golden', 'Red Rocks College', 'EB', 5],
  ['Red Rocks College', 'Federal Center', 'EB', 5],
  ['Federal Center', 'Oak', 'EB', 5],
  ['Oak', 'Garrison', 'EB', 3],
  ['Garrison', 'Lakewood-Wadsworth', 'EB', 2],
  ['Lakewood-Wadsworth', 'Lamar', 'EB', 3],
  ['Lamar', 'Sheridan', 'EB', 2],
  ['Sheridan', 'Perry', 'EB', 2],
  ['Perry', 'Knox', 'EB', 2],
  ['Knox', 'Decatur-Federal', 'EB', 2],
  ['Decatur-Federal', 'Auraria West', 'EB', 4],
  ['Auraria West', 'Empower Field at Mile High', 'EB', 1],
  ['Empower Field at Mile High', 'Ball Arena-Elitch Gardens', 'EB', 2],
  ['Ball Arena-Elitch Gardens', 'Union Station', 'EB', 4],

['Red Rocks College', "Jeffco Gov't Ctr-Golden", 'WB', 5],
['Federal Center', 'Red Rocks College', 'WB', 5],
['Oak', 'Federal Center', 'WB', 5],
['Garrison', 'Oak', 'WB', 3],
['Lakewood-Wadsworth', 'Garrison', 'WB', 2],
['Lamar', 'Lakewood-Wadsworth', 'WB', 3],
['Sheridan', 'Lamar', 'WB', 2],
['Perry', 'Sheridan', 'WB', 2],
['Knox', 'Perry', 'WB', 2],
['Decatur-Federal', 'Knox', 'WB', 2],
['Auraria West', 'Decatur-Federal', 'WB', 4],
['Empower Field at Mile High', 'Auraria West', 'WB', 1],
['Ball Arena-Elitch Gardens', 'Empower Field at Mile High', 'WB', 2],
['Union Station', 'Ball Arena-Elitch Gardens', 'WB', 4]


] AS segs
UNWIND segs AS s
MATCH (u:Station {code:s[0]}), (v:Station {code:s[1]})
MERGE (u)-[:W {dir:s[2], minutes:s[3]}]->(v);

WITH [
['Union Station', '38th-Blake', 'EB', 4],
['38th-Blake', '40th-Colorado', 'EB', 5],
['40th-Colorado', 'Central Park', 'EB', 4],
['Central Park', 'Peoria', 'EB', 3],
['Peoria', '40th Ave & Airport Blvd-Gateway Park', 'EB', 6],
['40th Ave & Airport Blvd-Gateway Park', '61st-Pena', 'EB', 3],
['61st-Pena', 'Denver Airport', 'EB', 12],

['38th-Blake', 'Union Station', 'WB', 4],
['40th-Colorado', '38th-Blake', 'WB', 5],
['Central Park', '40th-Colorado', 'WB', 4],
['Peoria', 'Central Park', 'WB', 3],
['40th Ave & Airport Blvd-Gateway Park', 'Peoria', 'WB', 6],
['61st-Pena', '40th Ave & Airport Blvd-Gateway Park', 'WB', 3],
['Denver Airport', '61st-Pena', 'WB', 12]

] AS segs
UNWIND segs AS s
MATCH (u:Station {code:s[0]}), (v:Station {code:s[1]})
MERGE (u)-[:A {dir:s[2], minutes:s[3]}]->(v);

WITH [
['Union Station', '48th & Brighton-National Western Center', 'NB', 8],
['48th & Brighton-National Western Center', 'Commerce City-72nd', 'NB', 6],
['Commerce City-72nd', 'Original Thornton-88th', 'NB', 4],
['Original Thornton-88th', 'Thornton Crossroads-104th', 'NB', 4],
['Thornton Crossroads-104th', 'Northglenn-112th', 'NB', 3],
['Northglenn-112th', 'Eastlake-124th', 'NB', 5],

['48th & Brighton-National Western Center', 'Union Station', 'SB', 8],
['Commerce City-72nd', '48th & Brighton-National Western Center', 'SB', 6],
['Original Thornton-88th', 'Commerce City-72nd', 'SB', 4],
['Thornton Crossroads-104th', 'Original Thornton-88th', 'SB', 4],
['Northglenn-112th', 'Thornton Crossroads-104th', 'SB', 3],
['Eastlake-124th', 'Northglenn-112th', 'SB', 5]

] AS segs
UNWIND segs AS s
MATCH (u:Station {code:s[0]}), (v:Station {code:s[1]})
MERGE (u)-[:N {dir:s[2], minutes:s[3]}]->(v);

WITH [
['RidgeGate Parkway', 'Lone Tree City Center', 'NB', 2],
['Lone Tree City Center', 'Sky Ridge', 'NB', 2],
['Sky Ridge', 'Lincoln', 'NB', 3],
['Lincoln', 'County Line', 'NB', 2],
['County Line', 'Dry Creek', 'NB', 3],
['Dry Creek', 'Arapahoe at Village Center', 'NB', 3],
['Arapahoe at Village Center', 'Orchard', 'NB', 2],
['Orchard', 'Belleview', 'NB', 2],
['Belleview', 'Southmoor', 'NB', 3],
['Southmoor', 'Yale', 'NB', 3],
['Yale', 'Colorado', 'NB', 3],
['Colorado', 'University of Denver', 'NB', 3],
['University of Denver', 'Louisiana-Pearl', 'NB', 2],
['Louisiana-Pearl', 'I-25-Broadway', 'NB', 3],
['I-25-Broadway', 'Alameda', 'NB', 2],
['Alameda', '10th & Osage', 'NB', 3],
['10th & Osage', 'Auraria West', 'NB', 4],
['Auraria West', 'Empower Field at Mile High', 'NB', 1],
['Empower Field at Mile High', 'Ball Arena-Elitch Gardens', 'NB', 2],
['Ball Arena-Elitch Gardens', 'Union Station', 'NB', 2],

['Lone Tree City Center', 'RidgeGate Parkway', 'SB', 2],
['Sky Ridge', 'Lone Tree City Center', 'SB', 2],
['Lincoln', 'Sky Ridge', 'SB', 3],
['County Line', 'Lincoln', 'SB', 2],
['Dry Creek', 'County Line', 'SB', 3],
['Arapahoe at Village Center', 'Dry Creek', 'SB', 3],
['Orchard', 'Arapahoe at Village Center', 'SB', 2],
['Belleview', 'Orchard', 'SB', 2],
['Southmoor', 'Belleview', 'SB', 3],
['Yale', 'Southmoor', 'SB', 3],
['Colorado', 'Yale', 'SB', 3],
['University of Denver', 'Colorado', 'SB', 3],
['Louisiana-Pearl', 'University of Denver', 'SB', 2],
['I-25-Broadway', 'Louisiana-Pearl', 'SB', 3],
['Alameda', 'I-25-Broadway', 'SB', 2],
['10th & Osage', 'Alameda', 'SB', 3],
['Auraria West', '10th & Osage', 'SB', 4],
['Empower Field at Mile High', 'Auraria West', 'SB', 1],
['Ball Arena-Elitch Gardens', 'Empower Field at Mile High', 'SB', 2],
['Union Station', 'Ball Arena-Elitch Gardens', 'SB', 2]
] AS segs
UNWIND segs AS s
MATCH (u:Station {code:s[0]}), (v:Station {code:s[1]})
MERGE (u)-[:E {dir:s[2], minutes:s[3]}]->(v);

WITH [
['Lincoln', 'County Line', 'NB', 2],
['County Line', 'Dry Creek', 'NB', 3],
['Dry Creek', 'Arapahoe at Village Center', 'NB', 3],
['Arapahoe at Village Center', 'Orchard', 'NB', 2],
['Orchard', 'Belleview', 'NB', 2],
['Belleview', 'Dayton', 'NB', 4],
['Dayton', 'Nine Mile', 'NB', 4],
['Nine Mile', 'Illiff', 'NB', 3],
['Illiff', 'Florida', 'NB', 4],
['Florida', 'Aurora Metro Center', 'NB', 7],
['Aurora Metro Center', '2nd Ave-Abilene', 'NB', 4],
['2nd Ave-Abilene', '13th Ave', 'NB', 3],
['13th Ave', 'Colfax', 'NB', 3],
['Colfax', 'Fitzsimons', 'NB', 3],
['Fitzsimons', 'Peoria', 'NB', 5],

['County Line', 'Lincoln', 'SB', 2],
['Dry Creek', 'County Line', 'SB', 3],
['Arapahoe at Village Center', 'Dry Creek', 'SB', 3],
['Orchard', 'Arapahoe at Village Center', 'SB', 2],
['Belleview', 'Orchard', 'SB', 2],
['Dayton', 'Belleview', 'SB', 4],
['Nine Mile', 'Dayton', 'SB', 4],
['Illiff', 'Nine Mile', 'SB', 3],
['Florida', 'Illiff', 'SB', 4],
['Aurora Metro Center', 'Florida', 'SB', 7],
['2nd Ave-Abilene', 'Aurora Metro Center', 'SB', 4],
['13th Ave', '2nd Ave-Abilene', 'SB', 3],
['Colfax', '13th Ave', 'SB', 3],
['Fitzsimons', 'Colfax', 'SB', 3],
['Peoria', 'Fitzsimons', 'SB', 5]


] AS segs
UNWIND segs AS s
MATCH (u:Station {code:s[0]}), (v:Station {code:s[1]})
MERGE (u)-[:R {dir:s[2], minutes:s[3]}]->(v);

MATCH p = (:Station)-[r:D|L|H|G|W|A|N|E|R]->(:Station) RETURN p;