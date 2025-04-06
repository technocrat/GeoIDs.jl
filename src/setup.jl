"""
    Setup

Module for setting up the database schema and acquiring necessary shapefiles.
Handles downloading and processing Census TIGER/Line county shapefiles.
"""
module Setup

using LibPQ
using ArchGDAL
using ZipFile
using HTTP
using DataFrames
using ..DB # Use DB module from parent

export setup_census_schema, download_county_shapefile, load_counties_to_db, initialize_database, ensure_database_exists, create_sample_counties_table

"""
    setup_census_schema(conn)

Create the census schema if it doesn't exist.

# Arguments
- `conn`: LibPQ connection object
"""
function setup_census_schema(conn)
    # Check if schema exists
    schema_check = DB.execute(conn, "SELECT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'census');")
    schema_df = DataFrame(schema_check)
    schema_exists = parse(Bool, string(schema_df[1, 1]))
    
    if !schema_exists
        @info "Creating census schema..."
        # Create schema
        DB.execute(conn, "CREATE SCHEMA census;")
        
        # Ensure PostGIS extension is enabled
        postgis_check = DB.execute(conn, "SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'postgis');")
        postgis_df = DataFrame(postgis_check)
        postgis_exists = parse(Bool, string(postgis_df[1, 1]))
        
        if !postgis_exists
            @info "Enabling PostGIS extension..."
            DB.execute(conn, "CREATE EXTENSION IF NOT EXISTS postgis;")
        end
        
        @info "Census schema created"
    else
        @info "Census schema already exists"
    end
end

"""
    download_county_shapefile(output_dir="./data", year=2023)

Use the local county shapefile that's already downloaded in the GeoIDs.jl/data directory.

# Arguments
- `output_dir`: Directory where the shapefile is or should be copied to
- `year`: Census year (default: 2023)

# Returns
- Path to the shapefile zip file
"""
function download_county_shapefile(output_dir="./data", year=2023)
    # Create data directory if it doesn't exist
    if !isdir(output_dir)
        mkdir(output_dir)
    end
    
    # Path to the local shapefile in GeoIDs.jl/data directory
    local_path = joinpath(dirname(@__DIR__), "data", "cb_$(year)_us_county_500k.zip")
    
    # Output file path
    output_path = joinpath(output_dir, "cb_$(year)_us_county_500k.zip")
    
    # Check if file already exists at the output location
    if isfile(output_path)
        @info "Shapefile already exists at $output_path"
        return output_path
    end
    
    # Check if the local file exists
    if !isfile(local_path)
        error("Local shapefile not found at $local_path. Please ensure the shapefile is in the GeoIDs.jl/data directory.")
    end
    
    # Copy the file if needed
    if local_path != output_path
        @info "Using local shapefile from $local_path"
        try
            cp(local_path, output_path, force=true)
            @info "Shapefile copied to $output_path"
        catch e
            error("Error copying shapefile: $e")
        end
    end
    
    return output_path
end

"""
    extract_shapefile(zip_path, output_dir="./data")

Extract the shapefile zip to the specified directory.
If the .shp file already exists, it won't extract again.

# Arguments
- `zip_path`: Path to the zip file
- `output_dir`: Directory to extract files to

# Returns
- Path to the extracted shapefile (.shp)
"""
function extract_shapefile(zip_path, output_dir="./data")
    # Check if .shp file already exists (extracted previously)
    year = match(r"cb_(\d{4})_us_county_500k", basename(zip_path)).captures[1]
    shp_path = joinpath(output_dir, "cb_$(year)_us_county_500k.shp")
    
    if isfile(shp_path)
        @info "Shapefile already extracted at $shp_path"
        return shp_path
    end
    
    # Extract the zip file
    @info "Extracting shapefile..."
    
    shapefile_path = ""
    
    try
        reader = ZipFile.Reader(zip_path)
        
        for file in reader.files
            # Extract the file
            filename = basename(file.name)
            output_file = joinpath(output_dir, filename)
            
            open(output_file, "w") do f
                write(f, read(file))
            end
            
            # Keep track of the .shp file
            if endswith(filename, ".shp")
                shapefile_path = output_file
            end
        end
        
        close(reader)
        
        @info "Shapefile extracted to $output_dir"
    catch e
        error("Error extracting shapefile: $e")
    end
    
    if isempty(shapefile_path)
        error("Could not find .shp file in the zip archive")
    end
    
    return shapefile_path
end

"""
    load_counties_to_db(shapefile_path, conn)

Load the county shapefile into the database.

# Arguments
- `shapefile_path`: Path to the shapefile (.shp)
- `conn`: LibPQ connection object
"""
function load_counties_to_db(shapefile_path, conn)
    @info "Loading county shapefile to database..."
    
    # Check if the counties table already exists
    table_check = DB.execute(conn, "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'census' AND table_name = 'counties');")
    table_df = DataFrame(table_check)
    table_exists = parse(Bool, string(table_df[1, 1]))
    
    if table_exists
        @info "Counties table already exists"
        return
    end
    
    # Create the counties table
    DB.execute(conn, """
    CREATE TABLE census.counties (
        geoid VARCHAR(5) PRIMARY KEY,
        statefp VARCHAR(2),
        countyfp VARCHAR(3),
        county_name VARCHAR(100),
        state_name VARCHAR(100),
        geom GEOMETRY(MultiPolygon, 4269)
    );
    """)
    
    # Read the shapefile
    @info "Reading shapefile..."
    dataset = ArchGDAL.read(shapefile_path)
    layer = ArchGDAL.getlayer(dataset, 0)
    
    # Begin transaction
    DB.execute(conn, "BEGIN;")
    
    try
        # Prepare insert statement
        insert_stmt = """
        INSERT INTO census.counties (geoid, statefp, countyfp, county_name, state_name, geom)
        VALUES (\$1, \$2, \$3, \$4, \$5, ST_GeomFromText(\$6, 4269));
        """
        
        # Process each feature
        for feature in layer
            # Get properties
            statefp = ArchGDAL.getfield(feature, "STATEFP")
            countyfp = ArchGDAL.getfield(feature, "COUNTYFP")
            geoid = statefp * countyfp
            county_name = ArchGDAL.getfield(feature, "NAME")
            state_name = ArchGDAL.getfield(feature, "NAMELSAD")
            
            # Get geometry
            geom = ArchGDAL.getgeom(feature)
            wkt = ArchGDAL.toWKT(geom)
            
            # Insert into database
            DB.execute(conn, insert_stmt, [geoid, statefp, countyfp, county_name, state_name, wkt])
        end
        
        # Create spatial index
        DB.execute(conn, "CREATE INDEX counties_geom_idx ON census.counties USING GIST(geom);")
        
        # Commit transaction
        DB.execute(conn, "COMMIT;")
        
        @info "County data loaded to database successfully"
    catch e
        # Rollback on error
        DB.execute(conn, "ROLLBACK;")
        error("Error loading county data to database: $e")
    finally
        # Close dataset
        ArchGDAL.destroy(dataset)
    end
end

"""
    ensure_database_exists()

Check if the configured database exists and create it if it doesn't.
Returns true if the database was created, false if it already existed.
"""
function ensure_database_exists()
    # Get database parameters
    dbname = DB.get_db_name()
    host = get(ENV, "GEOIDS_DB_HOST", "localhost")
    port = get(ENV, "GEOIDS_DB_PORT", "5432")
    user = get(ENV, "GEOIDS_DB_USER", get(ENV, "USER", "postgres"))
    password = get(ENV, "GEOIDS_DB_PASSWORD", "")
    
    # Create connection string to postgres database
    # Use default authentication without username/password
    conn_string = "postgresql://localhost:5432/postgres"
    try
        # Connect to postgres database
        conn = LibPQ.Connection(conn_string)
        
        # Check if our target database exists
        result = LibPQ.execute(conn, """
            SELECT EXISTS(
                SELECT 1 FROM pg_database WHERE datname = '$dbname'
            );
        """)
        
        # Convert the result to a DataFrame
        result_df = DataFrame(result)
        db_exists = parse(Bool, string(result_df[1, 1]))
        
        if !db_exists
            # Create the database
            @info "Database '$dbname' does not exist. Creating it now..."
            LibPQ.execute(conn, "CREATE DATABASE $dbname;")
            close(conn)
            
            # Connect to the new database to create extensions
            db_conn_string = "postgresql://localhost:5432/$dbname"
            db_conn = LibPQ.Connection(db_conn_string)
            
            # Create the census schema
            @info "Creating census schema..."
            LibPQ.execute(db_conn, "CREATE SCHEMA IF NOT EXISTS census;")
            
            # Enable PostGIS extensions
            @info "Creating PostGIS extension..."
            LibPQ.execute(db_conn, "CREATE EXTENSION IF NOT EXISTS postgis;")
            LibPQ.execute(db_conn, "CREATE EXTENSION IF NOT EXISTS postgis_topology;")
            close(db_conn)
            
            @info "Database '$dbname' created with census schema and PostGIS extensions"
            return true
        else
            @info "Database '$dbname' already exists"
            close(conn)
            
            # Connect to the database to ensure schema exists
            db_conn_string = "postgresql://localhost:5432/$dbname"
            db_conn = LibPQ.Connection(db_conn_string)
            
            # Check if census schema exists
            schema_result = LibPQ.execute(db_conn, "SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = 'census');")
            schema_df = DataFrame(schema_result)
            schema_exists = parse(Bool, string(schema_df[1, 1]))
            
            if !schema_exists
                @info "Creating census schema..."
                LibPQ.execute(db_conn, "CREATE SCHEMA IF NOT EXISTS census;")
            end
            
            # Check if PostGIS is enabled
            postgis_result = LibPQ.execute(db_conn, "SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'postgis');")
            postgis_df = DataFrame(postgis_result)
            postgis_exists = parse(Bool, string(postgis_df[1, 1]))
            
            if !postgis_exists
                @info "Enabling PostGIS extension..."
                LibPQ.execute(db_conn, "CREATE EXTENSION IF NOT EXISTS postgis;")
                LibPQ.execute(db_conn, "CREATE EXTENSION IF NOT EXISTS postgis_topology;")
            end
            
            close(db_conn)
            return false
        end
    catch e
        @error "Error checking/creating database: $e"
        
        # Check if the error is about connection failure
        if isa(e, LibPQ.Errors.PQConnectionError)
            @error """
                Failed to connect to PostgreSQL server.
                Please make sure PostgreSQL is installed and running.
                See the PostgreSQL setup guide at https://github.com/technocrat/GeoIDs.jl/blob/main/docs/src/guide/postgresql-setup.md
            """
        end
        
        rethrow(e)
    end
end

"""
    initialize_database()

Main function to set up the database schema, use the local shapefile,
and load county data to the database.
"""
function initialize_database()
    # Ensure the database exists
    ensure_database_exists()
    
    # Connect to database
    DB.with_connection() do conn
        # Set up schema
        setup_census_schema(conn)
        
        # Check if counties table exists and has data
        table_check = DB.execute(conn, """
        SELECT EXISTS(
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'census' AND table_name = 'counties'
        );
        """)
        
        table_df = DataFrame(table_check)
        table_exists = parse(Bool, string(table_df[1, 1]))
        
        if table_exists
            # Check if table has data
            count_check = DB.execute(conn, "SELECT COUNT(*) FROM census.counties;")
            count_df = DataFrame(count_check)
            count = parse(Int, string(count_df[1, 1]))
            
            if count > 0
                @info "Counties table already exists with $count records"
                
                # Make sure GEOID set tables are created even if counties table exists
                DB.setup_tables()
                
                return
            end
        end
        
        # Try to create sample counties table first
        try
            create_sample_counties_table(conn)
            
            # Set up GEOID set tables
            DB.setup_tables()
            
            @info "Sample database initialized successfully"
            return
        catch e
            @warn "Failed to create sample counties table: $e"
            @info "Falling back to using local shapefile..."
        end
        
        # Try to use the local shapefile
        try
            # Use local shapefile
            data_dir = joinpath(dirname(@__DIR__), "data")
            zip_path = download_county_shapefile(data_dir)
            shapefile_path = extract_shapefile(zip_path, data_dir)
            
            # Load data to database
            load_counties_to_db(shapefile_path, conn)
            
            # Set up GEOID set tables
            DB.setup_tables()
        catch e
            @error "Error processing shapefile: $e"
            error("Database initialization failed. Please check the error messages above.")
        end
    end
    
    @info "Database initialization complete"
end

"""
    create_sample_counties_table(conn)

Create a sample counties table with some example counties for testing purposes.
This is used when downloading the actual Census data fails or isn't required.
"""
function create_sample_counties_table(conn)
    @info "Creating sample counties table for testing..."
    
    # Check if the counties table already exists
    table_check = DB.execute(conn, "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'census' AND table_name = 'counties');")
    table_df = DataFrame(table_check)
    table_exists = parse(Bool, string(table_df[1, 1]))
    
    if table_exists
        # Check if table has data
        count_check = DB.execute(conn, "SELECT COUNT(*) FROM census.counties;")
        count_df = DataFrame(count_check)
        count = parse(Int, string(count_df[1, 1]))
        
        if count > 0
            @info "Counties table already exists with $count records"
            return
        end
    end
    
    # Create counties table with PostGIS geometry column
    DB.execute(conn, """
    CREATE TABLE IF NOT EXISTS census.counties (
        geoid VARCHAR(5) PRIMARY KEY,
        name VARCHAR(100),
        stusps VARCHAR(2),
        geom geometry(MultiPolygon, 4269)
    );
    """)
    
    # Sample county data for testing - using simplified geometries
    # This includes a few counties from different states
    DB.execute(conn, """
    INSERT INTO census.counties (geoid, name, stusps, geom) VALUES
    ('12086', 'Miami-Dade', 'FL', ST_GeomFromText('MULTIPOLYGON(((-80.5 25.2, -80.2 25.2, -80.2 25.8, -80.5 25.8, -80.5 25.2)))', 4269)),
    ('12011', 'Broward', 'FL', ST_GeomFromText('MULTIPOLYGON(((-80.5 25.8, -80.2 25.8, -80.2 26.3, -80.5 26.3, -80.5 25.8)))', 4269)),
    ('12099', 'Palm Beach', 'FL', ST_GeomFromText('MULTIPOLYGON(((-80.5 26.3, -80.2 26.3, -80.2 26.9, -80.5 26.9, -80.5 26.3)))', 4269)),
    ('12021', 'Collier', 'FL', ST_GeomFromText('MULTIPOLYGON(((-81.6 25.8, -81.2 25.8, -81.2 26.5, -81.6 26.5, -81.6 25.8)))', 4269)),
    ('06037', 'Los Angeles', 'CA', ST_GeomFromText('MULTIPOLYGON(((-118.6 33.7, -117.8 33.7, -117.8 34.8, -118.6 34.8, -118.6 33.7)))', 4269)),
    ('36061', 'New York', 'NY', ST_GeomFromText('MULTIPOLYGON(((-74.1 40.6, -73.9 40.6, -73.9 40.9, -74.1 40.9, -74.1 40.6)))', 4269)),
    ('17031', 'Cook', 'IL', ST_GeomFromText('MULTIPOLYGON(((-88.2 41.6, -87.5 41.6, -87.5 42.1, -88.2 42.1, -88.2 41.6)))', 4269)),
    ('48201', 'Harris', 'TX', ST_GeomFromText('MULTIPOLYGON(((-95.8 29.5, -95.0 29.5, -95.0 30.1, -95.8 30.1, -95.8 29.5)))', 4269)),
    ('13121', 'Fulton', 'GA', ST_GeomFromText('MULTIPOLYGON(((-84.6 33.6, -84.2 33.6, -84.2 34.0, -84.6 34.0, -84.6 33.6)))', 4269)),
    ('53033', 'King', 'WA', ST_GeomFromText('MULTIPOLYGON(((-122.5 47.3, -121.8 47.3, -121.8 47.8, -122.5 47.8, -122.5 47.3)))', 4269))
    ON CONFLICT (geoid) DO NOTHING;
    """)
    
    # Create spatial index on geometry column
    DB.execute(conn, "CREATE INDEX IF NOT EXISTS counties_geom_idx ON census.counties USING GIST (geom);")
    
    # Verify county count
    count_check = DB.execute(conn, "SELECT COUNT(*) FROM census.counties;")
    count_df = DataFrame(count_check)
    count = parse(Int, string(count_df[1, 1]))
    
    @info "Sample counties table created with $count records"
end

end # module Setup 