# Setup Module

```@meta
CurrentModule = GeoIDs.Setup
```

The Setup module provides functionality for initializing the database schema and acquiring Census TIGER/Line shapefiles.

## Database Initialization

Main function to completely initialize the database:

```@docs
initialize_database
ensure_database_exists
```

## Schema Setup

Functions for setting up the database schema:

```@docs
setup_census_schema
```

## Census Data Management

Functions for managing Census geographic data:

```@docs
download_county_shapefile
extract_shapefile
load_counties_to_db
```

> **Note**: The `download_county_shapefile` function now uses a local shapefile from the GeoIDs.jl/data directory instead of downloading it from the internet.

## Module Index

```@index
Pages = ["setup.md"]
``` 