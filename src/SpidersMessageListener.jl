module SpidersMessageListener

using Aeron
using Agent
using Clocks
using EnumX
using SpidersFragmentFilters
using SpidersMessageCodecs

include("controlagent.jl")

export main

function (@main)(ARGS)
    # Initialize Aeron
    Aeron.Context() do context
        Aeron.Client(context) do client

            # Initialize the agent
            agent = ControlAgent(client, "SpidersMessageListener")

            # Start the agent
            runner = AgentRunner(BackoffIdleStrategy(), agent)

            Agent.start_on_thread(runner)

            try
                wait(runner)
            catch e
                if e isa TaskFailedException || e isa InterruptException
                    @info "Shutting down..."
                else
                    @error "Exception caught:" exception = (e, catch_backtrace())
                end
            finally
                close(runner)
            end
        end
    end

    return 0
end

end # module SpidersMessageListener