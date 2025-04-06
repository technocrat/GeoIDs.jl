# SPDX-License-Identifier: MIT

module DB

using LibPQ
using DataFrames

# Get database parameters from environment variables with fallbacks
"""
    get_db_params() -> Dict{String, String}

Get database connection parameters from environment variables with fallbacks:
- GEOIDS_DB_NAME: Database name (defaults to "geocoder")
- GEOIDS_DB_HOST: Database host (defaults to "localhost")
- GEOIDS_DB_PORT: Database port (defaults to "5432")
- GEOIDS_DB_USER: Database user (defaults to current system user)
- GEOIDS_DB_PASSWORD: Database password (defaults to empty string)
"""
function get_db_params()
    return Dict(
        "dbname" => get(ENV, "GEOIDS_DB_NAME", "geocoder"),
        "host" => get(ENV, "GEOIDS_DB_HOST", "localhost"),
        "port" => get(ENV, "GEOIDS_DB_PORT", "5432"),
        "user" => get(ENV, "GEOIDS_DB_USER", get(ENV, "USER", "")),
        # Only include password if provided
        filter(pair -> first(pair) != "password" || !isempty(last(pair)), 
            Dict("password" => get(ENV, "GEOIDS_DB_PASSWORD", "")))...
    )
end

"""
    get_db_name() -> String

Get the database name from the GEOIDS_DB_NAME environment variable,
falling back to "geocoder" if not set.
"""
function get_db_name()
    return get(ENV, "GEOIDS_DB_NAME", "geocoder")
end

"""
    build_connection_string(params::Dict{String, String}) -> String

Build a connection string from database parameters.
"""
function build_connection_string(params::Dict{String, String})
    return join(["$key=$value" for (key, value) in params], " ")
end

# Database connection functions
"""
    get_connection() -> LibPQ.Connection

Returns a connection to the database specified by environment variables.
By default connects to "geocoder" database on localhost:5432.

Environment variables:
- GEOIDS_DB_NAME: Database name (defaults to "geocoder")
- GEOIDS_DB_HOST: Database host (defaults to "localhost")
- GEOIDS_DB_PORT: Database port (defaults to "5432")
- GEOIDS_DB_USER: Database user (defaults to current system user)
- GEOIDS_DB_PASSWORD: Database password (defaults to empty string)
"""
function get_connection()
    db_params = get_db_params()
    connection_string = build_connection_string(db_params)
    return LibPQ.Connection(connection_string)
end

"""
    with_connection(f::Function)

Execute function f with a database connection, ensuring the connection is closed after use.
"""
function with_connection(f::Function)
    conn = get_connection()
    try
        return f(conn)
    finally
        close(conn)
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
"""
function execute_query(query::String, params::Vector=[])
    with_connection() do conn
        result = execute(conn, query, params)
        return DataFrame(result)
    end
end

"""
    setup_tables()

Create the necessary database tables for storing GEOID sets with versioning.
"""
function setup_tables()
    with_connection() do conn
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
            
            # Table for GEOID set members
            execute(conn, """
            CREATE TABLE IF NOT EXISTS census.geoid_set_members (
                set_name VARCHAR(100),
                version INT NOT NULL DEFAULT 1,
                geoid VARCHAR(5) REFERENCES census.counties(geoid),
                PRIMARY KEY (set_name, version, geoid),
                FOREIGN KEY (set_name, version) REFERENCES census.geoid_sets(set_name, version) ON DELETE CASCADE
            );
            """)
            
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

export get_connection, with_connection, execute, execute_query, setup_tables, get_db_name, get_db_params

end # module DB 