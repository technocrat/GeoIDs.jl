# Spatial Filtering

GeoIDs.jl provides powerful spatial filtering capabilities to generate GEOIDs based on geographic criteria. These functions allow you to select counties based on latitude, longitude, distance from a point, or within a bounding box.

## Basic Usage

The main function for spatial filtering is `get_geoids_by_spatial_filter`:

```julia
get_geoids_by_spatial_filter(filter_type::Symbol, parameters::Dict) -> Vector{String}
```

- `filter_type`: The type of spatial filter to apply (`:latitude`, `:longitude`, `:distance`, or `:bounding_box`)
- `parameters`: A dictionary containing the parameters for the specified filter type
- Returns: A vector of GEOIDs matching the spatial criteria

## Filter Types

### Latitude Filter

Select counties based on their latitude range:

```julia
# Get counties in southern Florida (below 27° N)
south_fl = get_geoids_by_spatial_filter(:latitude, Dict(
    "min_lat" => 25.0,
    "max_lat" => 27.0
))
```

**Parameters:**
- `min_lat`: Minimum latitude (decimal degrees)
- `max_lat`: Maximum latitude (decimal degrees)

### Longitude Filter

Select counties based on their longitude range:

```julia
# Get counties in western United States
western_counties = get_geoids_by_spatial_filter(:longitude, Dict(
    "min_lon" => -125.0,
    "max_lon" => -110.0
))
```

**Parameters:**
- `min_lon`: Minimum longitude (decimal degrees)
- `max_lon`: Maximum longitude (decimal degrees)

### Distance Filter

Select counties within a specified distance from a point:

```julia
# Get counties within 100 kilometers of Chicago
chicago_area = get_geoids_by_spatial_filter(:distance, Dict(
    "lat" => 41.8781,
    "lon" => -87.6298,
    "distance" => 100.0,  # kilometers
    "unit" => "km"
))

# Get counties within 50 miles of Miami
miami_area = get_geoids_by_spatial_filter(:distance, Dict(
    "lat" => 25.7617,
    "lon" => -80.1918,
    "distance" => 50.0,
    "unit" => "mi"
))
```

**Parameters:**
- `lat`: Latitude of the center point (decimal degrees)
- `lon`: Longitude of the center point (decimal degrees)
- `distance`: Maximum distance from the center point
- `unit`: Distance unit ("km" for kilometers or "mi" for miles, default: "km")
- `include_intersecting`: Whether to include counties that intersect the radius or only those fully contained (default: true)

### Bounding Box Filter

Select counties within or intersecting a rectangular bounding box:

```julia
# Get counties in the southeastern United States
southeast = get_geoids_by_spatial_filter(:bounding_box, Dict(
    "min_lat" => 30.0,
    "max_lat" => 35.0,
    "min_lon" => -90.0,
    "max_lon" => -80.0,
    "include_intersecting" => true
))
```

**Parameters:**
- `min_lat`: Minimum latitude (decimal degrees)
- `max_lat`: Maximum latitude (decimal degrees)
- `min_lon`: Minimum longitude (decimal degrees)
- `max_lon`: Maximum longitude (decimal degrees)
- `include_intersecting`: Whether to include counties that intersect the bounding box or only those fully contained (default: true)

## Helper Functions

### Getting Counties by Region

The package provides shortcuts for common regional selections:

```julia
# Get all counties in the western United States
western_counties = get_western_geoids()

# Get all counties in the eastern United States
eastern_counties = get_eastern_geoids()

# Get counties in southern Florida
south_florida = get_florida_south_geoids()
```

### Getting Counties by State

You can get all counties in a specific state:

```julia
# Get all counties in California
ca_counties = get_geoids_by_state("CA")

# Get all counties in New York
ny_counties = get_geoids_by_state("NY")
```

## Technical Details

Spatial filtering uses PostGIS spatial functions to perform geographic queries:

- Latitude/longitude filters use the `ST_Y(ST_PointOnSurface(geom))` and `ST_X(ST_PointOnSurface(geom))` functions
- Distance filters use the `ST_DWithin` function with proper distance units
- Bounding box filters use the `ST_MakeEnvelope` and either `ST_Covers` or `ST_Intersects` functions

## Performance Considerations

Spatial queries can be computationally intensive. The package:

1. Uses spatial indices on the geometry column for efficient querying
2. Converts all calculations to the appropriate coordinate reference system
3. Caches common query results for faster repeated access

For large datasets or complex queries, consider:
- Starting with a more restrictive spatial filter and then refining results
- Combining spatial filters with other criteria using set operations
- Creating and reusing GEOID sets for frequently used geographic areas 