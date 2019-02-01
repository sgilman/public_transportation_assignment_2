-- returns number of residnets living within 0.5 miles of bus stop

CREATE OR REPLACE VIEW bus_stops as  -- create new view for just bus stops (except Supplemental Bus, which is excluded from base coverage according to the Serivice Guidelines)
	SELECT
		s.stop_id,
        MIN(s.stop_lon) as stop_lon,
        MIN(s.stop_lat) as stop_lat
     FROM
     	gtfs_stops as s,
        gtfs_stop_times as st,
        gtfs_trips as t,
        gtfs_routes as r
     WHERE
     	s.stop_id = st.stop_id AND
        st.trip_id = t.trip_id AND
        t.route_id = r.route_id AND
        r.route_desc LIKE '%Bus' AND
        r.route_desc <> 'Supplemental Bus'
	GROUP BY s.stop_id;
    
CREATE TABLE all_bus_stop_buffers as
	SELECT
    	ST_UNION(					--1. make gemoetry out of lat/long 2.set SRID to 4326 3. transform to 32619 4. Buffer by 804m (0.5 mi) 6. union buffers together						
            ST_Buffer(
        		ST_Transform(
        			ST_SetSRID(
        				ST_MakePoint(bs.stop_lon, bs.stop_lat),		
                	4326),
            	32619),
            804.672)
        ) as the_geom
     FROM bus_stops as bs;

 SELECT						-- sum poptotal for blockgroups that intersected buffers from last step
 	SUM(poptotal)
 FROM
 	block_groups_2010 as bg,
    all_bus_stop_buffers as absb
WHERE
	ST_Intersects(
       ST_Transform(absb.the_geom, 4326),
       bg.geom
    )
       
 	
     
    