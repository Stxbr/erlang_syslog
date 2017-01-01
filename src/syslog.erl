%% Copyright (c) 2010 Jacob Vorreuter <jacob.vorreuter@gmail.com>
%%
%% Permission is hereby granted, free of charge, to any person
%% obtaining a copy of this software and associated documentation
%% files (the "Software"), to deal in the Software without
%% restriction, including without limitation the rights to use,
%% copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the
%% Software is furnished to do so, subject to the following
%% conditions:
%%
%% The above copyright notice and this permission notice shall be
%% included in all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
%% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
%% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
%% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
%% HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
%% WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
%% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
%% OTHER DEALINGS IN THE SOFTWARE.

%% http://www.faqs.org/rfcs/rfc3164.html
-module(syslog).
-behaviour(gen_server).

%%-include_lib("ejabberd/include/ejabberd.hrl").


%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2,
         handle_info/2, terminate/2, code_change/3, timestamp/0]).

%% api callbacks
-export([
    start_link/0,
    %%send/3,
    %%send/4,
    send/7,
    settings/3
]).

-record(state, {socket, address, port, facility}).

%%====================================================================
%% api callbacks
%%====================================================================
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%send(Who, Level, Msg) when is_atom(Who), is_atom(Level), is_list(Msg) ->
%%    gen_server:cast(?MODULE, {send, Who, Level, Msg}).

%%send(Facility, Who, Level, Msg) when is_integer(Facility), is_atom(Who), is_atom(Level), is_list(Msg) ->
%%    gen_server:cast(?MODULE, {send, Facility, Who, Level, Msg}).

send(Module, Pid, Line, Who, Level, Msg, Args)
%%        when is_integer(Line), is_atom(Who), is_atom(Level), is_list(Msg) ->
    ->
    %%?INFO_MSG("send ~p", [Module, Pid, Line, Who, Level, Msg]),
    %%ejabberd_logger:debug_msg(?MODULE,?LINE,"syslog send ~p", [Module, Pid, Line, Who, Level, Msg]),
    gen_server:cast(?MODULE, {send, Module, Pid, Line, Who, Level, io_lib:format(Msg, Args)}).

settings(Ip, Port, Facility) ->
    application:set_env(?MODULE, ip, Ip),
    application:set_env(?MODULE, port, Port),
    application:set_env(?MODULE, facility, Facility),
    ok.

%%====================================================================
%% gen_server callbacks
%%====================================================================

%%--------------------------------------------------------------------
%% Function: init(Args) -> {ok, State} |
%%                         {ok, State, Timeout} |
%%                         ignore               |
%%                         {stop, Reason}
%% Description: Initiates the server
%%--------------------------------------------------------------------
init([]) ->
    case gen_udp:open(0) of
        {ok, Socket} ->
            %%ejabberd_logger:debug_msg(?MODULE,?LINE,"syslog start ~p", []),
            ok = settings({127,0,0,1}, 514, user),
            {ok, Hostname} = inet:gethostname(),
            {ok, #state{
                    socket = Socket,
                    address = Hostname,
                    port = 514,
                    facility = atom_to_facility(user)
            }};
        {error, Reason} -> {stop, Reason}
    end.

%%--------------------------------------------------------------------
%% Function: %% handle_call(Request, From, State) -> {reply, Reply, State} |
%%                                      {reply, Reply, State, Timeout} |
%%                                      {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, Reply, State} |
%%                                      {stop, Reason, State}
%% Description: Handling call messages
%%--------------------------------------------------------------------
handle_call(_Msg, _From, State) ->
    {reply, ok, State}.

%%--------------------------------------------------------------------
%% Function: handle_cast(Msg, State) -> {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, State}
%% Description: Handling cast messages
%%--------------------------------------------------------------------
%%handle_cast({send, Who, Level, Msg}, State) ->
%%    handle_cast({send, 0, Who, Level, Msg}, State);

handle_cast({send, Module, Pid, Line, Who, Level, Msg}, State) ->
    {ok, Hostname} = inet:gethostname(),
    %%State#state.facility
    {ok, Facility} = application:get_env(facility),
    Packet = [io_lib:format("<~B>", [(atom_to_facility(Facility) bor atom_to_level(Level))]),
        timestamp(), " ", Hostname, " ",
        atom_to_list(Who), "/", Module,
        io_lib:format("[~p]: ~p: ", [Pid, Line]),
        Msg, "\n"],
    do_send(State, Packet),
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}
%% Description: Handling all non call/cast messages
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: terminate(Reason, State) -> void()
%% Description: This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
%% Description: Convert process state when code is changed
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------
do_send(#state{socket=Socket}, Packet) ->
    {ok, IP} = application:get_env(ip),
    {ok, Port} = application:get_env(port),
    gen_udp:send(Socket, IP, Port, Packet).

atom_to_level(emergency) -> 0; % system is unusable
atom_to_level(alert) -> 1; % action must be taken immediately
atom_to_level(critical) -> 2; % critical conditions
atom_to_level(error) -> 3; % error conditions
atom_to_level(warning) -> 4; % warning conditions
atom_to_level(notice) -> 5; % normal but significant condition
atom_to_level(info) -> 6; % informational
atom_to_level(debug) -> 7. % debug-level messages

atom_to_facility(kernel)    -> 0;
atom_to_facility(user)      -> 8;
atom_to_facility(mail)      -> 16;
atom_to_facility(system)    -> 24;
atom_to_facility(security)  -> 32;
atom_to_facility(syslogd)   -> 40;
atom_to_facility(printer)   -> 48;
atom_to_facility(nntp)      -> 56;
atom_to_facility(uucp)      -> 64;
atom_to_facility(clock)     -> 72;
atom_to_facility(security2) -> 80;
atom_to_facility(ftp)       -> 88;
atom_to_facility(ntp)       -> 96;
atom_to_facility(audit)     -> 104;
atom_to_facility(alert)     -> 112;
atom_to_facility(clock2)    -> 120;
atom_to_facility(local0)    -> 128;
atom_to_facility(local1)    -> 136;
atom_to_facility(local2)    -> 144;
atom_to_facility(local3)    -> 152;
atom_to_facility(local4)    -> 160;
atom_to_facility(local5)    -> 168;
atom_to_facility(local6)    -> 176;
atom_to_facility(local7)    -> 184.

timestamp() ->
	{{_Year,Month,Day},{Hour,Min,Sec}} = erlang:localtime(),
	M = case Month of
		1 -> "Jan";
		2 -> "Feb";
		3 -> "Mar";
		4 -> "Apr";
		5 -> "May";
		6 -> "Jun";
		7 -> "Jul";
		8 -> "Aug";
		9 -> "Sep";
		10-> "Oct";
		11-> "Nov";
		12-> "Dec"
	end,
	io_lib:format("~s ~2.10.0B ~2.10.0B:~2.10.0B:~2.10.0B",
	        [M, Day, Hour, Min, Sec]).
