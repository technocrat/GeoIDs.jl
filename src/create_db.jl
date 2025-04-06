#!/usr/bin/env julia

using LibPQ
using DataFrames

function create_tiger_database()
    println("Checking if 'tiger' database exists...")
    
    # Database connection parameters
    dbname = "postgres"  # Connect to postgres database first
    host = "localhost"
    port = "5432"
    user = get(ENV, "USER", "postgres")
    password = get(ENV, "GEOIDS_DB_PASSWORD", "")
    
    # Create connection string to postgres database
    conn_string = "postgresql://$user:$password@$host:$port/$dbname"
    
    try
        # Connect to postgres database
        conn = LibPQ.Connection(conn_string)
        println("Connected to PostgreSQL!")
        
        # Check if our target database exists
        result = LibPQ.execute(conn, """
            SELECT EXISTS(
                SELECT 1 FROM pg_database WHERE datname = 'tiger'
            );
        """)
        
        # Convert the result to a DataFrame
        resultdf = DataFrame(result)
        db_exists = parse(Bool, string(resultdf[1, 1]))
        
        if !db_exists
            # Create the database
            println("Database 'tiger' does not exist. Creating it now...")
            LibPQ.execute(conn, "CREATE DATABASE tiger;")
            close(conn)
            
            # Connect to the new database to create extensions
            tiger_conn_string = "postgresql://$user:$password@$host:$port/tiger"
            tiger_conn = LibPQ.Connection(tiger_conn_string)
            println("Connected to 'tiger' database")
            
            # Create the postgis extension
            println("Creating PostGIS extension...")
            LibPQ.execute(tiger_conn, "CREATE EXTENSION IF NOT EXISTS postgis;")
            LibPQ.execute(tiger_conn, "CREATE EXTENSION IF NOT EXISTS postgis_topology;")
            close(tiger_conn)
            
            println("Database 'tiger' created with PostGIS extensions")
            return true
        else
            println("Database 'tiger' already exists")
            close(conn)
            return false
        end
    catch e
        println("Error: $e")
        
        if isa(e, LibPQ.Errors.PQConnectionError)
            println("Failed to connect to PostgreSQL server.")
            println("Please make sure PostgreSQL is installed and running.")
        end
        
        return false
    end
end

# Execute the function
create_tiger_database() 