# Fetch Module

```@meta
CurrentModule = GeoIDs
```

The Fetch module provides functions for retrieving GEOIDs based on various criteria, including spatial filters, state boundaries, and predefined regions.

## Spatial Filtering

Functions for retrieving GEOIDs based on spatial criteria:

```@docs
get_geoids_by_spatial_filter
```

## Regional and State Filters

Functions for retrieving GEOIDs based on predefined regions or state boundaries:

```@docs
get_geoids_by_state
get_western_geoids
get_eastern_geoids
get_florida_south_geoids
```

## County Information

Functions for retrieving information about counties:

```@docs
get_county_name
get_county_geom
get_county_centroid
```

## County Retrieval

```@docs
get_geoids_by_state
get_geoids_by_states
get_geoids_by_county_names
get_geoids_by_population_range
get_geoids_by_custom_query
```

## Module Index

```@index
Pages = ["fetch.md"]
``` 