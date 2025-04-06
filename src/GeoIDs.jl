# SPDX-License-Identifier: MIT

module GeoIDs

using DataFrames
using LibPQ
using ArchGDAL
using JSON3
using Dates
using HTTP
using ZipFile

# Include sub-modules
include("db.jl")
include("store.jl")
include("fetch.jl")
include("operations.jl")
include("setup.jl")
include("predefined_sets.jl") # Include the new predefined sets module

# Import and re-export from sub-modules
using .DB
using .Store
using .Fetch
using .Operations
using .Setup
using .PredefinedSets

# Constants for holding pre-defined GEOID sets that will be loaded from the database
const EASTERN_US_GEOIDS = String[]
const WESTERN_US_GEOIDS = String[]
const SOUTH_FLORIDA_GEOIDS = String[] 
const MIDWEST_GEOIDS = String[]
const MOUNTAIN_WEST_GEOIDS = String[]
const GREAT_PLAINS_GEOIDS = String[]

"""
    initialize_predefined_geoid_sets()

Initialize all predefined GEOID sets in the database.
This is called during the first module load to ensure all
standard GEOID sets are available in the versioned database.
"""
function initialize_predefined_geoid_sets()
    # Check if tables exist, create them if not
    DB.setup_tables()
    
    # Get all available GEOID sets from the database
    try
        result = list_geoid_sets()
        existing_sets = result.set_name
        
        # Initialize each predefined set if it doesn't exist
        for (set_name, (geoids, description)) in PredefinedSets.PREDEFINED_SETS
            if set_name ∉ existing_sets
                if !isempty(geoids)
                    create_geoid_set(set_name, description, geoids)
                    @info "Initialized predefined GEOID set: $set_name with $(length(geoids)) counties"
                end
            end
        end
    catch e
        @warn "Could not initialize predefined GEOID sets: $e"
    end
end

"""
    load_predefined_geoids()

Load all predefined GEOID sets from the database into module constants.
"""
function load_predefined_geoids()
    # Use individual try/catch blocks for each set to ensure one failure doesn't affect others
    
    # Eastern US GEOIDs
    try
        empty!(EASTERN_US_GEOIDS)
        append!(EASTERN_US_GEOIDS, get_geoid_set("eastern_us"))
    catch e
        @info "Could not load 'eastern_us' set: $(typeof(e))"
    end
    
    # Western US GEOIDs
    try
        empty!(WESTERN_US_GEOIDS)
        append!(WESTERN_US_GEOIDS, get_geoid_set("western_us"))
    catch e
        @info "Could not load 'western_us' set: $(typeof(e))"
    end
    
    # South Florida GEOIDs
    try
        empty!(SOUTH_FLORIDA_GEOIDS)
        append!(SOUTH_FLORIDA_GEOIDS, get_geoid_set("south_florida"))
    catch e
        @info "Could not load 'south_florida' set: $(typeof(e))"
    end
    
    # Midwest GEOIDs
    try
        empty!(MIDWEST_GEOIDS)
        append!(MIDWEST_GEOIDS, get_geoid_set("midwest"))
    catch e
        @info "Could not load 'midwest' set: $(typeof(e))"
    end
    
    # Mountain West GEOIDs
    try
        empty!(MOUNTAIN_WEST_GEOIDS)
        append!(MOUNTAIN_WEST_GEOIDS, get_geoid_set("mountain_west"))
    catch e
        @info "Could not load 'mountain_west' set: $(typeof(e))"
    end
    
    # Great Plains GEOIDs
    try
        empty!(GREAT_PLAINS_GEOIDS)
        append!(GREAT_PLAINS_GEOIDS, get_geoid_set("great_plains"))
    catch e
        @info "Could not load 'great_plains' set: $(typeof(e))"
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
                    if convert(Int, check_result[1, 1]) > 0
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
        # Ensure database exists and is properly initialized with data
        initialize_database()
        
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
       EASTERN_US_GEOIDS,
       WESTERN_US_GEOIDS,
       SOUTH_FLORIDA_GEOIDS,
       MIDWEST_GEOIDS,
       MOUNTAIN_WEST_GEOIDS,
       GREAT_PLAINS_GEOIDS,
       # Export Setup module functions
       setup_census_schema,
       download_county_shapefile,
       load_counties_to_db,
       initialize_database,
       # Re-export predefined sets constants
       EASTERN_US_COUNTIES,
       WESTERN_US_COUNTIES,
       SOUTH_FLORIDA_COUNTIES,
       MIDWEST_COUNTIES,
       MOUNTAIN_WEST_COUNTIES,
       GREAT_PLAINS_COUNTIES

end # module GeoIDs 