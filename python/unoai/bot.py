#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from telethon import TelegramClient, events
import re
import logging
import time
import sys
from random import randint, choice as random_choice
from telethon.tl.functions.messages import GetInlineBotResultsRequest, SendInlineBotResultRequest, SendMessageRequest, SetTypingRequest
from telethon.tl.types import PeerUser, SendMessageTypingAction, SendMessageCancelAction
from game import Game, debug_print
from telethon.errors.rpc_base_errors import RPCError
import schedule

game = Game()


from config import api_id, api_hash, PHONE, session_name, game_autostart

SAFE_MODE = False
#game_autostart = True
at_times = ("9:00", "12:00", "16:00", "18:00", "19:00", "20:00", "21:30")

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

client = TelegramClient(session_name, api_id, api_hash, update_workers=1, spawn_read_thread=False, use_ipv6=False)
while not client.start(phone=PHONE):
    logger.info("Start failed. Retrying...")
    time.sleep(5)
logger.info("Started!")

my_username = client.get_me().username
my_firstname = client.get_me().first_name
unobot_username = 'unounofficialbot'
unogroup_chatname = 'playuno'
unobot = client.get_entity(unobot_username)
unochat = client.get_entity(unogroup_chatname)


def startgame_task():
    logger.info("startgame_task run")
    if not game.is_playing:
        client(SendMessageRequest(unochat, "/new@{}".format(unobot_username)))
        time.sleep(60)
        game.delay = 8
        #try starting the game
        client(SendMessageRequest(unochat, "/start@{}".format(unobot_username)))
        logger.info("startgame_task game started")

def task_run():
    logger.info("Thread task_run started")
    while True:
        schedule.run_pending()
        time.sleep(60)

def inline_query():
    try:
        client(SetTypingRequest(
            peer = unochat,
            action = SendMessageTypingAction()
        ))
    except Exception as err:
        print(err)
    for tries in range(10):
        try:
            bot_results = client(GetInlineBotResultsRequest(
                unobot, unochat, '', ''
            ))
        except RPCError:
            time.sleep(1)
        else:
            break
    if bot_results.results:
        query_id = bot_results.query_id
        for result in bot_results.results:
            try:
                (result_id, anti_cheat) = result.id.split(':')
            except ValueError:
                inline_query()
                return
            game.add_card(result_id, anti_cheat)
        str_id = game.play_card()
        #if str_id:
            #client(SendMessageRequest(unochat, str_id))
        #else:
        if not str_id:
            str_id = 'draw'
            client(SendMessageRequest(unochat, 'Error: No card can be played.'))
            debug_print([
                game.deck,
                game.special,
                game.functional,
                game.choose_color
            ])
        for tries in range(6):
            try:
                client(SendInlineBotResultRequest(
                    unochat,
                    query_id,
                    "{}:{}".format(str_id, game.anti_cheat)
                ))
            except Exception as err:
                logger.critical('Exception: {}'.format(err))
                #client(SendMessageRequest(unochat, 'Exception: {}'.format(err)))
            else:
                break
        try:
            client(SetTypingRequest(
                peer = unochat,
                action = SendMessageCancelAction()
            ))
        except Exception as err:
            print(err)
        game.clear_deck()
        return True
    else:
        print(bot_results)
    return None


def safety_check(chat_id, force=False):
    if SAFE_MODE or force:
        safe_ids = [-1000000, -1000001]
        if chat_id in safe_ids:
            return True
        else:
            return False
    else:
        return True

def commandify(text, my_commands=True, wild_card=True):
    args = text.split()
    if not args:
        return [None]
    match = re.match(r'/([^@]+$)', args[0])
    if match:
        command = match.group(1)
        if not wild_card:
            return [None]
        username = my_username
        args = args[1:]
        return [command, username, args]
    else:
        match = re.match(r'/([^@]+)@([^@]+)$', args[0])
        if match:
            username = match.group(2)
            command = match.group(1)
            args = args[1:]
            if username != my_username and my_commands == True:
                return [None]
            else:
                return [command, username, args]
        else:
            return [None]

def get_peer_id(peer):
    id = getattr(peer, "channel_id", None)
    if id:
        id = int('-100{}'.format(id))
    else:
        id = getattr(peer, "user_id", None)
    if not id:
        id = getattr(peer, "chat_id")
        assert id
        id = int('-100{}'.format(id))
    return id


class EmptyChat:
    def __init__(self, title=None):
        self.title = title

class EmptyUser:
    def __init__(self, first_name="None", last_name=None, username=None):
        self.first_name = first_name
        self.last_name = last_name
        self.username = username

def display_username(user, atuser=False, shorten=False):
    if user.first_name and user.last_name:
        name = "{} {}".format(user.first_name, user.last_name)
    else:
        name = user.first_name
    if shorten:
        return name
    if user.username:
        if atuser:
            name += " (@{})".format(user.username)
        else:
            name += " ({})".format(user.username)
    return name


max_items = 1000
cached_ids = list()
cached_entity = list()
def mwt_get_entity(entity_type, client, id, retry=0):
    global max_items, cached_ids, cached_entity
    def get(unique_id):
        global cached_ids, cached_entity
        try:
            my_index = cached_ids.index(unique_id)
            entity = cached_entity[my_index]
            return entity
        except ValueError:
            return None
    def store(unique_id, entity):
        global cached_ids, cached_entity
        cached_ids.append(unique_id)
        cached_entity.append(entity)

    while len(cached_ids) > max_items:
        cached_ids.pop(0)
        cached_entity.pop(0)

    try:
        if entity_type == 'group':
            unique_id = get_peer_id(id)
            entity = get(unique_id)
            #print("cache")
            if not entity:
                #print("new")
                entity = client.get_entity(id)
        elif entity_type == 'user':
            unique_id = id
            entity = get(unique_id)
            #print("cache")
            if not entity:
                #print("new")
                entity = client.get_entity(PeerUser(user_id=id))
        else:
            return None
        store(unique_id, entity)
        return entity
    except (ValueError, KeyError) as err:
        if retry < 1:
            retry += 1
            if entity_type == 'group':
                sys.stdout.write("[Retry in 1s] Error while getting chat: {}".format(err))
                sys.stdout.flush()
            elif entity_type == 'user':
                sys.stdout.write("[Retry in 1s] Error while getting user: {}".format(err))
                sys.stdout.flush()
            time.sleep(1)
            entity = mwt_get_entity(entity_type, client, id, retry=retry)
            store(unique_id, entity)
            return entity
        else:
            if entity_type == 'group':
                sys.stdout.write("[Give up] Error while getting chat: {}".format(err))
                sys.stdout.flush()
                entity = EmptyChat(str(id))
            elif entity_type == 'user':
                sys.stdout.write("[Give up] Error while getting user: {}".format(err))
                sys.stdout.flush()
                entity = EmptyUser(first_name="PeerUser(user_id={})".format(id))
            store(unique_id, entity)
            return entity


def get_full_info(event):
    if event.is_channel:
        channel = mwt_get_entity('group', client, event.message.to_id)
        user = mwt_get_entity('user', client, event.message.from_id)
        full_info = ['Channel', channel, user]
    elif event.is_group:
        group = mwt_get_entity('group', client, event.message.to_id)
        user = mwt_get_entity('user', client, event.message.from_id)
        full_info = ['Group', group, user]
    elif event.is_private:
        user = mwt_get_entity('user', client, event.message.from_id)
        full_info = ['User', EmptyChat(), user]
    else:
        return None

    return full_info



@client.on(events.NewMessage)
def new_msg_handler(event):
    global unochat
    #print(event)
    #sys.stdout.flush()
    full_info = get_full_info(event)
    msg = event.message
    if msg.message and (not msg.media):
        # Text handler
        logger.info("{} - {} - {}: {}".format(full_info[0], full_info[1].title, display_username(full_info[2]), msg.message))
        if not safety_check(get_peer_id(msg.to_id)):
            return
        c = commandify(event.raw_text, wild_card=False)
        if c[0]:
            if c[0] == 'hello':
                event.reply('hi!')
            if c[0] in ['startgame', 'start', 'join'] and full_info[0] == "Channel":
                if game.is_playing:
                    event.reply("I'm playing right now.")
                else:
                    unochat = msg.to_id
                    game.join_game(unochat)
                    client(SendMessageRequest(unochat, "/join@{}".format(unobot_username)))
            elif c[0] in ['stopgame', 'stop', 'leave'] and full_info[0] == "Channel":
                if game.is_playing:
                    game.leave_game(unochat)
                    game.stop_game()
                    client(SendMessageRequest(unochat, "/leave@{}".format(unobot_username)))
                elif game.joined and unochat in game.joined:
                    game.leave_game(unochat)
                    client(SendMessageRequest(unochat, "/leave@{}".format(unobot_username)))
                else:
                    event.reply("I'm not playing right now.")
            elif c[0] in ['wait', 'delay'] and full_info[0] == "Channel":
                if game.delay or (not game.is_playing):
                    event.reply("Nothing to do.")
                else:
                    game.delay = 8
                    event.reply("OK. {} seconds of delay has been set.".format(game.delay))
            elif c[0] in ['nowait', 'nodelay'] and full_info[0] == "Channel":
                if game.delay and game.is_playing:
                    myreply = "OK. {} seconds of delay has been removed.".format(game.delay)
                    game.delay = None
                    event.reply(myreply)
                else:
                    event.reply("Nothing to do.")
            return

        if full_info[2].username and full_info[2].username == unobot_username:
            if re.search("(@{})".format(my_username), msg.message):
                inline_query()
            elif re.search(r'Game ended', msg.message):
                if game.is_playing:
                    game.clear_deck()
                    game.leave_game(unochat)
                    game.stop_game()
            elif re.search(r'Created a new game!|on_game_created', msg.message):
                if not game.is_playing:
                    unochat = msg.to_id
                    game.join_game(unochat)
                    client(SendMessageRequest(unochat, "/join@{}".format(unobot_username)))
            elif re.search(r'First player:', msg.message):
                if not game.is_playing:
                    unochat = msg.to_id
                    if unochat in game.joined:
                        game.start_game()
                    else:
                        client(SendMessageRequest(unochat, "/leave@{}".format(unobot_username)))
            elif re.search("{} won!".format(my_firstname), msg.message):
                if game.is_playing:
                    game.clear_deck()
                    game.leave_game(unochat)
                    game.stop_game()

    elif msg.media:
        # Has media, interesting.
        media = msg.media
        type = None
        if hasattr(media, 'photo'):
            type = "photo"
            logger.info("{} - {} - {}: [Photo]".format(full_info[0], full_info[1].title, display_username(full_info[2])))
        elif hasattr(media, 'document'):
            try:
                if hasattr(media.document.attributes[1], 'stickerset'):
                    type = "Sticker"
                    logger.info("{} - {} - {}: [Sticker]:{}".format(full_info[0], full_info[1].title, display_username(full_info[2]), media.document.attributes[1].alt))
                else:
                    type = "Document (file)"
                    logger.info("{} - {} - {}: [Document (file)]".format(full_info[0], full_info[1].title, display_username(full_info[2])))
            except (AttributeError, IndexError):
                type = "Document"
                logger.info("{} - {} - {}: [Document]".format(full_info[0], full_info[1].title, display_username(full_info[2])))
        else:
            type = "Unknown media"
            logger.info("{} - {} - {}: [Unknown media]".format(full_info[0], full_info[1].title, display_username(full_info[2])))
        logger.debug("Media Type: {}".format(type))
    # Handler complete


if game_autostart:
    for at_time in at_times:
        schedule.every().day.at(at_time).do(startgame_task)
    from threading import Thread
    Thread(target=task_run, args=()).start()

client.idle()