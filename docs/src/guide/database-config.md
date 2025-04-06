# Database Configuration

GeoIDs.jl uses PostgreSQL with the PostGIS extension to store and manage GEOID sets. The package provides flexible configuration options through environment variables.

> **Note**: If you need to install and set up PostgreSQL first, see our [PostgreSQL Setup Guide](postgresql-setup.md).

## Environment Variables

You can customize the database connection using these environment variables:

| Environment Variable | Description | Default Value |
|---------------------|-------------|---------------|
| `GEOIDS_DB_NAME` | Database name | `tiger` |
| `GEOIDS_DB_HOST` | Database host | `localhost` |
| `GEOIDS_DB_PORT` | Database port | `5432` |

> **Note**: The package now uses PostgreSQL's default socket authentication which generally doesn't require username and password on local development setups. This is especially convenient on macOS with Homebrew installations.

## Setting Environment Variables

### Within Julia

You can set environment variables before loading the package:

```julia
# Set database configuration
ENV["GEOIDS_DB_NAME"] = "my_census_db"
ENV["GEOIDS_DB_HOST"] = "db.example.com"
ENV["GEOIDS_DB_PORT"] = "5433"

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
```

## Connection String Format

The connection string is formatted as:

```
postgresql://host:port/dbname
```

For example:
```
postgresql://localhost:5432/tiger
```

This format uses PostgreSQL's default authentication mechanism, which is socket authentication on most development setups.

## Database Setup

GeoIDs.jl requires these database tables:

1. `census.counties` - Table containing county information with GEOID and geometry
2. `census.geoid_sets` - Table for GEOID set metadata (created automatically)
3. `census.geoid_set_members` - Table for GEOID set members (created automatically)
4. `census.geoid_set_changes` - Table for tracking changes (created automatically)

All required tables are created automatically when you run the `initialize_database()` function. This function:

1. Creates the `census` schema if it doesn't exist
2. Enables the PostGIS extension if needed
3. Uses the local U.S. Census TIGER/Line county shapefile from the GeoIDs.jl/data directory
4. Creates the `census.counties` table with proper schema
5. Loads county data with GEOIDs and geometries
6. Sets up the GEOID set management tables

### Required Schema

The `census.counties` table must have the following schema:

```sql
CREATE TABLE census.counties (
    geoid VARCHAR(5) PRIMARY KEY,
    name VARCHAR(100),
    stusps VARCHAR(2),  -- State postal code
    geom GEOMETRY(MultiPolygon, 4269)  -- County geometry
    -- Other fields can vary
);
```

This table is automatically created and populated when you run `initialize_database()`. 