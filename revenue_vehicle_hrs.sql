CREATE OR REPLACE VIEW trip_vehicle_hrs as 
    SELECT
        t.trip_id,
        MIN(st.departure_time) as earliest,  -- earliest departure time on the trip
        MAX(st.arrival_time) as latest,	     -- latest arrival time on the trip
        EXTRACT(EPOCH FROM (
            to_timestamp(MAX(st.arrival_time), 'hh24:mi:ss') -
            to_timestamp(MIN(st.departure_time), 'hh24:mi:ss')::timestamp
        )) / 3600 as vehicle_hrs,             -- difference between latest and earliest time to get time on trip
        MIN(r.route_desc) as route_desc       

    FROM
        gtfs_stop_times as st,
        gtfs_trips as t,
        gtfs_routes as r,
        calendar_dates as cd
    WHERE
        st.trip_id = t.trip_id AND			 -- join gtfs_stop_times, gtfs_trips, gtfs_routes, calendar dates
        t.route_id = r.route_id AND
        t.service_id = cd.service_id AND
        cd.date = '20190126' AND			  -- modify date to see services on that day (between 1/15 and 3/15)
        r.route_desc LIKE '%Bus'			  -- only select bus services
    GROUP BY t.trip_id;						  --group by trip_id to get aggregate statistics for each trip

SELECT
	route_desc,
    SUM(vehicle_hrs)							-- get sum of all trip times for 
FROM	
	trip_vehicle_hrs
GROUP BY route_desc