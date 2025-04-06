# POLICY.md for GeoIDs.jl

## Project Overview
- **Name**: GeoIDs.jl
- **Purpose**: Julia package for downloading and processing US Census TIGER/Line shapefiles
- **Database**: PostgreSQL (tiger database)
- **Programming Paradigm**: Functional programming approach

## Development Principles

### Code Quality
1. **Functional Style**: Prefer pure functions and immutable data structures
2. **Type Stability**: Ensure functions have consistent return types
3. **Error Handling**: Use robust error handling with informative messages
4. **Testing**: Include comprehensive tests for all functionality
5. **Documentation**: Provide clear documentation with examples

### Database Operations
1. **Resilience**: All database operations should handle missing schemas/tables
2. **Idempotence**: Functions should be safe to run multiple times
3. **Transaction Safety**: Use transactions for multi-step operations
4. **Error Recovery**: Provide graceful error handling for database operations

### GEOID Set Management
1. **Version Control**: Maintain version history for all GEOID sets
2. **Data Integrity**: Ensure consistency between database and module constants
3. **Backwards Compatibility**: Preserve access to previous versions

### Development Process
1. **Explore Thoroughly**: Investigate issues completely before implementing solutions
2. **Verify Consistency**: When changing functions, update all related components
3. **Test Incrementally**: Test changes thoroughly before proceeding
4. **Document Changes**: Update documentation to reflect new functionality

### User Experience
1. **Informative Messages**: Provide clear progress and error messages
2. **Sensible Defaults**: Functions should have reasonable default parameters
3. **Graceful Degradation**: Handle missing prerequisites without crashing
4. **Progressive Enhancement**: Core functions work with minimal setup

## Technical Requirements
1. **Julia Compatibility**: Support Julia 1.6 and higher
2. **PostgreSQL Requirements**: Compatible with PostgreSQL 12 and higher
3. **Environmental Adaptability**: Honor environment variables for configuration
4. **Minimal Dependencies**: Keep external dependencies to essential packages only 