elementary-pattern = gz_*_*_950_*_500k.zip
unified-pattern = gz_*_*_970_*_500k.zip
elementary-geoid = SDELM
unified-geoid = SDUNI

PHONY: all clean

all: transformed/districts.geojson

transformed/districts.geojson: combined/districts.geojson
	cat $< | python3 scripts/transform_districts.py > $@

combined/districts.geojson: filtered/elementary.geojson filtered/unified.geojson
	mapshaper -i $^ combine-files -merge-layers -o $@

# combined/clipped.geojson: filtered/elementary.geojson filtered/unified.geojson
# 	mapshaper filtered/unified.geojson \
# 	-erase $< remove-slivers \
# 	-filter-fields GEOID,NAME -o $@

# combined/clipped.geojson: filtered/elementary.geojson filtered/unified.geojson
# 	mapshaper filtered/unified.geojson -each 'INIT_AREA = this.area' \
# 	-erase $< remove-slivers \
# 	-each 'AREA = this.area' \
# 	-filter 'AREA > (INIT_AREA * 0.95)' \
# 	-filter-fields GEOID,NAME -o $@

filtered/elementary.geojson: districts/elementary.geojson
	mapshaper $< \
	-join input/seda-ids.csv field-types=GEOID:str keys=GEOID,GEOID calc='COUNT = count()' \
	-filter 'COUNT > 0' \
	-filter-fields GEOID,NAME -o $@

filtered/unified.geojson: districts/unified.geojson
	mapshaper $< \
	-join input/seda-ids.csv field-types=GEOID:str keys=GEOID,GEOID calc='COUNT = count()' \
	-filter 'COUNT > 0' \
	-filter-fields GEOID,NAME -o $@

districts/%.geojson:
	mkdir -p input/$*
	wget --no-use-server-timestamps -np -nd -r -P input/$* -A '$($*-pattern)' ftp://ftp2.census.gov/geo/tiger/GENZ2010/
	for f in ./input/$*/*.zip; do unzip -d ./input/$* $$f; done
	mapshaper ./input/$*/*.shp combine-files \
	-each "this.properties.GEOID = this.properties.STATE + this.properties.$($*-geoid)" \
	-filter-fields GEOID,NAME \
	-o $@ combine-layers format=geojson
