# Core Module

```@meta
CurrentModule = GeoIDs
```

The core functionality of GeoIDs.jl.

## Constants

These constants are loaded from the database at runtime:

- `WESTERN_GEOIDS`: Counties west of 100°W longitude requiring irrigation
- `EASTERN_GEOIDS`: Counties between 90°W and 100°W with historically high rainfall
- `FLORIDA_SOUTH_GEOIDS`: Florida counties south of 29°N latitude
- `COLORADO_BASIN_GEOIDS`: Counties in the Colorado River Basin

## Core Functions

```@docs
initialize_predefined_geoid_sets
load_predefined_geoids
backup_geoid_sets
restore_geoid_sets
```

## Module Index

```@index
Pages = ["core.md"]
``` 