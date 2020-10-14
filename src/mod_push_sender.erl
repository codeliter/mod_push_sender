-module(mod_push_sender).
-author('hackzlord@gmail.com').

-behaviour(gen_mod).

%% Required by ?INFO_MSG macros
-include("logger.hrl").

%% Required by ?T macro
-include("translate.hrl").
-include("ejabberd_http.hrl").

%% gen_mod API callbacks
-export([start/2, stop/1, depends/2, mod_options/1]).

start(_Host, _Opts) ->
    ?INFO_MSG("Starting mod_push_sender!", []),
    ejabberd_hooks:add(offline_message_hook, _Host, ?MODULE, push_message, 50).
    ok.

stop(_Host) ->
    ?INFO_MSG("Have a great time from mod_push_sender!", []),
    ejabberd_hooks:delete(offline_message_hook, _Host, ?MODULE, push_message, 50).
    ok.

depends(_Host, _Opts) ->
    [].

push_message(_From, _To, Packet) ->
    MessageId = xml:get_tag_attr_s(list_to_binary("id"), Packet),
    MessageType = xml:get_tag_attr_s(list_to_binary("type"), Packet),
    FromS = _From#jid.luser,
    ToS = _To#jid.luser,
    Body = xml:get_path_s(Packet, [{elem, list_to_binary("body")}, cdata]),

    if (MessageType == <<"groupchat">>) and (Body /= <<"">>) ->
    		push_offline_message(FromS, ToS, Body, MessageType, MessageId)
    if (MessageType == <<"chat">>) and (Body /= <<"">>) ->
    		push_offline_message(FromS, ToS, Body, MessageType, MessageId)
    	ok.

push_offline_message(From, To, Body, MessageType, MessageId) ->
    Token = gen_mod:get_opt(token, fun(S) ->econf:string() ok, ""),
    PostUrl = gen_mod:get_module_opt(post_url, fun(S) -> econf:string() ok, ""),

	Sep = "&",
	Post = [
		"from=", From, Sep,
		"to=", To, Sep,
		"body=", binary_to_list(Body), Sep,
		"message_id=", binary_to_list(MessageId), Sep,
		"message_type=", MessageType, Sep,
		"token=",Token
	],
	httpc:request(post, {PostUrl, [], "application/x-www-form-urlencoded", list_to_binary(Post)},[],[]),
    ok.