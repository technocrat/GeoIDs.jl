# SPDX-License-Identifier: MIT

module ListGeoids

using DataFrames
using GeoIDs.DB

"""
    list_all_geoids() -> DataFrame

Returns a DataFrame containing all unique GEOIDs currently stored in any GEOID set,
along with a count of how many sets each GEOID appears in.

# Returns:
# - DataFrame with columns:
#   - `geoid`: The GEOID (e.g., '12086')
#   - `set_count`: The number of sets the GEOID appears in
#   - `set_names`: A comma-separated list of the set names the GEOID appears in

# Example
```julia
julia> list_all_geoids()
# Output:
#   geoid  | set_count | set_names
# ---------|-----------|---------------------------------
#   12086  | 2         | south_florida, florida_counties
```
"""
function list_all_geoids()
    query = """
    WITH current_sets AS (
        SELECT set_name, version 
        FROM census.geoid_sets 
        WHERE is_current = TRUE
    ),
    geoid_sets AS (
        SELECT 
            geoid,
            array_agg(DISTINCT set_name) AS set_name_array
        FROM census.geoid_set_members
        WHERE (set_name, version) IN (SELECT set_name, version FROM current_sets)
        GROUP BY geoid
    )
    SELECT 
        geoid, 
        array_length(set_name_array, 1) AS set_count,
        array_to_string(set_name_array, ', ') AS set_names
    FROM geoid_sets
    ORDER BY geoid;
    """
    
    try
        return DB.execute_query(query)
    catch e
        @warn "Error listing all GEOIDs: $e"
        return DataFrame(geoid = String[], set_count = Int[], set_names = String[])
    end
end

"""
    which_sets(geoid::String) -> DataFrame

Returns a DataFrame listing all sets that contain the specified GEOID,
along with their version and description.

# Arguments
- `geoid::String`: The GEOID to search for (e.g., '12086' for Miami-Dade county)

# Returns
- DataFrame with columns:
  - `set_name`: Name of the set containing the GEOID
  - `version`: Version of the set
  - `description`: Description of the set
  - `is_current`: Whether this is the current version

# Example
```julia
julia> which_sets("12086")
# Output:
#   set_name        | version | description               | is_current
# -----------------|---------|-----------------------------|------------
#   south_florida  | 1       | Southern Florida counties  | true
```
"""
function which_sets(geoid::String)
    query = """
    SELECT 
        m.set_name,
        m.version,
        s.description,
        s.is_current
    FROM 
        census.geoid_set_members m
    JOIN 
        census.geoid_sets s ON m.set_name = s.set_name AND m.version = s.version
    WHERE 
        m.geoid = \$1
    ORDER BY 
        m.set_name, m.version DESC;
    """
    
    try
        return DB.execute_query(query, [geoid])
    catch e
        @warn "Error finding sets for GEOID $geoid: $e"
        return DataFrame(set_name = String[], version = Int[], description = String[], is_current = Bool[])
    end
end

export list_all_geoids, which_sets

end # module ListGeoids