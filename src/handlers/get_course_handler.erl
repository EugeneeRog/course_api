-module(get_course_handler).

-export([
  init/2,
  create_rows/2
]).

-define(COURSE, "https://api.privatbank.ua/p24api/pubinfo?json&exchange&coursid=5" ).

init(Req0, State) ->
    Req = cowboy_req:reply(200,
        #{<<"content-type">> => <<"text/plain">>},
        get_course(check_ets()),
        Req0),
    {ok, Req, State}.

get_course(empty) -> 
    {ok, {{_, 200, "OK"}, _, Body}} = httpc:request(?COURSE),
    XML = create_xml(jsx:decode(list_to_binary(Body))),
    true = ets:insert_new(course, {main_course, XML}),
    spawn(fun() ->
        timer:sleep(60000),
        ets:delete(course, main_course)
        end),
    XML;
get_course({exist, Course}) ->
    Course;
get_course(error) -> <<"Server error">>.

check_ets() -> 
    case ets:lookup(course, main_course) of
        [] -> empty;
        [{main_course, Inf}] -> {exist, Inf};
        _ -> error
    end.

create_xml(Fields) ->
    Rows = create_rows(Fields, []),
    Data = {exchangerates, Rows},
    lists:flatten(xmerl:export_simple([Data], xmerl_xml)).

create_rows([], Acc) -> 
    erlang:display(Acc),
    Acc;
create_rows([Row | Rest], Acc) ->
    NewAcc = Acc ++ [{row, [{exchangerates, create_tags(Row), []}]}],
    create_rows(Rest, NewAcc).

create_tags(Row) ->
    [{ccy,maps:get(<<"ccy">>, Row)},
    {base_ccy,maps:get(<<"base_ccy">>, Row)},
    {buy,maps:get(<<"buy">>, Row)},
    {sale,maps:get(<<"sale">>, Row)}].