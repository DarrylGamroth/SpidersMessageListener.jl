#!/usr/bin/env julia

using Aeron
using Agent
using EnumX
using SpidersFragmentFilters
using SpidersMessageCodecs

include("controlagent.jl")

ENV["STATUS_URI"] = "aeron:udp?endpoint=localhost:40123"
ENV["STATUS_STREAM_ID"] = "1"

ENV["CONTROL_URI"] = "aeron:udp?endpoint=localhost:40123"
ENV["CONTROL_STREAM_ID"] = "2"
ENV["CONTROL_STREAM_FILTER"] = "Camera"

ENV["SUB_DATA_URI_1"] = "aeron:udp?endpoint=localhost:40123"
ENV["SUB_DATA_STREAM_1"] = "3"

ENV["BLOCK_NAME"] = "SpidersMessageListener"

Base.exit_on_sigint(false)

function main(ARGS)
    # Initialize Aeron
    try
        client = Aeron.Client()

        # Initialize the agent
        agent = ControlAgent(client, ENV["BLOCK_NAME"])

        # Start the agent
        runner = AgentRunner(BackoffIdleStrategy(), agent)
        Agent.start_on_thread(runner)

        wait(runner)
    catch e
        if e isa TaskFailedException || e isa InterruptException
            println("Shutting down...")
        else
            println("Error: ", e)
            @error "Exception caught:" exception = (e, catch_backtrace())
        end
    end

    return 0
end

@isdefined(var"@main") ? (@main) : exit(main(ARGS))