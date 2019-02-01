
-- returns population in service area that lives in blocks with density >7000 persons/sq mi density
SELECT SUM(poptotal) FROM
     	block_groups_2010 as bg,
		primary_service_area as psa,
      	secondar_service_area as ssa
      WHERE
      	(ST_Intersects(  -- select bg groups that intersect primary or secondary service area
            psa.geom,
         	bg.geom
     	) OR
      	ST_Intersects(
      		ssa.geom,
        	bg.geom
        )) AND
        bg.poptotal / NULLIF(( bg.aland10::float / 2589988.11 ), 0) > 7000  -- and have density > 7000 pp/sq mi