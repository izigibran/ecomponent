-module(metrics).

%% API
-export([
    init/0, 
    notify_throughput_presence/2,
    notify_throughput_message/2,
    notify_throughput_iq/3, 
    set_iq_time/3, 
    notify_resp_time/1, 
    notify_dropped_presence/1,
    notify_dropped_message/1,
    notify_dropped_iq/2
]).

-spec init() -> ok.

init() ->
    case ets:info(metrics) of
        undefined ->
            ets:new(metrics, [named_table, public]);
        _ ->
            ets:delete_all_objects(metrics)
    end,
    case ets:info(response_time) of
        undefined ->
            ets:new(response_time, [named_table, public]);
        _ ->
            ets:delete_all_objects(response_time)
    end,
    ok.

-spec notify_throughput_presence(IO::atom(), Type :: atom()) ->
    ok | {error, Name :: atom(), nonexistent_metric} |
    {error, Type :: atom(), unsupported_metric_type}.

notify_throughput_presence(IO, Type) ->
    Name = concat("presence_throughput_", concat(IO, concat("_", Type))),
    case ets:member(metrics, Name) of 
        false ->
            folsom_metrics:new_spiral(Name), %% last 60 sec
            ets:insert(metrics, {Name, 1});
        _ -> true
    end,
    folsom_metrics:notify({Name, 1}).

-spec notify_throughput_message(IO::atom(), Type :: atom()) ->
    ok | {error, Name :: atom(), nonexistent_metric} |
    {error, Type :: atom(), unsupported_metric_type}.

notify_throughput_message(IO, Type) ->
    Name = concat("message_throughput_", concat(IO, concat("_", Type))),
    case ets:member(metrics, Name) of 
        false ->
            folsom_metrics:new_spiral(Name), %% last 60 sec
            ets:insert(metrics, {Name, 1});
        _ -> true
    end,
    folsom_metrics:notify({Name, 1}).

-spec notify_throughput_iq(IO::atom(), Type :: atom(), NS :: atom()) ->
    ok | {error, Name :: atom(), nonexistent_metric} |
    {error, Type :: atom(), unsupported_metric_type}.

notify_throughput_iq(IO, Type, NS) ->
    Name = concat("iq_throughput_", concat(IO, concat("_", concat(concat(Type, "_"), NS)))),
    case ets:member(metrics, Name) of
        false ->
            folsom_metrics:new_spiral(Name), %% last 60 sec
            ets:insert(metrics, {Name, 1});
        _ -> true
    end,
    folsom_metrics:notify({Name, 1}).

-spec set_iq_time(Id :: binary(), Type :: atom(), NS :: atom()) -> boolean().

set_iq_time(Id, Type, NS) ->
    ets:insert(response_time, {Id, {os:timestamp(), concat(concat(Type, "_"), NS)}}).

-spec notify_resp_time(Id :: binary()) ->
    ok | {error, Name :: atom(), nonexistent_metric} |
    {error, Type :: atom(), unsupported_metric_type}.

notify_resp_time(Id) ->               
    case ets:lookup(response_time, Id) of
        [{_, {Time, Mname}}] ->
            Name = concat("response_time_", Mname),
            case ets:member(metrics, Name) of
                false ->
                    folsom_metrics:new_histogram(Name, slide, 60), %%TODO need configure time
                    ets:insert(metrics, {Name, 1});
                _ -> true
            end,
            Diff = timer:now_diff(now(), Time)/1000000, %%seconds
            folsom_metrics:notify({Name, Diff});
        _ -> ok
    end.

-spec notify_dropped_presence(Type :: atom()) ->
    ok | {error, Name :: atom(), nonexistent_metric} |
    {error, Type :: atom(), unsupported_metric_type}.

notify_dropped_presence(Type) ->
    Name = concat("presence_dropped_", Type),
    case ets:member(metrics, Name) of
        false ->
            folsom_metrics:new_spiral(Name), %% last 60 sec
            ets:insert(metrics, {Name, 1});
        _ -> true
    end,
    folsom_metrics:notify({Name, 1}).

-spec notify_dropped_message(Type :: atom()) ->
    ok | {error, Name :: atom(), nonexistent_metric} |
    {error, Type :: atom(), unsupported_metric_type}.

notify_dropped_message(Type) ->
    Name = concat("message_dropped_", Type),
    case ets:member(metrics, Name) of
        false ->
            folsom_metrics:new_spiral(Name), %% last 60 sec
            ets:insert(metrics, {Name, 1});
        _ -> true
    end,
    folsom_metrics:notify({Name, 1}).

-spec notify_dropped_iq(Type :: atom(), NS :: atom()) ->
    ok | {error, Name :: atom(), nonexistent_metric} |
    {error, Type :: atom(), unsupported_metric_type}.

notify_dropped_iq(Type, NS) ->
    Name = concat("iq_dropped_", concat(concat(Type, "_"), NS)),
    case ets:member(metrics, Name) of
        false ->
            folsom_metrics:new_spiral(Name), %% last 60 sec
            ets:insert(metrics, {Name, 1});
        _ -> true
    end,
    folsom_metrics:notify({Name, 1}).

-spec concat(S :: string() | atom(), A :: string() | atom()) -> atom().

concat(S, A) when is_list(S) andalso is_list(A) ->
    erlang:list_to_atom(S ++ A);
concat(S, A) when is_list(S) andalso is_atom(A) ->
    erlang:list_to_atom(S ++ erlang:atom_to_list(A));
concat(S, A) when is_atom(S) andalso is_atom(A) ->
    erlang:list_to_atom(erlang:atom_to_list(S) ++ erlang:atom_to_list(A));
concat(S, A) when is_atom(S) andalso is_list(A) ->
    erlang:list_to_atom(erlang:atom_to_list(S) ++ A).

