# GeoIDs.jl

A Julia package for managing, storing, and manipulating geographic GEOID sets with versioning support.

## Features

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

## Requirements

- PostgreSQL with PostGIS extension
- Julia 1.6 or newer
- Database table `census.counties` with county GEOIDs and geometries

## Configuration

You can configure the database connection using these environment variables:

| Environment Variable | Description | Default Value |
|---------------------|-------------|---------------|
| `GEOIDS_DB_NAME` | Database name | `geocoder` |
| `GEOIDS_DB_HOST` | Database host | `localhost` |
| `GEOIDS_DB_PORT` | Database port | `5432` |
| `GEOIDS_DB_USER` | Database user | Current system user |
| `GEOIDS_DB_PASSWORD` | Database password | Empty string |

Examples:

Set in Julia before using the package:
```julia
ENV["GEOIDS_DB_NAME"] = "my_custom_database"
ENV["GEOIDS_DB_HOST"] = "db.example.com"
using GeoIDs
```

Set in shell before running your script:
```bash
GEOIDS_DB_NAME=my_custom_database GEOIDS_DB_HOST=db.example.com julia my_script.jl
```

## Basic Usage

```julia
using GeoIDs

# Create a new GEOID set
florida_counties = get_geoids_by_state("FL")
create_geoid_set("florida_counties", "All counties in Florida", florida_counties)

# Get southern Florida counties
south_fl = get_geoids_by_spatial_filter(:latitude, Dict(
    "min_lat" => 25.0,
    "max_lat" => 27.0
))
create_geoid_set("south_florida", "Southern Florida counties", south_fl)

# Create a subset using difference
central_fl = difference_geoid_sets("florida_counties", "south_florida", "central_florida")

# Add counties to a set
add_to_geoid_set("south_florida", ["12021"]) # Add Collier County

# Remove counties from a set
remove_from_geoid_set("south_florida", ["12025"]) # Remove Dade County

# List all versions of a set
versions = list_geoid_set_versions("south_florida")

# Rollback to a previous version
rollback_geoid_set("south_florida", 1)
```

## GEOID Set Operations

```julia
# Union of multiple sets
union_geoid_sets(["south_florida", "central_florida"], "combined_florida")

# Intersection of sets
intersect_geoid_sets(["coastal_counties", "florida_counties"], "florida_coastal")

# Difference between sets
difference_geoid_sets("florida_counties", "coastal_counties", "florida_inland")

# Symmetric difference (elements in either set but not both)
symmetric_difference_geoid_sets("florida_counties", "georgia_counties", "fl_ga_border")
```

## Spatial Filtering

```julia
# Counties in a longitude range
west_counties = get_geoids_by_spatial_filter(:longitude, Dict(
    "min_lon" => -120.0,
    "max_lon" => -110.0
))

# Counties within a bounding box
southeast = get_geoids_by_spatial_filter(:bounding_box, Dict(
    "min_lon" => -85.0,
    "max_lon" => -80.0,
    "min_lat" => 25.0,
    "max_lat" => 30.0
))

# Counties within distance of a point
miami_area = get_geoids_by_spatial_filter(:distance, Dict(
    "center_lon" => -80.191790,
    "center_lat" => 25.761681,
    "radius_miles" => 50
))
```

## Backing Up and Restoring

```julia
# Backup all GEOID sets with version history
backup_geoid_sets("geoid_backup_2023-10-01.json")

# Restore sets from backup
restore_geoid_sets("geoid_backup_2023-10-01.json")
```

## Integration with Census.jl

The GeoIDs.jl package is designed to work seamlessly with the Census.jl package for analyzing U.S. Census data. By managing GEOID sets separately, we gain:

1. Improved modularity and separation of concerns
2. Version control for geographic definitions
3. Enhanced spatial querying capabilities
4. Persistent storage of custom geographic regions

## License

MIT License

## Author

Richard Careaga <public@careaga.net> 