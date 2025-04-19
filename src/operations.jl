# SPDX-License-Identifier: MIT

module Operations

using ..Store: get_geoid_set, create_geoid_set_version

"""
    union_geoid_sets(set_names::Vector{String}, output_name::String, description::String="") -> Vector{String}

Create a new GEOID set that is the union of multiple existing sets.

# Arguments
- `set_names::Vector{String}`: Names of the sets to combine
- `output_name::String`: Name of the new set to create
- `description::String`: Optional description for the new set

# Returns
- Vector{String}: The GEOIDs in the new set

# Example
```julia
combined = union_geoid_sets(["western_counties", "mountain_counties"], "western_mountain_counties")
```
"""
function union_geoid_sets(set_names::Vector{String}, output_name::String, description::String="")
    # Get the union of all GEOIDs in the specified sets
    union_geoids = String[]
    
    for set_name in set_names
        append!(union_geoids, get_geoid_set(set_name))
    end
    
    # Remove duplicates
    unique!(union_geoids)
    
    # Create the new set
    change_description = "Union of sets: $(join(set_names, ", "))"
    create_geoid_set_version(output_name, union_geoids, change_description, 0, description)
    
    return union_geoids
end

"""
    intersect_geoid_sets(set_names::Vector{String}, output_name::String, description::String="") -> Vector{String}

Create a new GEOID set that is the intersection of multiple existing sets.

# Arguments
- `set_names::Vector{String}`: Names of the sets to intersect
- `output_name::String`: Name of the new set to create
- `description::String`: Optional description for the new set

# Returns
- Vector{String}: The GEOIDs in the new set

# Example
```julia
common = intersect_geoid_sets(["florida_counties", "coastal_counties"], "florida_coastal_counties")
```
"""
function intersect_geoid_sets(set_names::Vector{String}, output_name::String, description::String="")
    if isempty(set_names)
        return String[]
    end
    
    # Get the first set
    result_geoids = get_geoid_set(set_names[1])
    
    # Intersect with each subsequent set
    for i in 2:length(set_names)
        next_set = get_geoid_set(set_names[i])
        filter!(geoid -> geoid in next_set, result_geoids)
    end
    
    # Create the new set
    change_description = "Intersection of sets: $(join(set_names, ", "))"
    create_geoid_set_version(output_name, result_geoids, change_description, 0, description)
    
    return result_geoids
end

"""
    difference_geoid_sets(base_set::String, subtract_set::String, output_name::String, description::String="") -> Vector{String}

Create a new GEOID set that contains elements in base_set that are not in subtract_set.

# Arguments
- `base_set::String`: Name of the base set
- `subtract_set::String`: Name of the set to subtract
- `output_name::String`: Name of the new set to create
- `description::String`: Optional description for the new set

# Returns
- Vector{String}: The GEOIDs in the new set

# Example
```julia
non_coastal_florida = difference_geoid_sets("florida_counties", "coastal_counties", "florida_inland_counties")
```
"""
function difference_geoid_sets(base_set::String, subtract_set::String, output_name::String, description::String="")
    base_geoids = get_geoid_set(base_set)
    subtract_geoids = get_geoid_set(subtract_set)
    
    # Remove GEOIDs that are in the subtract set
    result_geoids = filter(geoid -> !(geoid in subtract_geoids), base_geoids)
    
    # Create the new set
    change_description = "Difference: $base_set - $subtract_set"
    create_geoid_set_version(output_name, result_geoids, change_description, 0, description)
    
    return result_geoids
end

"""
    symmetric_difference_geoid_sets(set1::String, set2::String, output_name::String, description::String="") -> Vector{String}

Create a new GEOID set with elements that are in either set but not in both.

# Arguments
- `set1::String`: Name of the first set
- `set2::String`: Name of the second set
- `output_name::String`: Name of the new set to create
- `description::String`: Optional description for the new set

# Returns
- Vector{String}: The GEOIDs in the new set

# Example
```julia
exclusive_regions = symmetric_difference_geoid_sets("eastern_counties", "coastal_counties", "exclusive_regions")
```
"""
function symmetric_difference_geoid_sets(set1::String, set2::String, output_name::String, description::String="")
    set1_geoids = get_geoid_set(set1)
    set2_geoids = get_geoid_set(set2)
    
    # Get elements that are in one set but not both
    only_in_set1 = filter(geoid -> !(geoid in set2_geoids), set1_geoids)
    only_in_set2 = filter(geoid -> !(geoid in set1_geoids), set2_geoids)
    
    result_geoids = vcat(only_in_set1, only_in_set2)
    
    # Create the new set
    change_description = "Symmetric difference of $set1 and $set2"
    create_geoid_set_version(output_name, result_geoids, change_description, 0, description)
    
    return result_geoids
end

# Export functions
export union_geoid_sets,
       intersect_geoid_sets,
       difference_geoid_sets,
       symmetric_difference_geoid_sets

"""
    get_centroid_longitude_range_geoids(min_long::Float64, max_long::Float64) -> Vector{String}

Returns GEOIDs for counties with centroids between the specified longitude range.
Longitude values should be in decimal degrees, with negative values for western hemisphere.

# Arguments
- `min_long::Float64`: Minimum longitude (western boundary)
- `max_long::Float64`: Maximum longitude (eastern boundary)

# Returns
- `Vector{String}`: Vector of county GEOIDs within the specified longitude range

# Example
```julia
# Get counties between -110°W and -115°W
geoids = get_centroid_longitude_range_geoids(-115.0, -110.0)
```
"""
function get_centroid_longitude_range_geoids(min_long::Float64, max_long::Float64)
    conn = get_connection()
    try
        query = """
        SELECT geoid 
        FROM census.counties 
        WHERE ST_X(ST_Centroid(geom)) BETWEEN $min_long AND $max_long
        ORDER BY geoid;
        """
        result = execute(conn, query)
        return DataFrame(result).geoid
    finally
        return_connection(conn)
    end
end

end # module Operations 