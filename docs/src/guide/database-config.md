# Database Configuration

GeoIDs.jl uses PostgreSQL with the PostGIS extension to store and manage GEOID sets. The package provides flexible configuration options through environment variables.

## Environment Variables

You can customize the database connection using these environment variables:

| Environment Variable | Description | Default Value |
|---------------------|-------------|---------------|
| `GEOIDS_DB_NAME` | Database name | `geocoder` |
| `GEOIDS_DB_HOST` | Database host | `localhost` |
| `GEOIDS_DB_PORT` | Database port | `5432` |
| `GEOIDS_DB_USER` | Database user | Current system user |
| `GEOIDS_DB_PASSWORD` | Database password | Empty string |

## Setting Environment Variables

### Within Julia

You can set environment variables before loading the package:

```julia
# Set database configuration
ENV["GEOIDS_DB_NAME"] = "my_census_db"
ENV["GEOIDS_DB_HOST"] = "db.example.com"
ENV["GEOIDS_DB_PORT"] = "5433"
ENV["GEOIDS_DB_USER"] = "census_user"
ENV["GEOIDS_DB_PASSWORD"] = "secure_password"

# Load package
using GeoIDs
```

### Command Line

You can set environment variables when running your script:

```bash
GEOIDS_DB_NAME=my_census_db GEOIDS_DB_HOST=db.example.com julia my_script.jl
```

### Configuration File

For a more permanent solution, you can add configuration to your `.bashrc`, `.zshrc`, or equivalent:

```bash
# Add to your .bashrc or .zshrc
export GEOIDS_DB_NAME=my_census_db
export GEOIDS_DB_HOST=db.example.com
export GEOIDS_DB_USER=census_user
```

## Database Setup

GeoIDs.jl requires these database tables:

1. `census.counties` - Table containing county information with GEOID and geometry
2. `census.geoid_sets` - Table for GEOID set metadata (created automatically)
3. `census.geoid_set_members` - Table for GEOID set members (created automatically)
4. `census.geoid_set_changes` - Table for tracking changes (created automatically)

Tables 2-4 are created automatically when needed through the `setup_tables()` function.

### Required Schema

The `census.counties` table must exist and have the following schema:

```sql
CREATE TABLE census.counties (
    geoid VARCHAR(5) PRIMARY KEY,
    name VARCHAR(100),
    stusps VARCHAR(2),  -- State postal code
    geom GEOMETRY(MultiPolygon, 4269)  -- County geometry
    -- Other fields can vary
);
```

This table is typically created as part of the Census.jl package setup. 