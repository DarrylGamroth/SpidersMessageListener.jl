module SpidersMessageListener

using Aeron
using Agent
using EnumX
using SpidersFragmentFilters
using SpidersMessageCodecs

include("controlagent.jl")

function main(ARGS)
    # Initialize Aeron
    client = Aeron.Client()

    # Initialize the agent
    agent = ControlAgent(client, "SpidersMessageListener")

    # Start the agent
    runner = AgentRunner(BackoffIdleStrategy(), agent)

    try
        Agent.start_on_thread(runner)

        wait(runner)
    catch e
        if e isa TaskFailedException || e isa InterruptException
            @info "Shutting down..."
        else
            @error "Exception caught:" exception = (e, catch_backtrace())
        end
    finally
        close(runner)
        close(client)
    end

    return 0
end

end # module SpidersMessageListener