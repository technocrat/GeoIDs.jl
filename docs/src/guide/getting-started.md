# Getting Started

## Installation

To install GeoIDs.jl, use the Julia package manager:

```julia
import Pkg
Pkg.add(url="https://github.com/technocrat/GeoIDs.jl.git")
```

## Setup

Before using GeoIDs.jl, you need to:

1. **Set up PostgreSQL with PostGIS** - Follow our [PostgreSQL Setup Guide](./postgresql-setup.md)
2. **Configure database connection** - See [Database Configuration](./database-config.md)
3. **Initialize the database schema** - Use [Database Setup](./database-setup.md) instructions

For quick setup with default settings, run:

```julia
using GeoIDs

# Initialize the database with default settings
initialize_database()
```

You can configure the database connection using environment variables:

```julia
# Set database connection parameters
ENV["GEOIDS_DB_NAME"] = "tiger"     # Default
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

For more details on using GeoIDs.jl, explore these guides:

- [PostgreSQL Setup](./postgresql-setup.md) - Installing and configuring PostgreSQL with PostGIS
- [Database Configuration](./database-config.md) - Configuring database connection settings
- [Database Setup](./database-setup.md) - Initializing the database schema and county data
- [GEOID Sets](./geoid-sets.md) - Working with GEOID sets in detail
- [Spatial Filtering](./spatial-filtering.md) - Advanced spatial querying capabilities
- [Set Operations](./set-operations.md) - Combining and manipulating GEOID sets
- [Versioning](./versioning.md) - Tracking changes to GEOID sets over time 