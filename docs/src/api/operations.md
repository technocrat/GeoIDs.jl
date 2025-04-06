# Operations Module

```@meta
CurrentModule = GeoIDs
```

The Operations module provides set operations for combining and manipulating GEOID sets, including union, intersection, difference, and symmetric difference.

## Set Operations

### Union Operation

Combines all GEOIDs from multiple sets:

```@docs
union_geoid_sets
```

### Intersection Operation

Keeps only GEOIDs that appear in all input sets:

```@docs
intersect_geoid_sets
```

### Difference Operation

Keeps GEOIDs from the first set that don't appear in the second set:

```@docs
difference_geoid_sets
```

### Symmetric Difference Operation

Keeps GEOIDs that appear in exactly one of the two input sets (not in both):

```@docs
symmetric_difference_geoid_sets
```

## Module Index

```@index
Pages = ["operations.md"]
``` 