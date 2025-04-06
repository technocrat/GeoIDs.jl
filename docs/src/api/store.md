# Store Module

```@meta
CurrentModule = GeoIDs
```

The Store module provides functions for creating, retrieving, and managing GEOID sets in the database with versioning support.

## Creating GEOID Sets

Functions for creating new GEOID sets and versions:

```@docs
create_geoid_set
create_geoid_set_version
```

## Retrieving GEOID Sets

Functions for retrieving GEOID sets and their versions:

```@docs
get_geoid_set
get_geoid_set_version
list_geoid_sets
list_geoid_set_versions
```

## Modifying GEOID Sets

Functions for adding to or removing from GEOID sets:

```@docs
add_to_geoid_set
remove_from_geoid_set
```

## Version Management

Functions for managing and comparing versions:

```@docs
rollback_geoid_set
compare_geoid_set_versions
```

## Deleting GEOID Sets

```@docs
delete_geoid_set
```

## Module Index

```@index
Pages = ["store.md"]
``` 