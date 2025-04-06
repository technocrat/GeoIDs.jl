# GEOID Sets

GEOID sets are collections of Census Geographic Identifiers (GEOIDs) that represent specific geographic areas. GeoIDs.jl allows you to create, manage, and version these sets for consistent geographic area definitions in your analyses.

## What are GEOIDs?

GEOIDs are unique identifiers assigned by the U.S. Census Bureau to identify geographic areas. For counties, a GEOID consists of:

- The first 2 digits represent the state FIPS code
- The last 3 digits represent the county FIPS code

For example, `12086` represents:
- `12`: Florida (state FIPS code)
- `086`: Miami-Dade County (county FIPS code)

## Creating GEOID Sets

You can create a new GEOID set using the `create_geoid_set` function:

```julia
# Create a GEOID set for Florida counties
florida_counties = get_geoids_by_state("FL")
create_geoid_set("florida_counties", "All counties in Florida", florida_counties)

# Create an empty set that you can populate later
create_geoid_set("southeast_region", "Southeastern U.S. counties")
```

### Function Signature

```julia
create_geoid_set(set_name::String, description::String="", geoids::Vector{String}=String[]) -> Int
```

- `set_name`: A unique name for the GEOID set
- `description`: Optional description of the set
- `geoids`: Optional initial list of GEOIDs to include in the set
- Returns: The version number (1 for a new set)

## Retrieving GEOID Sets

To get the current version of a GEOID set:

```julia
# Get all GEOIDs in the Florida counties set
fl_geoids = get_geoid_set("florida_counties")
```

To get a specific version:

```julia
# Get version 2 of the Florida counties set
fl_geoids_v2 = get_geoid_set_version("florida_counties", 2)
```

## Modifying GEOID Sets

GeoIDs.jl maintains version history when you modify sets. Each modification creates a new version while preserving previous versions.

### Adding GEOIDs

```julia
# Add Collier County to South Florida set
new_version = add_to_geoid_set("south_florida", ["12021"], "Added Collier County")
```

### Removing GEOIDs

```julia
# Remove Miami-Dade County from South Florida set
new_version = remove_from_geoid_set("south_florida", ["12086"], "Removed Miami-Dade County")
```

## Listing GEOID Sets

To view all available GEOID sets:

```julia
sets = list_geoid_sets()
```

The result is a DataFrame with columns:
- `set_name`: Name of the GEOID set
- `description`: Description of the set
- `version`: Current version number
- `member_count`: Number of GEOIDs in the set
- `created_at`: When the set was created
- `updated_at`: When the set was last updated

## Working with Versions

GeoIDs.jl maintains complete version history for all GEOID sets.

### Listing Versions

To view all versions of a specific GEOID set:

```julia
versions = list_geoid_set_versions("south_florida")
```

The result includes:
- `version`: Version number
- `description`: Set description
- `member_count`: Number of GEOIDs in this version
- `created_at`: When this version was created
- `is_current`: Whether this is the current version
- `additions`: Number of GEOIDs added in this version
- `removals`: Number of GEOIDs removed in this version
- `change_description`: Description of changes made

### Rolling Back to Previous Versions

You can revert to a previous version:

```julia
# Roll back to version 1
new_version = rollback_geoid_set("south_florida", 1)
```

This creates a new version that matches the specified version's content.

### Comparing Versions

To compare two versions of a GEOID set:

```julia
comparison = compare_geoid_set_versions("south_florida", 1, 3)
```

The result is a dictionary with keys:
- `added`: GEOIDs present in version 3 but not in version 1
- `removed`: GEOIDs present in version 1 but not in version 3

## Deleting GEOID Sets

To permanently delete a GEOID set and all its versions:

```julia
delete_geoid_set("temp_analysis")
```

## Database Schema

GEOID sets are stored in three tables:

### census.geoid_sets

Stores metadata about GEOID sets and their versions:

| Column | Type | Description |
|--------|------|-------------|
| set_name | VARCHAR(100) | Name of the GEOID set |
| version | INT | Version number |
| description | TEXT | Description of the set |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp |
| is_current | BOOLEAN | Whether this is the current version |
| parent_version | INT | Previous version this was derived from |
| change_description | TEXT | Description of changes from parent |

### census.geoid_set_members

Stores the actual GEOIDs in each set version:

| Column | Type | Description |
|--------|------|-------------|
| set_name | VARCHAR(100) | Name of the GEOID set |
| version | INT | Version number |
| geoid | VARCHAR(5) | The GEOID value |

### census.geoid_set_changes

Tracks changes between versions:

| Column | Type | Description |
|--------|------|-------------|
| set_name | VARCHAR(100) | Name of the GEOID set |
| version | INT | Version number |
| change_type | VARCHAR(10) | 'ADDED' or 'REMOVED' |
| geoid | VARCHAR(5) | The GEOID that changed |
| changed_at | TIMESTAMP | When the change occurred | 