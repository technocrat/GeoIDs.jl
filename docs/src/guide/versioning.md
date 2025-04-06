# Versioning System

GeoIDs.jl implements a robust versioning system for GEOID sets, allowing you to track changes, roll back to previous states, and maintain a complete history of your geographic definitions.

## How Versioning Works

Every GEOID set has a version history. When you:

1. Create a new GEOID set, it gets version 1
2. Modify a GEOID set, a new version is created
3. All previous versions remain accessible and unchanged

Each version is a complete snapshot of the GEOID set at a point in time, with metadata about when and how it was created.

## Version Anatomy

Each version consists of:

- **Complete GEOID list**: The full list of GEOIDs in this version
- **Version number**: Sequential integer, starting from 1
- **Parent version**: The version this was derived from
- **Change description**: Human-readable description of what changed
- **Timestamp**: When this version was created
- **Change details**: Records of specific GEOIDs added or removed

## Listing Versions

To view all versions of a GEOID set:

```julia
versions = list_geoid_set_versions("florida_counties")
```

This returns a DataFrame with columns:
- `version`: Version number
- `description`: Set description (can vary by version)
- `member_count`: Number of GEOIDs in this version
- `created_at`: When this version was created
- `is_current`: Whether this is the current version
- `additions`: Number of GEOIDs added in this version
- `removals`: Number of GEOIDs removed in this version
- `change_description`: Description of changes made

## Accessing Specific Versions

To access a specific version of a GEOID set:

```julia
# Get GEOIDs from version 2
v2_geoids = get_geoid_set_version("florida_counties", 2)

# Get the current version
current_geoids = get_geoid_set("florida_counties")  # Same as version 0
```

The version parameter can be:
- A positive integer: Specific version number
- 0 (default): Current version (most recent)

## Comparing Versions

You can compare any two versions to see what changed:

```julia
# Compare version 1 with version 3
comparison = compare_geoid_set_versions("florida_counties", 1, 3)

# Print added and removed GEOIDs
println("Added: ", comparison["added"])
println("Removed: ", comparison["removed"])
```

The result is a dictionary with keys:
- `added`: GEOIDs present in the second version but not in the first
- `removed`: GEOIDs present in the first version but not in the second

## Rolling Back to Previous Versions

If you need to revert to a previous version:

```julia
# Roll back to version 2
new_version = rollback_geoid_set("florida_counties", 2)
```

This creates a new version that matches the content of version 2. The original version 2 remains unchanged.

## Creating New Versions Manually

While most versions are created through functions like `add_to_geoid_set` and `remove_from_geoid_set`, you can also create versions directly:

```julia
# Create a new version with a completely different set of GEOIDs
new_version = create_geoid_set_version(
    "florida_counties",     # set name
    new_geoids,             # vector of GEOIDs for this version
    "Complete redefinition",# change description
    current_version         # parent version (0 for current)
)
```

## Tracking Changes

The system automatically tracks what GEOIDs were added or removed in each version. This change tracking enables:

1. Detailed audit history of how geographic definitions evolved
2. Understanding the impact of each change
3. Reconciling different versions
4. Recreating the exact state of a GEOID set at any point in time

## Database Schema

The versioning system uses three tables:

1. `census.geoid_sets`: Basic metadata for each version
2. `census.geoid_set_members`: The GEOIDs in each version
3. `census.geoid_set_changes`: Records of specific changes (additions/removals)

## Backup and Restore

The entire version history can be backed up and restored:

```julia
# Backup all GEOID sets with version history
backup_geoid_sets("geoid_sets_backup.json")

# Restore from backup (defaults to not overwriting existing sets)
restore_geoid_sets("geoid_sets_backup.json")

# Restore and overwrite any existing sets
restore_geoid_sets("geoid_sets_backup.json", true)
```

## Use Cases for Versioning

Versioning provides several benefits:

1. **Reproducibility**: Refer to exact geographic definitions used in past analyses
2. **Auditing**: Track how and why geographic definitions changed
3. **Collaboration**: Share consistent definitions across teams and projects
4. **Iteration**: Experiment with different geographic definitions while preserving history
5. **Governance**: Implement formal approval processes for geographic definition changes 