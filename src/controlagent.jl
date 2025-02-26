struct ControlAgent
    client::Aeron.Client
    name::String
    sbe_position_ptr::Base.RefValue{Int64}
    input_streams::Vector{Tuple{Aeron.Subscription,Aeron.FragmentAssembler}}
    ControlAgent(client, name) = new(client, name, Ref(0), Vector{Tuple{Aeron.Subscription,Aeron.FragmentAssembler}}(undef, 0))
end

Agent.name(agent::ControlAgent) = agent.name

function Agent.on_start(agent::ControlAgent)
    @info "Starting agent $(Agent.name(agent))"

    # Get configuration from environment variables
    status_uri = get(ENV, "STATUS_URI") do
        error("Environment variable STATUS_URI not found")
    end

    status_stream_id = parse(Int, get(ENV, "STATUS_STREAM_ID") do
        error("Environment variable STATUS_STREAM_ID not found")
    end)

    # Publication for status messages
    subscription = Aeron.add_subscription(agent.client, status_uri, status_stream_id)
    fragment_handler = Aeron.FragmentHandler(message_handler, subscription)

    if haskey(ENV, "STATUS_STREAM_FILTER")
        message_filter = SpidersEventTagFragmentFilter(fragment_handler, ENV["STATUS_STREAM_FILTER"])
        assembler = Aeron.FragmentAssembler(message_filter)
    else
        assembler = Aeron.FragmentAssembler(fragment_handler)
    end
    push!(agent.input_streams, (subscription, assembler))

    control_uri = get(ENV, "CONTROL_URI") do
        error("Environment variable CONTROL_URI not found")
    end

    control_stream_id = parse(Int, get(ENV, "CONTROL_STREAM_ID") do
        error("Environment variable CONTROL_STREAM_ID not found")
    end)

    subscription = Aeron.add_subscription(agent.client, control_uri, control_stream_id)
    fragment_handler = Aeron.FragmentHandler(message_handler, subscription)

    if haskey(ENV, "CONTROL_STREAM_FILTER")
        message_filter = SpidersEventTagFragmentFilter(fragment_handler, ENV["CONTROL_STREAM_FILTER"])
        assembler = Aeron.FragmentAssembler(message_filter)
    else
        assembler = Aeron.FragmentAssembler(fragment_handler)
    end
    push!(agent.input_streams, (subscription, assembler))

    # # Subscribe to all data streams
    i = 1
    while haskey(ENV, "SUB_DATA_URI_$i")
        uri = ENV["SUB_DATA_URI_$i"]
        stream_id = parse(Int, get(ENV, "SUB_DATA_STREAM_$i") do
            error("Environment variable SUB_DATA_STREAM_$i not found")
        end)
        subscription = Aeron.add_subscription(agent.client, uri, stream_id)
        fragment_handler = Aeron.FragmentHandler(message_handler, subscription)
        assembler = Aeron.FragmentAssembler(fragment_handler)
        push!(agent.input_streams, (subscription, assembler))
        i += 1
    end
end

function Agent.on_close(agent::ControlAgent)
    @info "Closing agent $(Agent.name(agent))"
    for (subscription, _) in agent.input_streams
        close(subscription)
    end
end

function Agent.on_error(agent::ControlAgent, error::Exception)
    @error "Error in agent $(Agent.name(agent)):" exception = (error, catch_backtrace())
    throw(error)
end

const DEFAULT_FRAGMENT_COUNT_LIMIT = 10
function Agent.do_work(agent::ControlAgent)
    total_fragments = 0

    for (subscription, assembler) in agent.input_streams
        total_fragments += Aeron.poll(subscription, assembler, DEFAULT_FRAGMENT_COUNT_LIMIT)
    end

    return total_fragments
end

function message_handler(s::Aeron.Subscription, buffer, header)
    offset = 0
    while offset < length(buffer)
        sbe_header = Sbe.MessageHeader(buffer, offset)
        message = Sbe.decoder(buffer, offset)
        println("Received message from channel=$(Aeron.channel(s)) stream-id=$(Aeron.stream_id(s)) session-id=$(Aeron.session_id(header))")
        println("$message\n")
        offset += Sbe.sbe_decoded_length(message) + Sbe.sbe_encoded_length(sbe_header)
    end

    nothing
end
