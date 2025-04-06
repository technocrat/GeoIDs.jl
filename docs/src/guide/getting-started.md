# Getting Started

## Installation

To install GeoIDs.jl, use the Julia package manager:

```julia
import Pkg
Pkg.add(url="https://github.com/technocrat/GeoIDs.jl.git")
```

## Setup

Before using GeoIDs.jl, you need to ensure you have:

1. A PostgreSQL database with PostGIS extension
2. The `census.counties` table with county GEOIDs and geometries

You can configure the database connection using environment variables:

```julia
# Set database connection parameters
ENV["GEOIDS_DB_NAME"] = "geocoder"  # Default
ENV["GEOIDS_DB_HOST"] = "localhost" # Default
ENV["GEOIDS_DB_PORT"] = "5432"      # Default

# Load the package
using GeoIDs
```

## Basic Usage

### Creating GEOID Sets

Create a new GEOID set by first fetching some GEOIDs:

```julia
# Get all Florida counties
florida_counties = get_geoids_by_state("FL")

# Create a named set
create_geoid_set("florida_counties", "All counties in Florida", florida_counties)
```

### Retrieving GEOID Sets

```julia
# Get a GEOID set
fl_geoids = get_geoid_set("florida_counties")

# Count the number of counties
println("Florida has $(length(fl_geoids)) counties")
```

### Spatial Filtering

Get counties based on spatial criteria:

```julia
# Get southern Florida counties (below 27° latitude)
south_fl = get_geoids_by_spatial_filter(:latitude, Dict(
    "min_lat" => 25.0,
    "max_lat" => 27.0
))

# Create a set with these counties
create_geoid_set("south_florida", "Southern Florida counties", south_fl)
```

### GEOID Set Operations

```julia
# Create a new set as the difference between two sets
central_fl = difference_geoid_sets(
    "florida_counties", 
    "south_florida", 
    "central_florida",
    "Florida counties excluding southern counties"
)

# Create a union of multiple sets
east_coast = union_geoid_sets(
    ["florida_counties", "georgia_coastal"], 
    "southeast_coast", 
    "Southeast coastal counties"
)
```

### Modifying Sets

Add or remove counties from an existing set:

```julia
# Add counties to a set
add_to_geoid_set("south_florida", ["12021"]) # Add Collier County

# Remove counties from a set
remove_from_geoid_set("south_florida", ["12025"]) # Remove Dade County
```

### Listing and Version Management

```julia
# List all GEOID sets
sets = list_geoid_sets()
println("Available sets: $(sets.set_name)")

# View version history of a set
versions = list_geoid_set_versions("south_florida")
println("Version history: $(versions)")

# Rollback to a previous version
rollback_geoid_set("south_florida", 1)
```

## Next Steps

- Learn about [GEOID Sets](./geoid-sets.md) in detail
- Explore advanced [Spatial Filtering](./spatial-filtering.md) capabilities
- Understand [Set Operations](./set-operations.md) for combining and manipulating GEOID sets
- Discover [Versioning](./versioning.md) features for tracking changes
- Configure database connections with [Database Configuration](./database-config.md) 