-module(course_api_app).

-behaviour(application).

-export([start/2, stop/1]).

-define(COURSE_API, <<"/get/course">>).

start(_Type, _Args) ->
    course = ets:new(course, [named_table, public]),
    Dispatch = cowboy_router:compile([
        {'_', [{"/", get_course_handler, []}]}
    ]),
    {ok, _} = cowboy:start_clear(my_http_listener,
        [{port, 8080}],
        #{env => #{dispatch => Dispatch}}
    ),
    course_api_sup:start_link().

stop(_State) ->
    ok.