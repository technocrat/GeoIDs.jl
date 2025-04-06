# Database Setup

GeoIDs.jl requires a PostgreSQL database with the PostGIS extension installed. The package provides tools to automatically set up the database schema and load necessary geographic data.

> **Note**: If you haven't installed PostgreSQL yet, please follow our [PostgreSQL Setup Guide](postgresql-setup.md) first.

## Automatic Setup

The simplest way to set up your database is to use the automatic initialization function:

```julia
using GeoIDs
initialize_database()
```

This function will:

1. Create the `census` schema if it doesn't exist
2. Enable the PostGIS extension if needed
3. Use the local U.S. Census TIGER/Line county shapefile from the GeoIDs.jl/data directory
4. Create the `census.counties` table
5. Load county data with GEOIDs and geometries

## Manual Setup

If you prefer to set up your database manually, you can use the individual functions:

```julia
using GeoIDs

# Connect to the database
DB.with_connection() do conn
    # Create the census schema
    setup_census_schema(conn)
    
    # Get the local county shapefile from GeoIDs.jl/data directory
    zip_path = download_county_shapefile("./data")
    
    # Extract the shapefile
    shapefile_path = extract_shapefile(zip_path, "./data")
    
    # Load counties into the database
    load_counties_to_db(shapefile_path, conn)
end
```

## Required Database Tables

The GeoIDs.jl package requires the following database tables:

1. `census.counties` - Table containing county information with GEOID and geometry
2. `census.geoid_sets` - Table for GEOID set metadata (created automatically)
3. `census.geoid_set_members` - Table for GEOID set membership (created automatically)
4. `census.geoid_set_changes` - Table for tracking changes to GEOID sets (created automatically)

Only the `census.counties` table needs to be populated with data from the Census TIGER/Line shapefile.

## Local Shapefile Usage

GeoIDs.jl now uses a local copy of the shapefile from the GeoIDs.jl/data directory instead of downloading it. Make sure the shapefile exists at:

```
GeoIDs.jl/data/cb_2023_us_county_500k.zip
```

You can customize the year by specifying a different year parameter:

```julia
# Use local 2022 county shapefile
zip_path = download_county_shapefile("./data", 2022)
```

In this case, ensure the file exists at `GeoIDs.jl/data/cb_2022_us_county_500k.zip`.

## Checking the Database

To verify that your database is set up correctly, you can run:

```julia
using GeoIDs
using DataFrames

# Execute a query to check counties table
DB.with_connection() do conn
    result = DB.execute(conn, "SELECT COUNT(*) FROM census.counties;")
    println("Number of counties: $(result[1, 1])")
end
```

## Creating the Database

The `initialize_database()` function automatically creates the `tiger` database if it doesn't exist. It performs these steps:

1. Checks if the database exists
2. Creates the database if it doesn't exist
3. Enables the PostGIS and PostGIS topology extensions
4. Creates the schema and loads county data

You don't need to manually create the database, just run:

```julia
using GeoIDs
initialize_database()
```

### Manual Database Creation (if needed)

If you prefer to create the database manually:

```bash
# Create the database
createdb tiger

# Enable PostGIS extension
psql -d tiger -c "CREATE EXTENSION IF NOT EXISTS postgis;"
psql -d tiger -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;"
```

For detailed instructions on setting up PostgreSQL and PostGIS, please refer to our [PostgreSQL Setup Guide](postgresql-setup.md).

After your database is ready, you can run the `initialize_database()` function to set up the schema and load the data. 