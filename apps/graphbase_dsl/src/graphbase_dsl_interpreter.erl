%%%-------------------------------------------------------------------
%% @doc graphbase_dsl Interpreter module.
%% @end
%%%-------------------------------------------------------------------

-module(graphbase_dsl_interpreter).

%% API
-export([
    run/2
]).

%%====================================================================
%% API functions
%%====================================================================

run(User, AST) ->
    run(User, AST, dict:new(), dict:new()).

%%====================================================================
%% Internal functions
%%====================================================================

run(User, [Statement | Statements], Scope, Response) ->
    case run_statement(User, Statement, Scope, Response) of
        {ok, NewScope, NewResponse} -> run(User, Statements, NewScope, NewResponse);
        {error, Reason}             -> {error, {statement_error, Reason}}
    end;

run(_User, [], _Scope, Response) ->
    {ok, dict:to_list(Response)}.

%%--------------------------------------------------------------------
run_statement(User, {assign, Name, Value}, Scope, Response) ->
    case run_assign(User, Name, Value, Scope) of
        {ok, NewScope}  -> {ok, NewScope, Response};
        {error, Reason} -> {error, {assign_failed, Name, Reason}}
    end;

run_statement(User, {call, Function, Arguments}, Scope, Response) ->
    case graphbase_dsl_utils:call(User, Function, Arguments, Scope) of
        {ok, _}         -> {ok, Scope, Response};
        {error, Reason} -> {error, {call_failed, {Function, Arguments}, Reason}}
    end;

run_statement(_User, {yield, Name}, Scope, Response) ->
    {ok, Scope, run_yield(Name, Scope, Response)}.

%%--------------------------------------------------------------------
run_assign(_User, Name, {constant, Value}, Scope) ->
    {ok, dict:store(Name, Value, Scope)};

run_assign(User, Name, {call, Function, Arguments}, Scope) ->
    case graphbase_dsl_utils:call(User, Function, Arguments, Scope) of
        {ok, Value}     -> {ok, dict:store(Name, Value, Scope)};
        {error, Reason} -> {error, {call_failed, {Function, Arguments}, Reason}}
    end;

run_assign(_User, Name, {variable, VarName}, Scope) ->
    {ok, dict:store(Name, dict:fetch(VarName, Scope), Scope)}.

%%--------------------------------------------------------------------
run_yield(Name, Scope, Response) ->
    dict:store(Name, dict:fetch(Name, Scope), Response).
