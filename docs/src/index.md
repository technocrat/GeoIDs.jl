# GeoIDs.jl

```@meta
CurrentModule = GeoIDs
```

A Julia package for managing, storing, and manipulating geographic GEOID sets with versioning support.

## Overview

GeoIDs.jl provides a comprehensive solution for working with Census GEOID identifiers, particularly at the county level. The package enables you to:

- **Create and Manage Geographic Area Sets**: Define sets of counties for analysis
- **Track Changes Over Time**: Full version history for every geographic definition
- **Apply Set Operations**: Union, intersection, difference, and symmetric difference
- **Filter Spatially**: Select counties by latitude, longitude, distance, or bounding box
- **Back Up and Restore**: Export and import full version history
- **Access Census Data**: Integrate with TIGER/Line shapefiles from local sources

## Prerequisites

GeoIDs.jl requires:

- **PostgreSQL** database server (version 12 or higher)
- **PostGIS** extension (version 3.0 or higher)
- **Local TIGER/Line shapefiles** in the GeoIDs.jl/data directory

> **Important**: Before using GeoIDs.jl, follow our [PostgreSQL Setup Guide](guide/postgresql-setup.md) to install and configure these prerequisites.

> **Note**: GeoIDs.jl now uses PostgreSQL's default socket authentication which doesn't require username and password on local development setups.

## Installation

```julia
import Pkg
Pkg.add(url="https://github.com/technocrat/GeoIDs.jl.git")
```

## Quick Start

### 1. Set Up the Database

```julia
using GeoIDs

# Initialize the database (only needed once)
initialize_database()
```

This will automatically use the local TIGER/Line shapefile from the GeoIDs.jl/data directory and initialize the database schema.

### 2. Create GEOID Sets

```julia
# Get all Florida counties
florida_counties = get_geoids_by_state("FL")
create_geoid_set("florida_counties", "All counties in Florida", florida_counties)

# Filter for southern Florida counties
south_fl = get_geoids_by_spatial_filter(:latitude, Dict(
    "min_lat" => 25.0,
    "max_lat" => 27.0
))
create_geoid_set("south_florida", "Southern Florida counties", south_fl)
```

### 3. Perform Set Operations

```julia
# Get counties in Florida but not in South Florida
central_fl = difference_geoid_sets(
    "florida_counties", 
    "south_florida", 
    "central_florida"
)

# Get coastal counties in Florida
coastal_fl = intersect_geoid_sets(
    ["florida_counties", "coastal_counties"],
    "florida_coastal"
)
```

### 4. List and Manage Sets

```julia
# List all available GEOID sets
sets = list_geoid_sets()

# View version history of a set
versions = list_geoid_set_versions("south_florida")

# Add a county to a set
new_version = add_to_geoid_set("south_florida", ["12021"])  # Add Collier County

# Revert to a previous version
rollback_geoid_set("south_florida", 1)
```

## Documentation

### User Guides

```@contents
Pages = [
    "guide/postgresql-setup.md",
    "guide/database-config.md",
    "guide/database-setup.md",
    "guide/getting-started.md",
    "guide/geoid-sets.md",
    "guide/spatial-filtering.md",
    "guide/set-operations.md",
    "guide/versioning.md",
]
Depth = 2
```

### API Reference

```@contents
Pages = [
    "api/core.md",
    "api/db.md",
    "api/setup.md",
    "api/store.md",
    "api/fetch.md",
    "api/operations.md",
]
Depth = 2
```

## Index

```@index
``` 