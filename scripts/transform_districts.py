import csv
import json
import os
import sys

from shapely.geometry import mapping, shape
from shapely.ops import cascaded_union

with open(
    os.path.join(os.path.dirname(os.path.dirname(__file__)),
    "input",
    "ny-district-ids.csv"
), "r") as f:
    ny_dist_ids = [r[0] for r in csv.reader(f)][1:]

# TODO: Add name as last item in tuple?
COMBINE_DISTRICTS = (
    (['4700147', '4700148', '4702940'], '470290'),
    (['0601414', '0635370'], '0635370'),
    (['4800054', '4800073', '4800091', '4800117', '4800128', '4800209', '4833060'], '4833060'),
    (ny_dist_ids, '3620580'),
)

DISTRICTS_TO_COMBINE = []
for cd in COMBINE_DISTRICTS:
    DISTRICTS_TO_COMBINE.extend(cd[0])


if __name__ == '__main__':
    districts = json.load(sys.stdin)
    features_to_combine = [
        feat for feat
        in districts['features']
        if feat['properties']['GEOID'] in DISTRICTS_TO_COMBINE
    ]
    districts['features'] = [
        feat for feat
        in districts['features']
        if feat['properties']['GEOID'] not in DISTRICTS_TO_COMBINE
    ]

    combined_districts = []
    for input_geoids, output_geoid in COMBINE_DISTRICTS:
        # Assert that count districts pulled is count GEOIDs
        input_districts = [
            shape(feat['geometry']) for feat
            in features_to_combine
            if feat['properties']['GEOID'] in input_geoids
        ]
        # print(f"# input GEOIDs {len(input_geoids)} # input districts {len(input_districts)}")
        # Combine
        combined_districts.append({
            'type': 'Feature',
            'properties': {
                'GEOID': output_geoid,
                'NAME': '', # TODO: Add name
            },
            'geometry': mapping(cascaded_union(input_districts)),
        })
    districts['features'].extend(combined_districts)
    json.dump(districts, sys.stdout)
