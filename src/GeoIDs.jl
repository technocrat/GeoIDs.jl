# SPDX-License-Identifier: MIT

module GeoIDs

using DataFrames
using LibPQ
using ArchGDAL
using JSON3
using Dates

# Include sub-modules
include("db.jl")
include("store.jl")
include("fetch.jl")
include("operations.jl")

# Import and re-export from sub-modules
using .DB
using .Store
using .Fetch
using .Operations

# Constants for holding pre-defined GEOID sets that will be loaded from the database
const WESTERN_GEOIDS = String[]
const EASTERN_GEOIDS = String[]
const FLORIDA_SOUTH_GEOIDS = String[] 
const COLORADO_BASIN_GEOIDS = String[]

"""
    initialize_predefined_geoid_sets()

Initialize all predefined GEOID sets in the database.
This is called during the first module load to ensure all
standard GEOID sets are available in the versioned database.
"""
function initialize_predefined_geoid_sets()
    # Check if tables exist, create them if not
    DB.setup_tables()
    
    # Get list of all predefined sets with their generation functions
    predefined_sets = [
        ("western_geoids", "Counties west of 100°W longitude requiring irrigation", get_western_geoids),
        ("eastern_geoids", "Counties between 90°W and 100°W with historically high rainfall", get_eastern_geoids),
        ("florida_south_geoids", "Florida counties south of 29°N latitude", get_florida_south_geoids),
        # Add more predefined sets here
    ]
    
    for (set_name, description, generator_func) in predefined_sets
        # Check if this set already exists in the database
        try
            result = list_geoid_sets()
            if set_name ∉ result.set_name
                # Set doesn't exist yet, initialize it
                geoids = generator_func()
                if !isempty(geoids)
                    create_geoid_set(set_name, description, geoids)
                    @info "Initialized predefined GEOID set: $set_name with $(length(geoids)) counties"
                end
            end
        catch e
            if isa(e, SQLState)
                # Tables might not exist yet, that's okay
                @warn "Could not check for existing GEOID sets: $e"
            else
                @warn "Error initializing predefined GEOID set $set_name: $e"
            end
        end
    end
end

"""
    load_predefined_geoids()

Load all predefined GEOID sets from the database into module constants.
"""
function load_predefined_geoids()
    try
        # Load predefined GEOID sets into constants
        empty!(WESTERN_GEOIDS)
        append!(WESTERN_GEOIDS, get_geoid_set("western_geoids"))
        
        empty!(EASTERN_GEOIDS)
        append!(EASTERN_GEOIDS, get_geoid_set("eastern_geoids"))
        
        empty!(FLORIDA_SOUTH_GEOIDS)
        append!(FLORIDA_SOUTH_GEOIDS, get_geoid_set("florida_south_geoids"))
        
        # Add more predefined sets here
    catch e
        @warn "Error loading predefined GEOID sets: $e"
    end
end

"""
    backup_geoid_sets(output_file::String)

Create a complete backup of all GEOID sets and their versions.

# Arguments
- `output_file::String`: Path to save the backup file (JSON format)

# Example
```julia
backup_geoid_sets("geoid_sets_backup_2023-10-15.json")
```
"""
function backup_geoid_sets(output_file::String)
    # Get all set metadata
    sets_query = """
    SELECT set_name, version, description, created_at, updated_at, 
           is_current, parent_version, change_description
    FROM census.geoid_sets
    ORDER BY set_name, version;
    """
    
    sets = DB.execute_query(sets_query)
    
    # Get all members
    members_query = """
    SELECT set_name, version, geoid
    FROM census.geoid_set_members
    ORDER BY set_name, version, geoid;
    """
    
    members = DB.execute_query(members_query)
    
    # Get all changes
    changes_query = """
    SELECT set_name, version, change_type, geoid, changed_at
    FROM census.geoid_set_changes
    ORDER BY set_name, version, geoid;
    """
    
    changes = DB.execute_query(changes_query)
    
    # Create backup structure
    backup = Dict(
        "metadata" => Dict(
            "created_at" => string(now()),
            "version" => "1.0"
        ),
        "sets" => [Dict(pairs(row)) for row in eachrow(sets)],
        "members" => [Dict(pairs(row)) for row in eachrow(members)],
        "changes" => [Dict(pairs(row)) for row in eachrow(changes)]
    )
    
    # Convert timestamps to strings for JSON serialization
    for set in backup["sets"]
        set["created_at"] = string(set["created_at"])
        set["updated_at"] = string(set["updated_at"])
    end
    
    for change in backup["changes"]
        change["changed_at"] = string(change["changed_at"])
    end
    
    # Write to file
    open(output_file, "w") do io
        write(io, JSON3.write(backup))
    end
    
    return output_file
end

"""
    restore_geoid_sets(input_file::String, overwrite::Bool=false)

Restore GEOID sets from a backup file.

# Arguments
- `input_file::String`: Path to the backup file
- `overwrite::Bool`: Whether to overwrite existing sets

# Example
```julia
restore_geoid_sets("geoid_sets_backup_2023-10-15.json")
```
"""
function restore_geoid_sets(input_file::String, overwrite::Bool=false)
    # Read backup file
    backup = open(input_file, "r") do io
        JSON3.read(read(io, String))
    end
    
    # Start transaction
    DB.with_connection() do conn
        DB.execute(conn, "BEGIN;")
        
        try
            if overwrite
                # Clear existing sets first
                DB.execute(conn, "DELETE FROM census.geoid_set_changes;")
                DB.execute(conn, "DELETE FROM census.geoid_set_members;")
                DB.execute(conn, "DELETE FROM census.geoid_sets;")
            end
            
            # Restore sets
            for set in backup["sets"]
                # Check if set exists
                if !overwrite
                    check_query = """
                    SELECT COUNT(*) FROM census.geoid_sets 
                    WHERE set_name = \$1 AND version = \$2;
                    """
                    
                    check_result = DB.execute(conn, check_query, [set["set_name"], set["version"]])
                    if parse(Int, LibPQ.getvalue(check_result, 1, 1)) > 0
                        continue  # Skip existing
                    end
                end
                
                # Insert set
                DB.execute(
                    conn,
                    """
                    INSERT INTO census.geoid_sets 
                    (set_name, version, description, created_at, updated_at, 
                     is_current, parent_version, change_description)
                    VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8);
                    """,
                    [
                        set["set_name"], set["version"], set["description"], 
                        set["created_at"], set["updated_at"], set["is_current"],
                        set["parent_version"], set["change_description"]
                    ]
                )
            end
            
            # Restore members
            for member in backup["members"]
                DB.execute(
                    conn,
                    """
                    INSERT INTO census.geoid_set_members
                    (set_name, version, geoid)
                    VALUES (\$1, \$2, \$3)
                    ON CONFLICT DO NOTHING;
                    """,
                    [member["set_name"], member["version"], member["geoid"]]
                )
            end
            
            # Restore changes
            for change in backup["changes"]
                DB.execute(
                    conn,
                    """
                    INSERT INTO census.geoid_set_changes
                    (set_name, version, change_type, geoid, changed_at)
                    VALUES (\$1, \$2, \$3, \$4, \$5)
                    ON CONFLICT DO NOTHING;
                    """,
                    [
                        change["set_name"], change["version"], 
                        change["change_type"], change["geoid"], change["changed_at"]
                    ]
                )
            end
            
            DB.execute(conn, "COMMIT;")
        catch e
            DB.execute(conn, "ROLLBACK;")
            rethrow(e)
        end
    end
    
    # Reload constants after restore
    load_predefined_geoids()
    
    return "Successfully restored GEOID sets from $input_file"
end

# Initialize the module
function __init__()
    # Setup database tables if they don't exist
    try
        # Initialize predefined GEOID sets in the database
        initialize_predefined_geoid_sets()
        
        # Load constants from the database
        load_predefined_geoids()
    catch e
        @warn "Error during GeoIDs initialization: $e"
    end
end

# Export functions from main module
export backup_geoid_sets,
       restore_geoid_sets,
       WESTERN_GEOIDS,
       EASTERN_GEOIDS,
       FLORIDA_SOUTH_GEOIDS,
       COLORADO_BASIN_GEOIDS

end # module GeoIDs 