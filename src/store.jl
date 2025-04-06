# SPDX-License-Identifier: MIT

module Store

using DataFrames
using LibPQ
using Dates
using ..DB: with_connection, execute, execute_query

"""
    create_geoid_set(set_name::String, description::String="", geoids::Vector{String}=String[])

Create a new GEOID set with optional initial members.
"""
function create_geoid_set(set_name::String, description::String="", geoids::Vector{String}=String[])
    create_geoid_set_version(set_name, geoids, "Initial definition", 0, description)
    return nothing
end

"""
    create_geoid_set_version(set_name::String, geoids::Vector{String}, 
                            change_description::String="", base_version::Int=0,
                            description::String="") -> Int

Create a new version of an existing GEOID set or create a new set (version 1) if it doesn't exist.

# Arguments
- `set_name::String`: Name of the set
- `geoids::Vector{String}`: GEOIDs for the new version
- `change_description::String`: Description of what changed in this version
- `base_version::Int`: Base version to create from (0 means latest version or new set)
- `description::String`: Description for the set (only used for new sets)

# Returns
- `Int`: The new version number
"""
function create_geoid_set_version(set_name::String, geoids::Vector{String}, 
                                 change_description::String="", base_version::Int=0,
                                 description::String="")
    # Start transaction
    with_connection() do conn
        execute(conn, "BEGIN;")
        
        try
            # Get current version information
            current_version_query = """
            SELECT version, description FROM census.geoid_sets
            WHERE set_name = \$1 AND is_current = TRUE;
            """
            
            current_version_result = execute(conn, current_version_query, [set_name])
            
            if LibPQ.num_rows(current_version_result) == 0
                # Set doesn't exist yet, create version 1
                new_version = 1
                set_description = description
                
                # Insert initial set metadata
                execute(
                    conn,
                    """
                    INSERT INTO census.geoid_sets 
                    (set_name, version, description, is_current)
                    VALUES (\$1, \$2, \$3, TRUE);
                    """,
                    [set_name, new_version, set_description]
                )
                
                # No changes to track for first version
                
            else
                # Get details of existing version
                existing_version = convert(Int, current_version_result[1, 1])
                existing_description = current_version_result[1, 2]
                
                # Determine base version
                base_ver = base_version > 0 ? base_version : existing_version
                
                # Mark current version as not current
                execute(
                    conn,
                    """
                    UPDATE census.geoid_sets 
                    SET is_current = FALSE
                    WHERE set_name = \$1 AND is_current = TRUE;
                    """,
                    [set_name]
                )
                
                # Get existing GEOIDs for the base version
                existing_geoids_query = """
                SELECT geoid FROM census.geoid_set_members
                WHERE set_name = \$1 AND version = \$2;
                """
                
                existing_geoids_result = execute(conn, existing_geoids_query, [set_name, base_ver])
                existing_geoids = [existing_geoids_result[i, 1] 
                                  for i in 1:LibPQ.num_rows(existing_geoids_result)]
                
                # Calculate new version and changes
                new_version = existing_version + 1
                
                # Track changes
                added_geoids = setdiff(geoids, existing_geoids)
                removed_geoids = setdiff(existing_geoids, geoids)
                
                # Insert change records
                for geoid in added_geoids
                    execute(
                        conn,
                        """
                        INSERT INTO census.geoid_set_changes
                        (set_name, version, change_type, geoid)
                        VALUES (\$1, \$2, 'ADD', \$3);
                        """,
                        [set_name, new_version, geoid]
                    )
                end
                
                for geoid in removed_geoids
                    execute(
                        conn,
                        """
                        INSERT INTO census.geoid_set_changes
                        (set_name, version, change_type, geoid)
                        VALUES (\$1, \$2, 'REMOVE', \$3);
                        """,
                        [set_name, new_version, geoid]
                    )
                end
                
                # Create new version
                execute(
                    conn,
                    """
                    INSERT INTO census.geoid_sets 
                    (set_name, version, description, is_current, parent_version, change_description)
                    VALUES (\$1, \$2, \$3, TRUE, \$4, \$5);
                    """,
                    [set_name, new_version, existing_description, base_ver, change_description]
                )
            end
            
            # Insert GEOIDs for the new version
            for geoid in geoids
                execute(
                    conn,
                    """
                    INSERT INTO census.geoid_set_members
                    (set_name, version, geoid)
                    VALUES (\$1, \$2, \$3);
                    """,
                    [set_name, new_version, geoid]
                )
            end
            
            execute(conn, "COMMIT;")
            return new_version
            
        catch e
            execute(conn, "ROLLBACK;")
            rethrow(e)
        end
    end
end

"""
    get_geoid_set_version(set_name::String, version::Int=0) -> Vector{String}

Get GEOIDs for a specific version of a set. Use version=0 for current version.

# Arguments
- `set_name::String`: Name of the set
- `version::Int`: Version to retrieve (0 means current version)

# Returns
- `Vector{String}`: GEOIDs in the specified version
"""
function get_geoid_set_version(set_name::String, version::Int=0)
    with_connection() do conn
        # Determine version to retrieve
        ver_query = if version == 0
            """
            SELECT version FROM census.geoid_sets
            WHERE set_name = \$1 AND is_current = TRUE;
            """
        else
            """
            SELECT version FROM census.geoid_sets
            WHERE set_name = \$1 AND version = \$2;
            """
        end
        
        ver_params = version == 0 ? [set_name] : [set_name, version]
        ver_result = execute(conn, ver_query, ver_params)
        
        if LibPQ.num_rows(ver_result) == 0
            if version == 0
                error("GEOID set '$set_name' not found")
            else
                error("Version $version of GEOID set '$set_name' not found")
            end
        end
        
        actual_version = convert(Int, ver_result[1, 1])
        
        # Get GEOIDs for this version
        geoids_query = """
        SELECT geoid FROM census.geoid_set_members
        WHERE set_name = \$1 AND version = \$2
        ORDER BY geoid;
        """
        
        geoids_result = execute(conn, geoids_query, [set_name, actual_version])
        
        geoids = [geoids_result[i, 1] 
                 for i in 1:LibPQ.num_rows(geoids_result)]
        
        return geoids
    end
end

"""
    get_geoid_set(set_name::String) -> Vector{String}

Get the current version of a GEOID set.

# Arguments
- `set_name::String`: Name of the set

# Returns
- `Vector{String}`: GEOIDs in the current version of the set
"""
function get_geoid_set(set_name::String)
    return get_geoid_set_version(set_name, 0)
end

"""
    add_to_geoid_set(set_name::String, geoids::Vector{String}, change_description::String="Added GEOIDs") -> Int

Add GEOIDs to an existing set by creating a new version.

# Arguments
- `set_name::String`: Name of the set
- `geoids::Vector{String}`: GEOIDs to add
- `change_description::String`: Description of the change

# Returns
- `Int`: The new version number
"""
function add_to_geoid_set(set_name::String, geoids::Vector{String}, change_description::String="Added GEOIDs")
    # Get current GEOIDs
    current_geoids = get_geoid_set(set_name)
    
    # Add new GEOIDs (avoiding duplicates)
    new_geoids = union(current_geoids, geoids)
    
    # If nothing changed, return current version
    if length(new_geoids) == length(current_geoids)
        return 0
    end
    
    # Create a new version
    return create_geoid_set_version(set_name, new_geoids, change_description)
end

"""
    remove_from_geoid_set(set_name::String, geoids::Vector{String}, change_description::String="Removed GEOIDs") -> Int

Remove GEOIDs from an existing set by creating a new version.

# Arguments
- `set_name::String`: Name of the set
- `geoids::Vector{String}`: GEOIDs to remove
- `change_description::String`: Description of the change

# Returns
- `Int`: The new version number
"""
function remove_from_geoid_set(set_name::String, geoids::Vector{String}, change_description::String="Removed GEOIDs")
    # Get current GEOIDs
    current_geoids = get_geoid_set(set_name)
    
    # Remove specified GEOIDs
    new_geoids = setdiff(current_geoids, geoids)
    
    # If nothing changed, return current version
    if length(new_geoids) == length(current_geoids)
        return 0
    end
    
    # Create a new version
    return create_geoid_set_version(set_name, new_geoids, change_description)
end

"""
    list_geoid_sets() -> DataFrame

List all available GEOID sets.
"""
function list_geoid_sets()
    return execute_query(
        """
        SELECT gs.set_name, gs.description, gs.created_at, gs.updated_at,
               gs.version, gs.is_current, COUNT(gsm.geoid) AS geoid_count
        FROM census.geoid_sets gs
        LEFT JOIN census.geoid_set_members gsm 
        ON gs.set_name = gsm.set_name AND gs.version = gsm.version
        WHERE gs.is_current = TRUE
        GROUP BY gs.set_name, gs.description, gs.created_at, gs.updated_at, gs.version, gs.is_current
        ORDER BY gs.set_name;
        """
    )
end

"""
    list_geoid_set_versions(set_name::String) -> DataFrame

List all versions of a GEOID set with change information.

# Arguments
- `set_name::String`: Name of the set

# Returns
- `DataFrame`: DataFrame with version info
"""
function list_geoid_set_versions(set_name::String)
    query = """
    SELECT s.version, s.description, s.created_at, s.is_current, 
           s.parent_version, s.change_description,
           COUNT(m.geoid) AS geoid_count,
           (SELECT COUNT(*) FROM census.geoid_set_changes 
            WHERE set_name = s.set_name AND version = s.version AND change_type = 'ADD') AS added_count,
           (SELECT COUNT(*) FROM census.geoid_set_changes 
            WHERE set_name = s.set_name AND version = s.version AND change_type = 'REMOVE') AS removed_count
    FROM census.geoid_sets s
    LEFT JOIN census.geoid_set_members m ON s.set_name = m.set_name AND s.version = m.version
    WHERE s.set_name = \$1
    GROUP BY s.version, s.description, s.created_at, s.is_current, s.parent_version, s.change_description
    ORDER BY s.version DESC;
    """
    
    result = execute_query(query, [set_name])
    return result
end

"""
    delete_geoid_set(set_name::String)

Delete a GEOID set and all its versions.

# Arguments
- `set_name::String`: Name of the set to delete
"""
function delete_geoid_set(set_name::String)
    with_connection() do conn
        execute(conn, "BEGIN;")
        try
            # Delete changes first due to FK constraints
            execute(
                conn,
                "DELETE FROM census.geoid_set_changes WHERE set_name = \$1;",
                [set_name]
            )
            
            # Delete members
            execute(
                conn,
                "DELETE FROM census.geoid_set_members WHERE set_name = \$1;",
                [set_name]
            )
            
            # Delete set metadata
            execute(
                conn,
                "DELETE FROM census.geoid_sets WHERE set_name = \$1;",
                [set_name]
            )
            
            execute(conn, "COMMIT;")
        catch e
            execute(conn, "ROLLBACK;")
            rethrow(e)
        end
    end
    return nothing
end

"""
    rollback_geoid_set(set_name::String, version::Int) -> Int

Rollback a GEOID set to a previous version by creating a new version.

# Arguments
- `set_name::String`: Name of the set
- `version::Int`: Version to rollback to

# Returns
- `Int`: The new version number (after rollback)
"""
function rollback_geoid_set(set_name::String, version::Int)
    # Get the GEOIDs from the target version
    target_geoids = get_geoid_set_version(set_name, version)
    
    # Create a new version based on the target version
    change_description = "Rollback to version $version"
    new_version = create_geoid_set_version(set_name, target_geoids, change_description)
    
    return new_version
end

"""
    compare_geoid_set_versions(set_name::String, version1::Int, version2::Int) -> Dict

Compare two versions of a GEOID set and return differences.

# Arguments
- `set_name::String`: Name of the set
- `version1::Int`: First version to compare
- `version2::Int`: Second version to compare

# Returns
- `Dict`: Dictionary with 'added', 'removed', and 'common' GEOIDs
"""
function compare_geoid_set_versions(set_name::String, version1::Int, version2::Int)
    geoids1 = get_geoid_set_version(set_name, version1)
    geoids2 = get_geoid_set_version(set_name, version2)
    
    added = setdiff(geoids2, geoids1)
    removed = setdiff(geoids1, geoids2)
    common = intersect(geoids1, geoids2)
    
    return Dict(
        "added" => added,
        "removed" => removed,
        "common" => common,
        "version1_count" => length(geoids1),
        "version2_count" => length(geoids2)
    )
end

# Export functions
export create_geoid_set,
       create_geoid_set_version,
       get_geoid_set,
       get_geoid_set_version,
       add_to_geoid_set,
       remove_from_geoid_set,
       list_geoid_sets,
       list_geoid_set_versions,
       delete_geoid_set,
       rollback_geoid_set,
       compare_geoid_set_versions

end # module Store 