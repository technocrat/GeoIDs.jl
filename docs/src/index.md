# GeoIDs.jl

```@meta
CurrentModule = GeoIDs
```

A Julia package for managing, storing, and manipulating geographic GEOID sets with versioning support.

## Overview

GeoIDs.jl provides a comprehensive solution for working with Census GEOID identifiers, particularly at the county level. The package offers:

- **Versioned GEOID Sets**: Store and manage GEOID sets with complete version history
- **Database Integration**: Persistent storage in PostgreSQL
- **Set Operations**: Union, intersection, difference, and symmetric difference operations
- **Spatial Filtering**: Generate GEOIDs based on spatial criteria (longitude, latitude, distance, etc.)
- **Backup/Restore**: Export and import GEOID sets with complete version history
- **Nation State Integration**: Connect with nation state definitions in the Census package

## Installation

```julia
import Pkg
Pkg.add(url="https://github.com/technocrat/GeoIDs.jl.git")
```

## Quick Start

```julia
using GeoIDs

# Create a new GEOID set with Florida counties
florida_counties = get_geoids_by_state("FL")
create_geoid_set("florida_counties", "All counties in Florida", florida_counties)

# Get southern Florida counties
south_fl = get_geoids_by_spatial_filter(:latitude, Dict(
    "min_lat" => 25.0,
    "max_lat" => 27.0
))
create_geoid_set("south_florida", "Southern Florida counties", south_fl)

# List all GEOID sets
sets = list_geoid_sets()
```

## Manual Outline

```@contents
Pages = [
    "guide/getting-started.md",
    "guide/geoid-sets.md",
    "guide/spatial-filtering.md",
    "guide/set-operations.md",
    "guide/versioning.md",
    "guide/database-config.md",
]
Depth = 2
```

## API Reference

```@contents
Pages = [
    "api/core.md",
    "api/db.md",
    "api/store.md",
    "api/fetch.md",
    "api/operations.md",
]
Depth = 2
```

## Index

```@index
``` 