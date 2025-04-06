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

MICHIGAN_UPPER_PENINSULA = ["26053", "26131", "26061", "26083", "26013",
                          "26071", "26103", "26003", "26109", "26041",
                          "26053", "26956", "26976", "26033", "26043",
                          "26053", "26095", "26097", "20033", "26043",
                          "26053", "26153"]

EAST_OF_SIERRAS_GEOIDS = ["06037", "06059", "06061", "06075", "06085"]

NORTHERN_RURAL_CALIFORNIA = ["06015", "06093", "06049", "06023", "06105",
                           "06089", "06035"]

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
    "northern_rural_california" => (NORTHERN_RURAL_CALIFORNIA, "Rural counties in Northern California")
)

# Export the constants
export EASTERN_US_COUNTIES, WESTERN_US_COUNTIES, SOUTH_FLORIDA_COUNTIES,
       MIDWEST_COUNTIES, MOUNTAIN_WEST_COUNTIES, GREAT_PLAINS_COUNTIES,
       EAST_OF_SIERRAS, FLORIDA_GEOIDS, COLORADO_BASIN_GEOIDS,
       WEST_OF_100TH, EAST_OF_100TH, MICHIGAN_UPPER_PENINSULA,
       NORTHERN_RURAL_CALIFORNIA, PREDEFINED_SETS

end