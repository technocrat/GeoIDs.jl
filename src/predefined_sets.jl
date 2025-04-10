"""
    Predefined GEOID Sets

This module provides predefined sets of GEOIDs for common geographic regions.
These can used to initialize the database with standard sets that users can reference.
"""

module PredefinedSets

# The lands west of the 100th meridian lie in the rain shadow of the Rockies and generally experience less than 20 inches of precipitation per year,
# which requires irrigation to support agriculture.
WEST_OF_100TH = ["48357", "48359", "48111", "48205", "48233",
             "48295", "48421", "48341", "48195", "48115",
             "48117"]

# The lands east of the 100th meridian lie outside of the rain shadow of the Rockies and generally experience more than 20 inches of precipitation per year,
# which supports agriculture without irrigation.
EAST_OF_100TH = ["48375", "48179", "48483", "48101", "48437",
               "48369", "48191", "48393", "48087", "48211"]

# Counties in Michigan's Upper Peninsula
MICHIGAN_UPPER_PENINSULA = ["26131", "26061", "26083", "26013",
                          "26071", "26103", "26003", "26109", "26041",
                          "26053", "26095", "26097", "26033", "26043",
                          "26153", "26956", "26976"]

EAST_OF_SIERRAS_GEOIDS = ["06037", "06059", "06061", "06075", "06085"]

NORTHERN_RURAL_CALIFORNIA = ["06015", "06093", "06049", "06023", "06105",
                           "06089", "06035"]

# Southern California counties
SOCAL_GEOIDS = [
    "06025",  # Imperial County
    "06029",  # Kern County
    "06037",  # Los Angeles County
    "06059",  # Orange County
    "06065",  # Riverside County
    "06071",  # San Bernardino County
    "06073",  # San Diego County
    "06079",  # San Luis Obispo County
    "06083",  # Santa Barbara County
    "06111"   # Ventura County
]

# Missouri River Basin counties across MT, ND, SD, IA, NE, MO, MN
MISSOURI_RIVER_BASIN = ["30005", "30007", "30013", "30015", "30017",
    "30021", "30027", "30033", "30041", "30045",
    "30049", "30051", "30055", "30059", "30069",
    "30071", "30075", "30079", "30083", "30085",
    "30087", "30091", "30099", "30101", "30105",
    "30109", "38001", "38007", "38011", "38013",
    "38015", "38023", "38025", "38029", "38033",
    "38037", "38041", "38053", "38055", "38057",
    "38059", "38061", "38065", "38085", "38087",
    "38089", "38101", "38105", "46003", "46005",
    "46007", "46009", "46011", "46013", "46015",
    "46017", "46019", "46021", "46023", "46025",
    "46029", "46031", "46033", "46035", "46037",
    "19001", "19003", "31001", "29003", "31003",
    "31005", "29005", "19009", "31007", "27011",
    "31009", "31011", "31013", "31015", "31017",
    "29021", "31019", "31021", "31023", "19027",
    "29033", "19029", "31025", "31027", "29041",
    "31029", "19035", "31031", "31033", "27023",
    "29045", "19039", "31035", "29051", "31037",
    "29053", "19047", "31039", "31041", "31043",
    "19049", "31045", "31047", "31049", "31051",
    "31053", "31055", "31057", "31059", "29071",
    "31061", "19071", "31063", "31065", "31067",
    "31069", "31071", "29073", "31073", "31075",
    "31077", "19073", "19077", "31079", "31081",
    "31083", "19085", "31085", "31087", "29087",
    "31089", "31091", "29089", "31093", "19093",
    "29095", "29099", "31095", "31097", "31099",
    "31101", "31103", "31105", "31107", "27073",
    "31109", "29111", "27081", "29113", "31111",
    "31113", "31115", "31119", "29127", "31117",
    "31121", "19129", "29135", "19133", "19137",
    "29139", "31123", "27101", "31125", "31127",
    "27105", "31129", "29151", "31131", "19145",
    "31133", "31135", "29157", "31137", "31139",
    "29163", "27117", "29165", "31141", "19149",
    "31143", "19155", "29173", "31145", "27127",
    "31147", "19159", "27133", "31149", "19161",
    "29195", "31151", "31153", "31155", "31157",
    "31159", "19165", "31161", "31163", "19167",
    "31165", "29183", "29189", "31167", "27151",
    "19173", "31169", "31171", "31173", "27155",
    "19175", "31175", "29219", "29221", "31177",
    "31179", "31181", "31183", "19193", "27173",
    "31185", "30019"]

# Counties east of the Cascade Range in Washington and Oregon (east of ~121° longitude)
EAST_OF_CASCADES = [
    # Washington counties
    "53001",  # Adams
    "53003",  # Asotin
    "53005",  # Benton
    "53007",  # Chelan
    "53013",  # Columbia
    "53017",  # Douglas
    "53019",  # Ferry
    "53021",  # Franklin
    "53023",  # Garfield
    "53025",  # Grant
    "53037",  # Kittitas
    "53039",  # Klickitat
    "53043",  # Lincoln
    "53047",  # Okanogan
    "53051",  # Pend Oreille
    "53063",  # Spokane
    "53065",  # Stevens
    "53071",  # Walla Walla
    "53075",  # Whitman
    "53077",  # Yakima
    # Oregon counties
    "41001",  # Baker
    "41013",  # Crook
    "41017",  # Deschutes
    "41021",  # Gilliam
    "41023",  # Grant
    "41025",  # Harney
    "41027",  # Hood River
    "41031",  # Jefferson
    "41035",  # Klamath
    "41037",  # Lake
    "41045",  # Malheur
    "41049",  # Morrow
    "41055",  # Sherman
    "41059",  # Umatilla
    "41061",  # Union
    "41063",  # Wallowa
    "41065",  # Wasco
    "41069"   # Wheeler
]

# Counties in the Colorado Basin, exclusive of California counties. 
# Source: https://coloradoriverbasin-lincolninstitute.hub.arcgis.com/datasets/a922a3809058416b8260813e822f8980_0/explore?location=36.663436%2C-110.573590%2C5.51

COLORADO_BASIN_GEOIDS = ["08109", "35003", "56023", "56013", "08115", 
                       "56041", "32003", "08067", "08111", "49013", 
                       "08097", "06111", "08093", "06037", "04027", 
                       "04021", "08099", "08081", "08059", "08117", 
                       "04017", "06073", "08101", "49011", "08013", 
                       "08031", "08085", "08037", "08113", "08015", 
                       "08025", "08043", "35055", "32023", "35017", 
                       "04011", "04013", "35043", "04019", "35006", 
                       "08029", "08045", "56037", "32033", "08103", 
                       "08087", "56007", "04003", "35023", "06071", 
                       "08083", "49025", "08001", "35053", "35028", 
                       "08079", "04005", "08089", "49035", "49041", 
                       "49017", "08091", "49053", "08011", "08007", 
                       "06065", "08107", "08053", "49031", "49043", 
                       "04007", "04009", "08123", "56021", "35045", 
                       "49015", "08069", "08065", "49009", "08105", 
                       "35029", "35031", "35039", "04015", "04025", 
                       "08047", "32017", "04012", "49047", "49049", 
                       "08057", "49055", "08019", "08075", "35049", 
                       "06059", "04023", "06025", "04001", "08121", 
                       "49007", "35001", "49021", "49039", "08035", 
                       "08021", "49037", "56039", "08041", "49051", 
                       "08051", "35051", "08077", "08033", "08005", 
                       "56035", "49019", "35061", "08049"]

# Counties east of the Sierra Nevada mountains, excluding Plumas County.
EAST_OF_SIERRAS = ["06003", "06017", "06027", "06035", "06049", 
                  "06051", "06057", "06063", "06071", "06091"]

# Florida counties south of latitude 29 degrees North, containing the bulk of the state's 
# retirement and seasonal populations.  
FLORIDA_GEOIDS = ["12017", "12069", "12117", "12119", "12053", 
                "12095", "12101", "12009", "12097", "12105", 
                "12057", "12103", "12061", "12049", "12081", 
                "12093", "12111", "12055", "12027", "12115", 
                "12085", "12043", "12015", "12099", "12071", 
                "12051", "12011", "12021", "12086", "12087"]

# Constants for the main module to reference
EASTERN_US_COUNTIES = ["36001", "36003", "36005", "36007"]  # Some counties in NY
WESTERN_US_COUNTIES = ["06001", "06003", "06005", "06007"]  # Some counties in CA
SOUTH_FLORIDA_COUNTIES = ["12086", "12011", "12099"]       # Miami-Dade, Broward, Palm Beach
MIDWEST_COUNTIES = ["17001", "17003", "17005"]             # Some counties in IL
MOUNTAIN_WEST_COUNTIES = ["08001", "08003", "08005"]       # Some counties in CO
GREAT_PLAINS_COUNTIES = ["20001", "20003", "20005"]        # Some counties in KS

# Dictionary mapping set names to (geoids, description) tuples
PREDEFINED_SETS = Dict(
    "eastern_us" => (EASTERN_US_COUNTIES, "Counties in the eastern United States"),
    "western_us" => (WESTERN_US_COUNTIES, "Counties in the western United States"),
    "south_florida" => (SOUTH_FLORIDA_COUNTIES, "Counties in South Florida"),
    "midwest" => (MIDWEST_COUNTIES, "Counties in the Midwest"),
    "mountain_west" => (MOUNTAIN_WEST_COUNTIES, "Counties in the Mountain West"),
    "great_plains" => (GREAT_PLAINS_COUNTIES, "Counties in the Great Plains"),
    "east_of_sierras" => (EAST_OF_SIERRAS, "Counties east of the Sierra Nevada mountains"),
    "florida" => (FLORIDA_GEOIDS, "Florida counties south of 29 degrees North"),
    "colorado_basin" => (COLORADO_BASIN_GEOIDS, "Counties in the Colorado River Basin"),
    "west_of_100th" => (WEST_OF_100TH, "Counties west of the 100th meridian"),
    "east_of_100th" => (EAST_OF_100TH, "Counties east of the 100th meridian"),
    "michigan_upper_peninsula" => (MICHIGAN_UPPER_PENINSULA, "Counties in Michigan's Upper Peninsula"),
    "northern_rural_california" => (NORTHERN_RURAL_CALIFORNIA, "Rural counties in Northern California"),
    "socal" => (SOCAL_GEOIDS, "Southern California counties"),
    "missouri_river_basin" => (MISSOURI_RIVER_BASIN, "Counties in the Missouri River Basin across MT, ND, SD, IA, NE, MO, and MN"),
    "east_of_cascades" => (EAST_OF_CASCADES, "Counties east of the Cascade Range in Washington and Oregon (east of ~121° longitude)")
)

"""
    create_predefined_set(set_name::String) -> Union{Vector{String}, Nothing}

Creates a predefined GEOID set in the database.

# Arguments
- `set_name::String`: Name of the predefined set to create (e.g., "eastern_us", "south_florida")

# Returns
- `Vector{String}`: The GEOIDs that were added to the set if successful
- `nothing`: If the set name is not recognized

# Example
```julia
julia> create_predefined_set("south_florida")
# Creates the south_florida set in the database
```
"""
function create_predefined_set(set_name::String)
    if !haskey(PREDEFINED_SETS, set_name)
        @warn "Unknown predefined set: $set_name"
        @info "Available predefined sets: $(join(keys(PREDEFINED_SETS), ", "))"
        return nothing
    end
    
    geoids, description = PREDEFINED_SETS[set_name]
    
    # Check if we're in the main module context or being called directly
    if isdefined(Main, :GeoIDs) && isdefined(Main.GeoIDs, :Store) && 
       isdefined(Main.GeoIDs.Store, :create_geoid_set)
        # Called in normal usage context
        Main.GeoIDs.Store.create_geoid_set(set_name, description, geoids)
        @info "Created predefined set '$set_name' with $(length(geoids)) GEOIDs"
        return geoids
    else
        # Direct usage of the module
        @warn "GeoIDs.Store module not available. Make sure you're using this function through the GeoIDs module."
        return geoids
    end
end

"""
    create_all_predefined_sets() -> Dict{String, Int}

Creates all predefined GEOID sets in the database.

# Returns
- `Dict{String, Int}`: A dictionary mapping set names to the number of GEOIDs in each set

# Example
```julia
julia> create_all_predefined_sets()
# Creates all predefined sets in the database
```
"""
function create_all_predefined_sets()
    results = Dict{String, Int}()
    
    # Check if we're in the main module context
    if !isdefined(Main, :GeoIDs) || !isdefined(Main.GeoIDs, :Store) || 
       !isdefined(Main.GeoIDs.Store, :create_geoid_set)
        @warn "GeoIDs.Store module not available. Make sure you're using this function through the GeoIDs module."
        return results
    end
    
    for (set_name, (geoids, description)) in PREDEFINED_SETS
        try
            Main.GeoIDs.Store.create_geoid_set(set_name, description, geoids)
            results[set_name] = length(geoids)
            @info "Created predefined set '$set_name' with $(length(geoids)) GEOIDs"
        catch e
            @warn "Failed to create set '$set_name': $e"
            results[set_name] = 0
        end
    end
    
    return results
end

# Export the constants
export EASTERN_US_COUNTIES, WESTERN_US_COUNTIES, SOUTH_FLORIDA_COUNTIES,
       MIDWEST_COUNTIES, MOUNTAIN_WEST_COUNTIES, GREAT_PLAINS_COUNTIES,
       EAST_OF_SIERRAS, FLORIDA_GEOIDS, COLORADO_BASIN_GEOIDS,
       WEST_OF_100TH, EAST_OF_100TH, MICHIGAN_UPPER_PENINSULA,
       NORTHERN_RURAL_CALIFORNIA, SOCAL_GEOIDS, MISSOURI_RIVER_BASIN, 
       EAST_OF_CASCADES, PREDEFINED_SETS, create_predefined_set,
       create_all_predefined_sets

end