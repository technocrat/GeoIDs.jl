# GeoIDs.jl

A Julia package for managing, storing, and manipulating geographic GEOID sets with versioning support. ***This is an early development version.***

This is intended for single-user operation on `localhost.` Database administration required for multiple concurrent users of the same database is beyond the scope of this package.

The problems that the package addresses are

1. Enabling offline use of US Census TIGER county boundary files
2. Creating and maintaining sets of GEOIDs


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

- PostgreSQL with PostGIS extension—documentation includes instructions
- Julia 1.6 or newer
- Database table `census.counties` with county GEOIDs and geometries—routines to create provided

## Configuration

You can configure the database connection using these environment variables:

| Environment Variable | Description | Default Value |
|---------------------|-------------|---------------|
| `GEOIDS_DB_NAME` | Database name | `tiger` |
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

## Database Setup

GeoIDs.jl provides tools to automatically set up the required database schema and download geographic data:

```julia
using GeoIDs

# Automatically set up the database with Census TIGER/Line county data
initialize_database()
```

This will:
- Create the `census` schema if it doesn't exist
- Enable the PostGIS extension if needed
- Download the latest Census TIGER/Line county shapefile
- Create and populate the `census.counties` table

For more control over the process, you can use the individual functions:

```julia
# Download county shapefile for a specific year
zip_path = download_county_shapefile("./data", 2022)

# Extract the shapefile
shapefile_path = extract_shapefile(zip_path, "./data")

# Load counties into the database manually
DB.with_connection() do conn
    setup_census_schema(conn)
    load_counties_to_db(shapefile_path, conn)
end
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

## Development Policy

The development of GeoIDs.jl follows the principles and guidelines outlined in the [POLICY.md](POLICY.md) file. This includes:

- Code quality standards emphasizing functional programming
- Database operation principles for resilience and safety
- GEOID set management best practices
- Development process guidelines
- User experience requirements
- Technical compatibility requirements

Contributors are encouraged to review this document before submitting changes.

## Author

Richard Careaga <public@careaga.net> 