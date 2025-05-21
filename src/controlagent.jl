struct ControlAgent
    client::Aeron.Client
    name::String
    clock::EpochClock
    cached_clock::CachedEpochClock
    streams::Vector{Tuple{Aeron.Subscription,Aeron.FragmentAssembler}}
    ControlAgent(client, name) = new(client, name, EpochClock(), CachedEpochClock(), [])
end

Agent.name(agent::ControlAgent) = agent.name

function Agent.on_start(agent::ControlAgent)
    @info "Starting agent $(Agent.name(agent))"

    i = 1
    while haskey(ENV, "STREAM_URI_$i")
        uri = ENV["STREAM_URI_$i"]
        stream_id = parse(Int, get(ENV, "STREAM_ID_$i") do
            error("Environment variable STREAM_ID_$i not found")
        end)
        subscription = Aeron.add_subscription(agent.client, uri, stream_id)
        fragment_handler = Aeron.FragmentHandler(message_handler, subscription)
        if haskey(ENV, "STREAM_FILTER_$i")
            message_filter = SpidersTagFragmentFilter(fragment_handler, ENV["STREAM_FILTER_$i"])
            assembler = Aeron.FragmentAssembler(message_filter)
        else
            assembler = Aeron.FragmentAssembler(fragment_handler)
        end
        push!(agent.streams, (subscription, assembler))
        i += 1
    end
end

function Agent.on_close(agent::ControlAgent)
    @info "Closing agent $(Agent.name(agent))"
    for (subscription, _) in agent.streams
        close(subscription)
    end
end

function Agent.on_error(agent::ControlAgent, error::Exception)
    @error "Error in agent $(Agent.name(agent)):" exception = (error, catch_backtrace())
    throw(error)
end

const DEFAULT_FRAGMENT_COUNT_LIMIT = 10
function Agent.do_work(agent::ControlAgent)
    # Update the clock
    now = fetch!(agent.cached_clock, agent.clock)

    total_fragments = 0

    for (subscription, assembler) in agent.streams
        total_fragments += Aeron.poll(subscription, assembler, DEFAULT_FRAGMENT_COUNT_LIMIT)
    end

    return total_fragments
end

function message_handler(s::Aeron.Subscription, buffer, header)
    offset = 0
    while offset < length(buffer)
        sbe_header = MessageHeader(buffer, offset)
        message = decode(buffer, offset; header=sbe_header)
        println("Received message from channel=$(Aeron.channel(s)) stream-id=$(Aeron.stream_id(s)) session-id=$(Aeron.session_id(header))")
        println("$message\n")

        # Adjust the offset for the next message
        offset += sbe_decoded_length(message) + sbe_encoded_length(sbe_header)
    end

    nothing
end
