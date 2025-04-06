# Set Operations

GeoIDs.jl supports standard set operations on GEOID sets, allowing you to combine and manipulate geographic areas in powerful ways. These operations follow the mathematical set theory concepts and create new GEOID sets that can be saved and versioned.

## Available Operations

The package provides four primary set operations:

1. **Union**: Combines all GEOIDs from multiple sets
2. **Intersection**: Keeps only GEOIDs that appear in all sets
3. **Difference**: Keeps GEOIDs from the first set that don't appear in the second set
4. **Symmetric Difference**: Keeps GEOIDs that appear in exactly one of the two sets

## Union Operation

The union operation combines all GEOIDs from multiple sets, removing duplicates.

```julia
union_geoid_sets(set_names::Vector{String}, output_name::String, description::String="") -> Vector{String}
```

### Example

```julia
# Combine western and mountain counties into a single set
combined = union_geoid_sets(
    ["western_counties", "mountain_counties"], 
    "western_mountain_counties",
    "Combined western and mountain regions"
)

# Combine multiple regions
combined_regions = union_geoid_sets(
    ["south_florida", "central_florida", "east_coast"],
    "analysis_region",
    "Combined analysis region"
)
```

### Parameters

- `set_names`: Vector of GEOID set names to combine
- `output_name`: Name of the new GEOID set to create
- `description`: Optional description for the new set
- Returns: Vector of GEOIDs in the resulting union set

## Intersection Operation

The intersection operation keeps only GEOIDs that appear in all of the input sets.

```julia
intersect_geoid_sets(set_names::Vector{String}, output_name::String, description::String="") -> Vector{String}
```

### Example

```julia
# Find counties that are both in Florida and coastal
common = intersect_geoid_sets(
    ["florida_counties", "coastal_counties"],
    "florida_coastal_counties",
    "Florida counties on the coast"
)

# Find counties that are in all three sets
three_way_intersection = intersect_geoid_sets(
    ["high_population", "high_income", "urban_counties"],
    "affluent_urban_counties",
    "Wealthy, populated urban counties"
)
```

### Parameters

- `set_names`: Vector of GEOID set names to intersect
- `output_name`: Name of the new GEOID set to create
- `description`: Optional description for the new set
- Returns: Vector of GEOIDs in the resulting intersection set

## Difference Operation

The difference operation (sometimes called "set subtraction") keeps GEOIDs that are in the first set but not in the second set.

```julia
difference_geoid_sets(base_set::String, subtract_set::String, output_name::String, description::String="") -> Vector{String}
```

### Example

```julia
# Get all Florida counties that are not coastal
non_coastal_florida = difference_geoid_sets(
    "florida_counties",
    "coastal_counties",
    "florida_inland_counties",
    "Florida counties that are not on the coast"
)

# Get all high population counties that are not in the west
non_western_populous = difference_geoid_sets(
    "high_population_counties",
    "western_counties",
    "eastern_populous_counties"
)
```

### Parameters

- `base_set`: Name of the GEOID set to start with
- `subtract_set`: Name of the GEOID set to subtract
- `output_name`: Name of the new GEOID set to create
- `description`: Optional description for the new set
- Returns: Vector of GEOIDs in the resulting difference set

## Symmetric Difference Operation

The symmetric difference operation keeps GEOIDs that appear in exactly one of the two input sets (not in both).

```julia
symmetric_difference_geoid_sets(set1::String, set2::String, output_name::String, description::String="") -> Vector{String}
```

### Example

```julia
# Find counties that are either eastern or coastal, but not both
exclusive_regions = symmetric_difference_geoid_sets(
    "eastern_counties",
    "coastal_counties",
    "exclusive_regions",
    "Counties that are either eastern or coastal, but not both"
)

# Find counties that are in exactly one of these two states
fl_ga_exclusive = symmetric_difference_geoid_sets(
    "florida_counties",
    "georgia_counties",
    "fl_ga_exclusive"
)
```

### Parameters

- `set1`: Name of the first GEOID set
- `set2`: Name of the second GEOID set
- `output_name`: Name of the new GEOID set to create
- `description`: Optional description for the new set
- Returns: Vector of GEOIDs in the resulting symmetric difference set

## Combining Operations

You can chain set operations together to create complex geographic definitions:

```julia
# Get Florida coastal counties first
fl_coastal = intersect_geoid_sets(
    ["florida_counties", "coastal_counties"],
    "florida_coastal_counties"
)

# Get Florida coastal counties that are not in the southern region
central_coastal = difference_geoid_sets(
    "florida_coastal_counties",
    "south_florida",
    "central_florida_coastal"
)

# Combine with a specific county that we want to include
final_region = union_geoid_sets(
    ["central_florida_coastal", "individual_counties"],
    "analysis_region"
)
```

## Persistence and Versioning

All set operations create new GEOID sets that are:

1. Stored in the database
2. Versioned like any other GEOID set
3. Available for further operations or analysis

This means you can:
- Track how your geographic definitions were created
- Modify the resulting sets with normal GEOID set operations
- Roll back changes if needed
- Export and import the sets with their full history 