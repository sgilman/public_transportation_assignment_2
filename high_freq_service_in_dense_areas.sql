 -- returns population in dense census block groups (>7,000 persons/sq mi) that live within 0.5 mi of frequent service (Rapid Tranist, Key Bus stop or bus stop with a service interval 06:00-24:00 (the Key Bus standard) and <15 min avg headway)
 
 -- calculates service interval and avg headway per stop
 CREATE OR REPLACE VIEW interval_and_headway AS
 SELECT q.real_stop_id,  -- aggregates earliest stop, latest stop, service interval by stop_id
    count(DISTINCT q.real_trip_id) AS trips_per_stop,  
    min(q.stop_time) AS earliest,
    max(q.stop_time) AS latest,
    max(q.stop_time) - min(q.stop_time) AS service_interval,
    (max(q.stop_time_secs) - min(q.stop_time_secs)) / (60 * count(DISTINCT q.real_trip_id))::float AS avg_headway
   FROM ( SELECT st.stop_id AS real_stop_id,
            t.trip_id AS real_trip_id,
            to_timestamp(st.departure_time, 'hh24:mi:ss'::text)::timestamp without time zone AS stop_time, --converts departure_time (text) to timestamp
            date_part('epoch'::text, to_timestamp(st.departure_time, 'hh24:mi:ss'::text)::timestamp without time zone) - date_part('epoch'::text, '0001-01-01 00:00:00 BC'::timestamp without time zone) AS stop_time_secs -- extracts "epoch" from stop time (# seconds since 1970), then subtracts start of day (defined arbitrarily as 0001-01-01 00:00:00) to get # of seconds since midnight 
           FROM gtfs_stop_times st,
            gtfs_routes r,
            gtfs_trips t,
            calendar c,
            calendar_dates cd
          WHERE st.trip_id = t.trip_id AND  -- join stop times, routes, trips, calendar, calendar_dates
         		t.route_id = r.route_id AND
         		t.service_id = c.service_id::text AND
         		t.service_id = cd.service_id::text AND
         		cd.date::text = '20190219'::text AND -- select for typical weekday (2/19/19)
         		r.route_desc ~~ '%Bus%'::text AND r.route_desc <> 'Key Bus'::text) q -- only select buses that aren't already labelled key bus stops
  GROUP BY q.real_stop_id
  ORDER BY ((max(q.stop_time_secs) - min(q.stop_time_secs)) / (60 * count(DISTINCT q.real_trip_id))::double precision);
  
-- create union of key bus stops and high frequency bus stops
CREATE OR REPLACE VIEW high_freq_bus_stops AS
SELECT * FROM gtfs_stops
WHERE stop_id IN 
	(SELECT stop_id FROM key_bus_stops UNION
    SELECT
     	interval_and_headway.real_stop_id as stop_id
     FROM interval_and_headway WHERE  -- select other bus stops that meet criteria: service interval from 06:00 to 24:00 and avg headway < 15 min
     	(earliest <= to_timestamp('06:00:00', 'hh24:mi:ss')::timestamp AND
         latest >= to_timestamp('24:00:00', 'hh24:mi:ss')::timestamp AND
         avg_headway < 15));

-- create 0.5 mile buffer (804m) around selected bus stops
CREATE OR REPLACE VIEW hi_freq_buffers_union_table AS
	SELECT
    	ST_Union(
            ST_Buffer(
                ST_Transform(
                	hfs.the_geom,
                4326),
             804.672)
            ) as the_geom
    FROM
    	high_freq_bus_stops as hfs;

-- sum population where bg groups intersect bus stop buffer and have density > 7000
SELECT SUM(poptotal) FROM 
     	block_groups_2010 as bg, 
     	hi_freq_buffers_union as hfb
     WHERE 
     ST_Intersects( 
            bg.geom,
        	hfb.the_geom
        	) AND
     bg.poptotal / NULLIF(( bg.aland10::float / 2589988.11 ), 0) > 7000;