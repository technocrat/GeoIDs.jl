# This retrieves the 2023 county shapefile in place of the 2023 shapefile
# already downloaded by the setup.jl script and available in the repo
# under the data/ directory.
# It for use with the 2023 census data, if needed, or for testing of direct download
# his is not used in the package, but is useful for testing or as a template
# for downloading other shapefiles

function test_download()
    # URL for the 2023 county shapefile via FTP
    url = "ftp://ftp2.census.gov/geo/tiger/GENZ2023/shp/cb_2023_us_county_500k.zip"
    output_path = "cb_2023_us_county_500k.zip"
    
    println("Testing download of 2023 county shapefile from FTP...")
    println("URL: $url")
    println("Output: $output_path")
    
    try
        # Remove existing file if present
        if isfile(output_path)
            println("Removing existing file...")
            rm(output_path)
        end
        
        # Download the file using curl
        println("Starting download from FTP...")
        cmd = `curl -s -o $output_path $url`
        println("Running: $cmd")
        run(cmd)
        
        # Check if file exists and its size
        if isfile(output_path)
            filesize_mb = round(filesize(output_path) / (1024 * 1024), digits=2)
            println("Download successful! File size: $filesize_mb MB")
            return true
        else
            println("Error: File not found after download")
            return false
        end
    catch e
        println("Error during download: $e")
        return false
    end
end

# Run the test
test_download() 