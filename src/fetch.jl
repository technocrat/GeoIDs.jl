# SPDX-License-Identifier: MIT

module Fetch

using DataFrames
using ..DB: execute_query

"""
    get_geoids_by_state(state::String) -> Vector{String}

Get GEOIDs for all counties in a state.

# Arguments
- `state::String`: State postal code (e.g., "CA")

# Returns
- `Vector{String}`: GEOIDs for counties in the state

# Example
```julia
ca_geoids = get_geoids_by_state("CA")
```
"""
function get_geoids_by_state(state::String)
    query = """
    SELECT geoid FROM census.counties
    WHERE stusps = \$1
    ORDER BY geoid;
    """
    
    result = execute_query(query, [state])
    # Convert to Vector{String} to ensure type stability
    return String.(collect(skipmissing(result.geoid)))
end

"""
    get_geoids_by_states(states::Vector{String}) -> Vector{String}

Get GEOIDs for all counties in multiple states.

# Arguments
- `states::Vector{String}`: Vector of state postal codes (e.g., ["CA", "OR", "WA"])

# Returns
- `Vector{String}`: GEOIDs for counties in the specified states

# Example
```julia
west_coast_geoids = get_geoids_by_states(["CA", "OR", "WA"])
```
"""
function get_geoids_by_states(states::Vector{String})
    query = """
    SELECT geoid FROM census.counties
    WHERE stusps = ANY(\$1)
    ORDER BY geoid;
    """
    
    result = execute_query(query, [states])
    # Convert to Vector{String} to ensure type stability
    return String.(collect(skipmissing(result.geoid)))
end

"""
    get_geoids_by_county_names(state::String, counties::Vector{String}) -> Vector{String}

Get GEOIDs for specific counties in a state by name.

# Arguments
- `state::String`: State postal code (e.g., "CA")
- `counties::Vector{String}`: Vector of county names

# Returns
- `Vector{String}`: GEOIDs for the specified counties

# Example
```julia
socal_geoids = get_geoids_by_county_names("CA", ["Los Angeles", "Orange", "San Diego"])
```
"""
function get_geoids_by_county_names(state::String, counties::Vector{String})
    placeholders = join(["\$$(i+1)" for i in 1:length(counties)], ", ")
    
    query = """
    SELECT geoid FROM census.counties
    WHERE stusps = \$1 AND name IN ($placeholders)
    ORDER BY geoid;
    """
    
    result = execute_query(query, [state, counties...])
    return String.(collect(skipmissing(result.geoid)))
end

"""
    get_geoids_by_spatial_filter(filter_type::Symbol, parameters::Dict) -> Vector{String}

Generate GEOIDs based on spatial filtering parameters.

# Filter Types
- `:longitude`: Filter by longitude range (requires `min_lon`, `max_lon`)
- `:latitude`: Filter by latitude range (requires `min_lat`, `max_lat`)
- `:bounding_box`: Filter by bounding box (requires `min_lon`, `max_lon`, `min_lat`, `max_lat`)
- `:distance`: Filter by distance from point (requires `center_lon`, `center_lat`, `radius_miles`)
- `:state`: Filter by state (requires `states` as array of state abbreviations)
- `:intersects`: Filter by intersection with geometry (requires `geometry`)

# Example
```julia
# Get counties within longitude range
west_counties = get_geoids_by_spatial_filter(:longitude, Dict("min_lon" => -120.0, "max_lon" => -110.0))

# Get counties within 50 miles of Chicago
chicago_area = get_geoids_by_spatial_filter(:distance, Dict(
    "center_lon" => -87.623177, 
    "center_lat" => 41.881832, 
    "radius_miles" => 50
))
```
"""
function get_geoids_by_spatial_filter(filter_type::Symbol, parameters::Dict)
    # Build the appropriate SQL query based on filter type
    query_start = "SELECT geoid FROM census.counties WHERE "
    query_end = " ORDER BY geoid"
    query_middle = ""
    params = []
    
    if filter_type == :longitude
        query_middle = "ST_X(ST_Centroid(geom)) BETWEEN \$1 AND \$2"
        push!(params, parameters["min_lon"], parameters["max_lon"])
    elseif filter_type == :latitude
        query_middle = "ST_Y(ST_Centroid(geom)) BETWEEN \$1 AND \$2"
        push!(params, parameters["min_lat"], parameters["max_lat"])
    elseif filter_type == :bounding_box
        query_middle = "ST_Within(ST_Centroid(geom), ST_MakeEnvelope(\$1, \$2, \$3, \$4, 4269))"
        push!(params, parameters["min_lon"], parameters["min_lat"], parameters["max_lon"], parameters["max_lat"])
    elseif filter_type == :distance
        # Convert miles to degrees (approximate)
        miles_to_degrees = 1/69.0
        radius_degrees = parameters["radius_miles"] * miles_to_degrees
        
        query_middle = "ST_DWithin(ST_Centroid(geom), ST_SetSRID(ST_MakePoint(\$1, \$2), 4269), \$3)"
        push!(params, parameters["center_lon"], parameters["center_lat"], radius_degrees)
    elseif filter_type == :state
        query_middle = "stusps = ANY(\$1)"
        push!(params, parameters["states"])
    elseif filter_type == :intersects
        query_middle = "ST_Intersects(geom, ST_GeomFromGeoJSON(\$1))"
        push!(params, parameters["geometry"])
    else
        throw(ArgumentError("Unknown filter type: $filter_type"))
    end
    
    query = query_start * query_middle * query_end
    
    # Execute the query
    result = execute_query(query, params)
    return String.(collect(skipmissing(result.geoid)))
end

"""
    get_western_geoids() -> Vector{String}

Returns GEOIDs for counties west of 100°W longitude and east of 115°W longitude,
getting the high plains counties with historically low rainfall (< 20 inches per year).
"""
function get_western_geoids()
    return get_geoids_by_spatial_filter(:longitude, Dict(
        "min_lon" => -115.0,
        "max_lon" => -100.0
    ))
end

"""
    get_eastern_geoids() -> Vector{String}

Returns GEOIDs for counties between 90°W and 100°W longitude,
getting the eastern counties with historically high rainfall (> 20 inches per year).
"""
function get_eastern_geoids()
    return get_geoids_by_spatial_filter(:longitude, Dict(
        "min_lon" => -100.0,
        "max_lon" => -90.0
    ))
end

"""
    get_florida_south_geoids() -> Vector{String}

Returns GEOIDs for Florida counties with centroids south of 29°N latitude.
"""
function get_florida_south_geoids()
    query = """
    SELECT geoid FROM census.counties
    WHERE stusps = 'FL' AND ST_Y(ST_Centroid(geom)) < 29.0
    ORDER BY geoid;
    """
    
    result = execute_query(query)
    return String.(collect(skipmissing(result.geoid)))
end

"""
    get_nation_state_geoids(nation_state::String) -> Vector{String}

Get GEOIDs for counties in a specific nation state.

# Arguments
- `nation_state::String`: Name of the nation state

# Returns
- `Vector{String}`: GEOIDs for counties in the nation state

# Example
```julia
powell_geoids = get_nation_state_geoids("powell")
```
"""
function get_nation_state_geoids(nation_state::String)
    query = """
    SELECT geoid FROM census.counties
    WHERE nation = \$1
    ORDER BY geoid;
    """
    
    result = execute_query(query, [nation_state])
    return String.(collect(skipmissing(result.geoid)))
end

"""
    set_nation_state_geoids(nation_state::String, geoids::Vector{String})

Set the nation state for a list of counties.

# Arguments
- `nation_state::String`: Name of the nation state
- `geoids::Vector{String}`: GEOIDs for counties to include in the nation state

# Example
```julia
set_nation_state_geoids("powell", powell_geoids)
```
"""
function set_nation_state_geoids(nation_state::String, geoids::Vector{String})
    query1 = """
    UPDATE census.counties 
    SET nation = NULL 
    WHERE nation = \$1;
    """
    
    query2 = """
    UPDATE census.counties 
    SET nation = \$1 
    WHERE geoid = ANY(\$2);
    """
    
    execute_query(query1, [nation_state])
    execute_query(query2, [nation_state, geoids])
    
    return nothing
end

"""
    get_geoids_by_population_range(min_pop::Int, max_pop::Int) -> Vector{String}

Get GEOIDs for counties with population within the specified range.

# Arguments
- `min_pop::Int`: Minimum population
- `max_pop::Int`: Maximum population

# Returns
- `Vector{String}`: GEOIDs for counties in the population range

# Example
```julia
rural_counties = get_geoids_by_population_range(0, 50000)
```
"""
function get_geoids_by_population_range(min_pop::Int, max_pop::Int)
    query = """
    SELECT c.geoid
    FROM census.counties c
    JOIN census.variable_data v ON c.geoid = v.geoid
    WHERE v.variable_name = 'total_population'
    AND v.value BETWEEN \$1 AND \$2
    ORDER BY c.geoid
    """
    
    result = execute_query(query, [min_pop, max_pop])
    return String.(collect(skipmissing(result.geoid)))
end

"""
    get_geoids_by_custom_query(query::String, params::Vector=[]) -> Vector{String}

Get GEOIDs using a custom SQL query.

# Arguments
- `query::String`: Custom SQL query (must return a 'geoid' column)
- `params::Vector`: Query parameters

# Returns
- `Vector{String}`: GEOIDs returned by the query

# Example
```julia
custom_geoids = get_geoids_by_custom_query(
    "SELECT geoid FROM census.counties WHERE name LIKE \$1", 
    ["%San%"]
)
```
"""
function get_geoids_by_custom_query(query::String, params::Vector=[])
    result = execute_query(query, params)
    
    if !("geoid" in names(result))
        error("Custom query must return a 'geoid' column")
    end
    
    return String.(collect(skipmissing(result.geoid)))
end

# Export functions
export get_geoids_by_state,
       get_geoids_by_states,
       get_geoids_by_county_names,
       get_geoids_by_spatial_filter,
       get_western_geoids,
       get_eastern_geoids,
       get_florida_south_geoids,
       get_nation_state_geoids,
       set_nation_state_geoids,
       get_geoids_by_population_range,
       get_geoids_by_custom_query

end # module Fetch 