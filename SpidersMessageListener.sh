#!/bin/bash

# Set the environment variables
export JULIA_PROJECT=@.
export STREAM_URI_1="aeron:udp?endpoint=localhost:40123"
export STREAM_ID_1=1
export STREAM_FILTER_1="Camera"
export STREAM_URI_2="aeron:udp?endpoint=localhost:40123"
export STREAM_ID_2=2
export STREAM_FILTER_2="Camera"

# Run the Julia script
julia -e "using SpidersMessageListener" -- "$@"
