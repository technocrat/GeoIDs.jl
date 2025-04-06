# Core Module

```@meta
CurrentModule = GeoIDs
```

The Core module contains foundational functionality for GeoIDs.jl, including predefined GEOID constants, initialization functions, and backup/restore capabilities.

## Predefined Constants

The following constants provide quick access to common geographic regions. They are loaded from the database during package initialization:

- `WESTERN_GEOIDS`: Counties west of 100°W longitude (traditionally requiring irrigation)
- `EASTERN_GEOIDS`: Counties between 90°W and 100°W (historically high rainfall)
- `FLORIDA_SOUTH_GEOIDS`: Florida counties south of 29°N latitude
- `COLORADO_BASIN_GEOIDS`: Counties in the Colorado River Basin

## Initialization Functions

```@docs
initialize_predefined_geoid_sets
load_predefined_geoids
initialize_database
```

## Backup and Restore

These functions enable exporting and importing GEOID sets with their complete version history:

```@docs
backup_geoid_sets
restore_geoid_sets
```

## Other Core Functions

```@docs
__init__
```

## Module Index

```@index
Pages = ["core.md"]
``` 