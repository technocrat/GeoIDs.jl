# SPDX-License-Identifier: MIT

module DB

using LibPQ
using DataFrames

# Get database parameters from environment variables with fallbacks
"""
    get_db_params() -> Dict{String, String}

Get database connection parameters from environment variables with fallbacks:
- GEOIDS_DB_NAME: Database name (defaults to "tiger")
- GEOIDS_DB_HOST: Database host (defaults to "localhost")
- GEOIDS_DB_PORT: Database port (defaults to "5432")
"""
function get_db_params()
    return Dict(
        "dbname" => get(ENV, "GEOIDS_DB_NAME", "tiger"),
        "host" => get(ENV, "GEOIDS_DB_HOST", "localhost"),
        "port" => get(ENV, "GEOIDS_DB_PORT", "5432")
    )
end

"""
    get_db_name() -> String

Get the database name from the GEOIDS_DB_NAME environment variable,
falling back to "tiger" if not set.
"""
function get_db_name()
    return get(ENV, "GEOIDS_DB_NAME", "tiger")
end

"""
    build_connection_string(params::Dict{String, String}) -> String

Build a connection string from database parameters.
Uses libpq format: postgresql://host:port/dbname
"""
function build_connection_string(params::Dict{String, String})
    host = get(params, "host", "localhost")
    port = get(params, "port", "5432")
    dbname = get(params, "dbname", "tiger")
    
    # Build connection string without user/password for default auth
    return "postgresql://$host:$port/$dbname"
end

# Database connection functions
"""
    get_connection() -> Union{LibPQ.Connection, Nothing}

Returns a connection to the database specified by environment variables.
By default connects to "tiger" database on localhost:5432.
Uses the default socket authentication method.

Environment variables:
- GEOIDS_DB_NAME: Database name (defaults to "tiger")
- GEOIDS_DB_HOST: Database host (defaults to "localhost")
- GEOIDS_DB_PORT: Database port (defaults to "5432")

Returns a LibPQ.Connection object or throws an informative error.
"""
function get_connection()
    db_params = get_db_params()
    connection_string = build_connection_string(db_params)
    
    try
        return LibPQ.Connection(connection_string)
    catch e
        # Extract the most relevant information for the user
        db_name = get(db_params, "dbname", "unknown")
        db_host = get(db_params, "host", "unknown")
        db_port = get(db_params, "port", "unknown")
        
        error_msg = if isa(e, LibPQ.Errors.ConnectionRefused)
            "Database connection refused. Please ensure that PostgreSQL is running on $db_host:$db_port"
        elseif isa(e, LibPQ.Errors.InvalidPassword)
            "Authentication failed. Please check your database credentials"
        elseif isa(e, LibPQ.Errors.UnknownDatabase)
            "Database '$db_name' does not exist. Please create it or specify a different database"
        else
            "Database connection error: $(typeof(e)): $(e.msg)"
        end
        
        @error error_msg
        throw(ErrorException(error_msg))
    end
end

"""
    with_connection(f::Function) -> Any

Execute function f with a database connection, ensuring the connection is closed after use.
Provides graceful error handling for database operations.

# Arguments
- `f::Function`: Function that takes a connection as its argument and performs database operations

# Returns
- Returns the result of the function f

# Example
```julia
with_connection() do conn
    execute(conn, "SELECT * FROM my_table")
end
```
"""
function with_connection(f::Function)
    conn = nothing
    try
        conn = get_connection()
        return f(conn)
    catch e
        # Handle specific database operation errors
        if isa(e, LibPQ.Errors.QueryError)
            @error "Database query error: $(e.msg)"
        elseif isa(e, LibPQ.Errors.ConnectionError)
            @error "Database connection was lost during operation"
        end
        rethrow(e)
    finally
        if conn !== nothing
            try
                close(conn)
            catch close_error
                @warn "Error while closing database connection: $close_error"
            end
        end
    end
end

"""
    execute(conn::LibPQ.Connection, query::String, params::Vector=[]) -> LibPQ.Result

Execute a SQL query with parameters and return the result.
"""
function execute(conn::LibPQ.Connection, query::String, params::Vector=[])
    return LibPQ.execute(conn, query, params)
end

"""
    execute_query(query::String, params::Vector=[]) -> DataFrame

Execute a query with parameters and return the result as a DataFrame.
Ensures proper type handling and provides informative error messages.

# Arguments
- `query::String`: SQL query to execute
- `params::Vector`: Parameters to substitute into the query (optional)

# Returns
- `DataFrame`: Results of the query as a DataFrame
- Empty DataFrame with appropriate column names on empty result

# Throws
- `ErrorException`: If the query fails to execute with an informative message
"""
function execute_query(query::String, params::Vector=[])
    try
        with_connection() do conn
            result = execute(conn, query, params)
            if LibPQ.num_rows(result) == 0
                # Return empty DataFrame but with correct column structure
                col_names = [Symbol(name) for name in result.column_names]
                return DataFrame([[] for _ in col_names], col_names)
            end
            return DataFrame(result)
        end
    catch e
        # Provide more specific error messages
        if isa(e, ErrorException)
            # Just rethrow if we've already formatted the error nicely
            rethrow(e)
        else
            error_msg = "Query execution failed: $(typeof(e)): $(string(e))"
            @error error_msg
            throw(ErrorException(error_msg))
        end
    end
end

"""
    setup_tables()

Create the necessary database tables for storing GEOID sets with versioning.
"""
function setup_tables()
    with_connection() do conn
        # First ensure the census schema exists
        schema_check = execute(conn, "SELECT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'census');")
        schema_df = DataFrame(schema_check)
        schema_exists = parse(Bool, string(schema_df[1, 1]))
        
        if !schema_exists
            @info "Creating census schema..."
            # Create schema
            execute(conn, "CREATE SCHEMA census;")
            
            # Ensure PostGIS extension is enabled
            postgis_check = execute(conn, "SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'postgis');")
            postgis_df = DataFrame(postgis_check)
            postgis_exists = parse(Bool, string(postgis_df[1, 1]))
            
            if !postgis_exists
                @info "Enabling PostGIS extension..."
                execute(conn, "CREATE EXTENSION IF NOT EXISTS postgis;")
                execute(conn, "CREATE EXTENSION IF NOT EXISTS postgis_topology;")
            end
        end
        
        # Check if counties table exists
        counties_check = execute(conn, "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'census' AND table_name = 'counties');")
        counties_df = DataFrame(counties_check)
        counties_exist = parse(Bool, string(counties_df[1, 1]))
        
        # Create tables within a transaction
        execute(conn, "BEGIN;")
        
        try
            # Main table for GEOID set metadata
            execute(conn, """
            CREATE TABLE IF NOT EXISTS census.geoid_sets (
                set_name VARCHAR(100),
                version INT NOT NULL DEFAULT 1,
                description TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                is_current BOOLEAN DEFAULT TRUE,
                parent_version INT,
                change_description TEXT,
                PRIMARY KEY (set_name, version)
            );
            """)
            
            # Table for GEOID set members - adapt based on whether counties table exists
            if counties_exist
                # With reference to counties table
                execute(conn, """
                CREATE TABLE IF NOT EXISTS census.geoid_set_members (
                    set_name VARCHAR(100),
                    version INT NOT NULL DEFAULT 1,
                    geoid VARCHAR(5) REFERENCES census.counties(geoid),
                    PRIMARY KEY (set_name, version, geoid),
                    FOREIGN KEY (set_name, version) REFERENCES census.geoid_sets(set_name, version) ON DELETE CASCADE
                );
                """)
            else
                # Without reference to counties table, to be added later
                @info "Creating geoid_set_members table without foreign key reference to counties table"
                execute(conn, """
                CREATE TABLE IF NOT EXISTS census.geoid_set_members (
                    set_name VARCHAR(100),
                    version INT NOT NULL DEFAULT 1,
                    geoid VARCHAR(5),
                    PRIMARY KEY (set_name, version, geoid),
                    FOREIGN KEY (set_name, version) REFERENCES census.geoid_sets(set_name, version) ON DELETE CASCADE
                );
                """)
            end
            
            # Table for tracking changes between versions
            execute(conn, """
            CREATE TABLE IF NOT EXISTS census.geoid_set_changes (
                set_name VARCHAR(100),
                version INT NOT NULL,
                change_type VARCHAR(10) NOT NULL,
                geoid VARCHAR(5) NOT NULL,
                changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (set_name, version, geoid),
                FOREIGN KEY (set_name, version) REFERENCES census.geoid_sets(set_name, version) ON DELETE CASCADE
            );
            """)
            
            execute(conn, "COMMIT;")
            @info "GeoIDs database tables created successfully in database: $(get_db_name())"
        catch e
            execute(conn, "ROLLBACK;")
            @error "Error creating GeoIDs database tables: $e"
            rethrow(e)
        end
    end
end

"""
    get_connection_string()

Build a PostgreSQL connection string from environment variables or defaults.
Uses default socket authentication when no username/password provided.

# Environment Variables
- `GEOIDS_DB_NAME`: Database name (default: "tiger")
- `GEOIDS_DB_HOST`: Database host (default: "localhost")
- `GEOIDS_DB_PORT`: Database port (default: 5432)
"""
function get_connection_string()
    dbname = get(ENV, "GEOIDS_DB_NAME", "tiger")
    host = get(ENV, "GEOIDS_DB_HOST", "localhost")
    port = get(ENV, "GEOIDS_DB_PORT", "5432")
    
    # Build connection string without user/password for default auth
    conn_string = "postgresql://$host:$port/$dbname"
    
    return conn_string
end

export get_connection, with_connection, execute, execute_query, setup_tables, get_db_name, get_db_params

end # module DB 