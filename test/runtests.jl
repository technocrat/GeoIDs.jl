# SPDX-License-Identifier: MIT

using Test
using GeoIDs
using DataFrames

@testset "GeoIDs.jl" begin
    @testset "Database Connection" begin
        # Test database connection
        conn = GeoIDs.DB.get_connection()
        @test conn isa LibPQ.Connection
        close(conn)
    end

    @testset "GEOID Sets" begin
        # Create a test set
        test_set_name = "test_set_$(rand(1000:9999))"
        test_geoids = ["12086", "12011", "12099"]  # Miami-Dade, Broward, Palm Beach
        
        # Test create_geoid_set
        GeoIDs.create_geoid_set(test_set_name, "Test set for unit tests", test_geoids)
        
        # Test get_geoid_set
        retrieved_geoids = GeoIDs.get_geoid_set(test_set_name)
        @test length(retrieved_geoids) == length(test_geoids)
        @test all(geoid in retrieved_geoids for geoid in test_geoids)
        
        # Test add_to_geoid_set
        additional_geoids = ["12071", "12031"]  # Lee, Duval
        version = GeoIDs.add_to_geoid_set(test_set_name, additional_geoids)
        @test version > 0
        
        updated_geoids = GeoIDs.get_geoid_set(test_set_name)
        @test length(updated_geoids) == length(test_geoids) + length(additional_geoids)
        @test all(geoid in updated_geoids for geoid in vcat(test_geoids, additional_geoids))
        
        # Test remove_from_geoid_set
        version = GeoIDs.remove_from_geoid_set(test_set_name, ["12071"])
        @test version > 0
        
        final_geoids = GeoIDs.get_geoid_set(test_set_name)
        @test length(final_geoids) == length(updated_geoids) - 1
        @test !("12071" in final_geoids)
        
        # Test list_geoid_sets
        sets = GeoIDs.list_geoid_sets()
        @test sets isa DataFrame
        @test test_set_name in sets.set_name
        
        # Test list_geoid_set_versions
        versions = GeoIDs.list_geoid_set_versions(test_set_name)
        @test versions isa DataFrame
        @test nrow(versions) >= 3  # Initial + add + remove
        
        # Test rollback
        original_version = 1
        rollback_version = GeoIDs.rollback_geoid_set(test_set_name, original_version)
        @test rollback_version > 0
        
        rollback_geoids = GeoIDs.get_geoid_set(test_set_name)
        @test length(rollback_geoids) == length(test_geoids)
        @test all(geoid in rollback_geoids for geoid in test_geoids)
        
        # Cleanup
        GeoIDs.delete_geoid_set(test_set_name)
        
        # Verify deletion
        sets_after = GeoIDs.list_geoid_sets()
        @test !(test_set_name in sets_after.set_name)
    end
    
    @testset "Fetch Operations" begin
        # Test get_geoids_by_state
        fl_geoids = GeoIDs.get_geoids_by_state("FL")
        @test length(fl_geoids) > 0
        @test all(startswith(geoid, "12") for geoid in fl_geoids)
        
        # Test get_geoids_by_states
        east_coast_geoids = GeoIDs.get_geoids_by_states(["FL", "GA", "SC", "NC", "VA"])
        @test length(east_coast_geoids) > 0
        @test any(startswith(geoid, "12") for geoid in east_coast_geoids)  # FL
        @test any(startswith(geoid, "13") for geoid in east_coast_geoids)  # GA
        
        # Test spatial filtering
        south_fl_geoids = GeoIDs.get_geoids_by_spatial_filter(:latitude, Dict(
            "min_lat" => 25.0,
            "max_lat" => 27.0
        ))
        
        @test length(south_fl_geoids) > 0
        @test "12086" in south_fl_geoids  # Miami-Dade
    end
    
    @testset "Set Operations" begin
        # Create two test sets
        test_set1 = "test_set1_$(rand(1000:9999))"
        test_set2 = "test_set2_$(rand(1000:9999))"
        
        geoids1 = ["12086", "12011", "12099"]  # Miami-Dade, Broward, Palm Beach
        geoids2 = ["12011", "12099", "12071"]  # Broward, Palm Beach, Lee
        
        GeoIDs.create_geoid_set(test_set1, "Test set 1", geoids1)
        GeoIDs.create_geoid_set(test_set2, "Test set 2", geoids2)
        
        # Test union
        union_set = "union_$(rand(1000:9999))"
        union_geoids = GeoIDs.union_geoid_sets([test_set1, test_set2], union_set)
        @test length(union_geoids) == 4  # All unique counties
        
        # Test intersection
        intersect_set = "intersect_$(rand(1000:9999))"
        intersect_geoids = GeoIDs.intersect_geoid_sets([test_set1, test_set2], intersect_set)
        @test length(intersect_geoids) == 2  # Broward, Palm Beach
        
        # Test difference
        diff_set = "diff_$(rand(1000:9999))"
        diff_geoids = GeoIDs.difference_geoid_sets(test_set1, test_set2, diff_set)
        @test length(diff_geoids) == 1  # Miami-Dade
        
        # Test symmetric difference
        sym_diff_set = "sym_diff_$(rand(1000:9999))"
        sym_diff_geoids = GeoIDs.symmetric_difference_geoid_sets(test_set1, test_set2, sym_diff_set)
        @test length(sym_diff_geoids) == 2  # Miami-Dade, Lee
        
        # Cleanup
        GeoIDs.delete_geoid_set(test_set1)
        GeoIDs.delete_geoid_set(test_set2)
        GeoIDs.delete_geoid_set(union_set)
        GeoIDs.delete_geoid_set(intersect_set)
        GeoIDs.delete_geoid_set(diff_set)
        GeoIDs.delete_geoid_set(sym_diff_set)
    end
    
    @testset "Predefined GEOIDs" begin
        # Test constants are populated
        @test !isempty(GeoIDs.WESTERN_GEOIDS)
        @test !isempty(GeoIDs.EASTERN_GEOIDS)
        
        # Test Florida south geoids
        @test !isempty(GeoIDs.FLORIDA_SOUTH_GEOIDS)
        @test "12086" in GeoIDs.FLORIDA_SOUTH_GEOIDS  # Miami-Dade
    end
end 