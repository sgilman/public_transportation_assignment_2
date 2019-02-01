-- returns population of MBTA service area

SELECT 
	count(DISTINCT bg.id),
    SUM(bg.poptotal) 			-- sum poptotal for all bg groups selected
FROM
     	block_groups_2010 as bg,
		primary_service_area as psa,
      	secondar_service_area as ssa
      WHERE
      	ST_Intersects(				-- bgs intersect primary service area or secondary service area
            psa.geom,
         	bg.geom
     	) OR
      	ST_Intersects(
      		ssa.geom,
        	bg.geom
        )