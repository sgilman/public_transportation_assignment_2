CREATE OR REPLACE VIEW trip_vehicle_hrs as 
    SELECT
        t.trip_id,
        MIN(st.departure_time) as earliest,
        MAX(st.arrival_time) as latest,
        EXTRACT(EPOCH FROM (
            to_timestamp(MAX(st.arrival_time), 'hh24:mi:ss') -
            to_timestamp(MIN(st.departure_time), 'hh24:mi:ss')::timestamp
        )) / 3600 as vehicle_hrs,
        MIN(r.route_desc) as route_desc

    FROM
        gtfs_stop_times as st,
        gtfs_trips as t,
        gtfs_routes as r,
        calendar_dates as cd
    WHERE
        st.trip_id = t.trip_id AND
        t.route_id = r.route_id AND
        t.service_id = cd.service_id AND
        cd.date = '20190219' AND
        r.route_desc LIKE '%Bus'
    GROUP BY t.trip_id;

SELECT
	route_desc,
    SUM(vehicle_hrs)
FROM
	trip_vehicle_hrs
GROUP BY route_desc