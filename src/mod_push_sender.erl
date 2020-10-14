%Original author: dev@codepond.org
-module(mod_push_sender).
-author("hackzlord@gmail.com").

-behaviour(gen_mod).

-export([start/2,
        stop/1,
        depends/2,
        mod_options/1,
        mod_opt_type/1,
        create_message/1,
        create_message/3,
        mod_doc/0]).

-ifndef(LAGER).
-define(LAGER, 1).
-endif.

-include("translate.hrl").
-include("logger.hrl").
-include("xmpp.hrl").

start(_Host, _Opt) ->
  ?INFO_MSG("mod_push_sender loading", []),
  inets:start(),
  ?INFO_MSG("HTTP client started", []),
  ejabberd_hooks:add(offline_message_hook, _Host, ?MODULE, create_message, 50).

stop (_Host) ->
  ?INFO_MSG("stopping mod_push_sender", []),
  ejabberd_hooks:delete(offline_message_hook, _Host, ?MODULE, create_message, 50).

depends(_Host, _Opts) ->
  [].

mod_options(_Host) ->
  [{token, <<"http://localhost">>},
  {post_url, <<"xx">>}].

mod_opt_type(token) ->
  fun iolist_to_binary/1;
mod_opt_type(post_url) ->
  fun iolist_to_binary/1.

mod_doc() ->
      #{desc =>
            ?T("This is for sending push to url.")}.

create_message({_Action, Packet} = Acc) when (Packet#message.type == chat) and (Packet#message.body /= []) ->
	[{text, _, Body}] = Packet#message.body,
	post_offline_message(Packet#message.from, Packet#message.to, Body, Packet#message.id),
  Acc;

create_message(Acc) ->
  Acc.

create_message(_From, _To, Packet) when (Packet#message.type == chat) and (Packet#message.body /= []) ->
  Body = fxml:get_path_s(Packet, [{elem, list_to_binary("body")}, cdata]),
  MessageId = fxml:get_tag_attr_s(list_to_binary("id"), Packet),
  post_offline_message(_From, _To, Body, MessageId),
  ok.

post_offline_message(From, To, Body, MessageId) ->
  ?INFO_MSG("Posting From ~p To ~p Body ~p ID ~p~n",[From, To, Body, MessageId]),
  Token = gen_mod:get_module_opt(To#jid.lserver, ?MODULE, token),
  PostUrl = gen_mod:get_module_opt(To#jid.lserver, ?MODULE, post_url),
  ToUser = To#jid.luser,
  FromUser = From#jid.luser,
  Vhost = To#jid.lserver,
  Data = string:join(["to=", binary_to_list(ToUser), "&from=", binary_to_list(FromUser), "&vhost=", binary_to_list(Vhost), "&body=", binary_to_list(Body), "&messageId=", binary_to_list(MessageId)], ""),
  Request = {binary_to_list(PostUrl), [{"Authorization", binary_to_list(Token)}, {"Logged-Out", "logged-out"}], "application/x-www-form-urlencoded", Data},
  httpc:request(post, Request,[],[]),
  ?INFO_MSG("post request sent", []).