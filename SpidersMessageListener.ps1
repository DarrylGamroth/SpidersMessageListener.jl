# Set the environment variables
$env:JULIA_PROJECT = "@."
$env:STREAM_URI_1="aeron:udp?endpoint=localhost:40123"
$env:STREAM_ID_1=1
$env:STREAM_FILTER_1 = "Camera"
$env:STREAM_URI_2="aeron:udp?endpoint=localhost:40123"
$env:STREAM_ID_2=2
$env:STREAM_FILTER_2 = "Camera"

# Run the Julia script
& "julia" -e "using SpidersMessageListener" -- $args