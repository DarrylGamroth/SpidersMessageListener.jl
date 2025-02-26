#!/bin/bash

# Set the environment variables
export JULIA_PROJECT=@.
export STATUS_URI="aeron:udp?endpoint=localhost:40123"
export STATUS_STREAM_ID=1
export CONTROL_URI="aeron:udp?endpoint=localhost:40123"
export CONTROL_STREAM_ID=2
export CONTROL_STREAM_FILTER="Camera"
# export SUB_DATA_URI_1="aeron:udp?endpoint=localhost:40123"
# export SUB_DATA_STREAM_1=3

# Run the Julia script
julia -e "using SpidersMessageListener; SpidersMessageListener.main(ARGS)"
