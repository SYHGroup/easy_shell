#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import telegram.ext as tg
from telegram import InlineQueryResultArticle, InputTextMessageContent, ParseMode, InlineKeyboardMarkup, InlineKeyboardButton
import logging
import re, time

import urllib.request
import subprocess
import json
import socket

from hashlib import md5 as hashlib_md5
from random import seed as random_seed, choice as random_choice
from telegram.error import TelegramError


logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

updater = tg.Updater('token_here')
forward_list = [-1000000000000, -1000000000000]
forward_mode = 0 #off, one-awy, two-way

blacklist = [-1000000000000, ]

cached_message_id_table = [dict(), dict()]

spammers = dict()
class Spam:
    def __init__(self, user_id, chat_id, msg_type):
        self.user_id = user_id
        self.chat_id = chat_id
        self.msg_type = msg_type
        self.send_time = int(time.time())
class Spammer:
    def __init__(self, user_id):
        self.user_id = user_id
        self.pool=list()
        self.pool2=list()
        self.last_spam_time=None
    def add(self, spam):
        self.pool.append(spam)
        while (60*5 + self.pool[0].send_time) <= int(time.time()):
            del self.pool[0]
        self.pool2=self.pool
        if len(self.pool2):
            while (30 + self.pool2[0].send_time) <= int(time.time()):
                del self.pool2[0]
    @staticmethod
    def dict_add(chat_id, target):
        if target.get(chat_id):
            target[chat_id] += 1
        else:
            target[chat_id] = 1
        return target
    def is_spamming(self, poolname, times):
        sticker_count=dict()
        atme_count=dict()
        for spam in eval("self." + poolname):
            if spam.msg_type == "sticker":
                sticker_count = self.dict_add(spam.chat_id, sticker_count)
            elif spam.msg_type == "atme":
                atme_count = self.dict_add(spam.chat_id, atme_count)
        for target in [sticker_count, atme_count]:
            if not len(target):
                pass
            elif max([target[k] for k in target]) >= times:
                return True
        return False
def print_text(update_msg, additional_tag=""):
    if update_msg.chat.type == "private":
        print(additional_tag + update_msg.chat.username + ": " + update_msg.text)
    else:
        print(additional_tag + update_msg.chat.title + " - " + display_username(update_msg.from_user, atuser=True) + ": " + update_msg.text)

def print_sticker(update_msg):
    if update_msg.chat.type == "private":
        print(update_msg.chat.username + ": Sticker[" + update_msg.sticker.file_id + "]")
    else:
        print(update_msg.chat.title + " - " + display_username(update_msg.from_user, atuser=True) + ": Sticker[" + update_msg.sticker.file_id + "]")

def spam_detector(msg, msg_type):
    chat_id=msg.chat_id
    user_id=msg.from_user.id
    global spammers
    if not spammers.get(user_id):
        spammers[user_id]=Spammer(user_id)
    spamuser=spammers[user_id]
    spamuser.add(Spam(user_id, chat_id, msg_type))
    #print(str(len(spamuser.pool)) + " " + str(len(spamuser.pool2)))
    if spamuser.last_spam_time and (int(time.time()) - spamuser.last_spam_time) < 10*60:
        spamuser.last_spam_time = int(time.time())
        del spamuser.pool2
        return True
    if spamuser.is_spamming("pool", 5) or spamuser.is_spamming("pool2", 2):
        spamuser.last_spam_time = int(time.time())
        msg.reply_text('#SPAM')
        del spamuser.pool2
        return True
    else:
        del spamuser.pool2
        return False



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
def start(bot, update):
    update.message.reply_text('Hello {}, this is jerrybot.'.format(update.message.from_user.first_name))
    logger.debug("Start from " + str(update.message.from_user.id))
def hello(bot, update):
    update.message.reply_text('Hello {}.'.format(update.message.from_user.first_name))
    logger.debug("Hello from " + str(update.message.from_user.id))
def chatinfo(bot, update):
    chat = update.message.chat
    chat_id = update.message.chat.id
#    user = update.message.from_user
    buttons = []
    buttons.append([InlineKeyboardButton(text="详细信息", callback_data="chatinfo new")])
    if chat.type != "private":
        buttons.append([InlineKeyboardButton(text="邀请链接", callback_data="link")])
        buttons.append([InlineKeyboardButton(text="管理员", callback_data="listadmins get")])
    buttons.append([InlineKeyboardButton(text="删除", callback_data="chatinfo delete")])
    bot.send_message(chat_id=chat_id, text="请选择:", reply_to_message_id=update.message.message_id, reply_markup=InlineKeyboardMarkup(buttons))
#
#    if update.message.reply_to_message:
#        print(update.message.reply_to_message.from_user.first_name)
#

    logger.info("Chatinfo selector from {}".format(update.message.from_user.id))
def handle_chatinfo_click(bot, update):
    chat = update.callback_query.message.chat
    user = update.callback_query.from_user
    message_id = update.callback_query.message.message_id
    data = update.callback_query.data
    result = ''
    if chat.type == "private":
        items = ["chat"]
    else:
        items = ["chat", "user"]
    for item in items:
        result += "Information about the {}:\n".format(item)
#        for identity in ['id', 'type', 'title', 'username', 'first_name', 'last_name', 'description', 'invite_link']:
        for identity in ['id', 'type', 'title', 'username', 'first_name', 'last_name']:
            try:
                info=getattr(eval(item), identity)
            except AttributeError:
                continue
            if info:
                result="{0}{1}: {2}\n".format(result, identity, info)
        result += "\n"
    if chat.type != "private":
        result += "Chat members count: {}".format(bot.get_chat_members_count(chat_id=chat.id))

    try:
        arg = re.match(r'chatinfo ([^ ]*)', data).group(1)
    except:
        arg = "new"
    if arg == "back":
        buttons = []
        buttons.append([InlineKeyboardButton(text="详细信息", callback_data="chatinfo new")])
        if chat.type != "private":
            buttons.append([InlineKeyboardButton(text="邀请链接", callback_data="link")])
            buttons.append([InlineKeyboardButton(text="管理员", callback_data="listadmins get")])
        buttons.append([InlineKeyboardButton(text="删除", callback_data="chatinfo delete")])
        bot.answer_callback_query(callback_query_id=update.callback_query.id)
        bot.edit_message_text(chat_id=chat.id, message_id=message_id, text="请选择:", reply_markup=InlineKeyboardMarkup(buttons))
    elif arg == "delete":
        bot.answer_callback_query(callback_query_id=update.callback_query.id)
        bot.delete_message(chat_id=chat.id, message_id=message_id)
    else:
        buttons = [[InlineKeyboardButton(text="返回", callback_data="chatinfo back")]]
        bot.answer_callback_query(callback_query_id=update.callback_query.id)
        bot.edit_message_text(chat_id=chat.id, message_id=message_id, text=result, reply_markup=InlineKeyboardMarkup(buttons))
#        bot.send_message(chat_id=chat.id, text=result)
    logger.info("Chatinfo click from {}".format(user.id))

def handle_link_click(bot, update):
    chat = update.callback_query.message.chat
    user = update.callback_query.from_user
    message_id = update.callback_query.message.message_id
#    data = update.callback_query.data

    msg = update.callback_query.message

    if chat.type == "private":
        return
    try:
        link = bot.export_chat_invite_link(chat_id=msg.chat.id)
    except TelegramError:
        buttons = [[InlineKeyboardButton(text="返回", callback_data="chatinfo back")]]
        bot.answer_callback_query(callback_query_id=update.callback_query.id)
        bot.edit_message_text(chat_id=chat.id, message_id=message_id, text="不能获得邀请链接，请检查机器人是否为管理员", reply_markup=InlineKeyboardMarkup(buttons))
#        bot.answer_callback_query(callback_query_id=update.callback_query.id, text="不能获得邀请链接")
    else:
        buttons = [[InlineKeyboardButton(text="返回", callback_data="chatinfo back")]]
        bot.answer_callback_query(callback_query_id=update.callback_query.id)
        bot.edit_message_text(chat_id=chat.id, message_id=message_id, text=link, reply_markup=InlineKeyboardMarkup(buttons))
#        bot.send_message(chat_id=msg.chat.id, text=link)
    logger.info("Export_link click from {}".format(user.id))

def handle_adminlist_click(bot, update):
    chat = update.callback_query.message.chat
    user = update.callback_query.from_user
    message_id = update.callback_query.message.message_id
    data = update.callback_query.data

    if chat.type == "private":
        return
    try:
        args = data.split()
    except:
        args = ["listadmins", "get"]
    if args[1] == "get":
        buttons = []
        chatmembers = bot.get_chat_administrators(chat_id=chat.id)
        if chatmembers and len(chatmembers) > 0:
            for chatmember in chatmembers:
                buttons.append([InlineKeyboardButton(text=display_username(chatmember.user, atuser=False, shorten=True), callback_data="listadmins display {}".format(chatmember.user.id))])
            buttons.append([InlineKeyboardButton(text="返回", callback_data="chatinfo back")])
            bot.answer_callback_query(callback_query_id=update.callback_query.id)
            bot.edit_message_text(chat_id=chat.id, message_id=message_id, text="管理员列表({}):".format(len(chatmembers)), reply_markup=InlineKeyboardMarkup(buttons))
        else:
            buttons = [[InlineKeyboardButton(text="返回", callback_data="chatinfo back")]]
            bot.answer_callback_query(callback_query_id=update.callback_query.id)
            bot.edit_message_text(chat_id=chat.id, message_id=message_id, text="无法获得管理员列表", reply_markup=InlineKeyboardMarkup(buttons))
    elif args[1] == "display":
        buttons = []
        buttons.append([InlineKeyboardButton(text="返回", callback_data="listadmins get")])
        buttons.append([InlineKeyboardButton(text="退出", callback_data="chatinfo back")])
        result = ""
        try:
            chatmember = bot.get_chat_member(chat_id=chat.id, user_id=args[2])
        except TelegramError:
            bot.edit_message_text(chat_id=chat.id, message_id=message_id, text="这个人不见了", reply_markup=InlineKeyboardMarkup(buttons))
        else:
            result = "{} 的详细信息:\n".format(display_username(chatmember.user, atuser=False))
            for identity in ['id', 'type', 'title', 'username', 'first_name', 'last_name']:
                try:
                    info=getattr(chatmember.user, identity)
                except AttributeError:
                    continue
                if info:
                    result="{0}{1}: {2}\n".format(result, identity, info)
            result += "\n权限信息:\n"
            identities = ['status', 'can_change_info', 'can_delete_messages', 'can_invite_users', 'can_restrict_members', 'can_pin_messages', 'can_promote_members']
            if chat.type == "channel":
                identities = identities + ['can_post_messages', 'can_edit_messages']
            for identity in identities:
                try:
                    info=getattr(chatmember, identity)
                except AttributeError:
                    continue
                if info:
                    result="{0}{1}: {2}\n".format(result, identity, info)
            bot.edit_message_text(chat_id=chat.id, message_id=message_id, text=result, reply_markup=InlineKeyboardMarkup(buttons))

    logger.info("Listadmins click from {}".format(user.id))

#def text_handler_private(bot, update):
#    text_handler(bot, update)
def edited_text_handler(bot, msg, group_id):
    #bot.edit_message_text()
    message_rawcontent=msg.text
    #dict_repl={"\\": "\\\\", "`": "\\`", "_": "\\_", "*": "\\*", "(": "\\(", ")": "\\)"}
    dict_repl={"\\": "\\\\", "_": "\\_", "*": "\\*"}
    for (pattern, repl) in dict_repl.items():
        message_rawcontent=message_rawcontent.replace(pattern, repl)
    #print("get_id: " + str(get_message_id(msg.message_id)))
    bot.send_message(chat_id=forward_list[1 - group_id], text="_{}编辑了消息_\n".format(display_username(msg.from_user, shorten=True)) + message_rawcontent, parse_mode=ParseMode.MARKDOWN, reply_to_message_id=get_message_id(msg.message_id, group_id))
def text_handler(bot, update):
    if update.edited_message:
        msg=update.edited_message
        print_text(msg, additional_tag="[Edited] ")
        if msg.chat.id == forward_list[0]:
            if forward_mode != 0:
                edited_text_handler(bot, msg, 0)
        elif msg.chat.id == forward_list[1]:
            if forward_mode == 2:
                edited_text_handler(bot, msg, 1)
        return
    elif update.edited_channel_post:
        logger.info("Edited_channel_post received.")
        return

    msg=update.message
    print_text(msg)
    if msg.chat.id not in blacklist:
        if re.search(r"@JerryXiao".lower(), msg.text.lower()) and msg.from_user.username != "JerryXiao":
            if not spam_detector(msg, "atme"):
                msg.reply_text('啧啧')
    forward_message(bot, update)

def sticker_handler(bot, update):
    msg=update.message
    print_sticker(msg)
    if msg.chat.id not in blacklist:
        #if msg.sticker.file_id in ["CAADAQADTgAD8UnJAoc8V3I9a2fWAg"]:
        if msg.sticker.file_id in ["CAADAQADOgAD8UnJAgkqNQxCY_cBAg", "CAADAQADTgAD8UnJAoc8V3I9a2fWAg"]:
            if not spam_detector(msg, "sticker"):
                bot.send_sticker(msg.chat_id, "CAADAQADQQAD8UnJAtvnuNiSIsT5Ag")
                #bot.send_sticker(msg.chat_id, "CAADBQADXgADbxmwBql8Snpn6Jm1Ag")
    forward_message(bot, update, True)


def forward_mode_changer(bot, update, args):
    msg=update.message
    if msg.chat.id not in forward_list:
        msg.reply_text('Permission denied.')
        return
    global forward_mode
    if len(args) != 0 and args[0] in ["0", "1", "2"]:
        forward_mode = int(args[0])
        bot.send_message(chat_id=msg.chat_id, text="转发模式:{}".format(forward_mode))
    else:
        bot.send_message(chat_id=msg.chat_id, text="当前转发模式:{}\n转发模式0:关闭转发\n转发模式1:单向转发(小群向大群)\n转发模式2:双向转发".format(forward_mode))
    logger.info("Forward mode was changed to {} by {} in {}".format(forward_mode, msg.from_user.id, msg.chat.id))


def forward_message(bot, update, send_detailed_info=False):
    msg=update.message

    if (msg.forward_from and msg.forward_from.id != msg.from_user.id) or msg.forward_from_chat:
        send_detailed_info=True
        info="转发人: "
    else:
        info="转发自: "
    if forward_mode == 0:
        return

    additional_text=""
    reply_to_id=None
    if send_detailed_info:
        username_human=display_username(msg.from_user)
    if msg.reply_to_message:
        reply_to_id=get_message_id(msg.reply_to_message.message_id, 0)
        if send_detailed_info:
            additional_text=" 回复的消息"
        else:
            send_detailed_info=True
            info="回复的消息"
            username_human=""

    if msg.chat.id == forward_list[0]:
        if send_detailed_info:
            bot.send_message(chat_id=forward_list[1], text="🔻{}{}🔻{}".format(info, username_human, additional_text), disable_notification=True, reply_to_message_id=reply_to_id)
        sent_message=bot.forward_message(chat_id=forward_list[1], from_chat_id=forward_list[0], message_id=msg.message_id, disable_notification=True)
        forwarded_id=sent_message.message_id
        del sent_message
        store_message_id(msg.message_id, forwarded_id, 0)

    if msg.chat.id == forward_list[1]:
        if forward_mode == 2:
            if msg.reply_to_message:
                reply_to_id=get_message_id(msg.reply_to_message.message_id, 1)
            else:
                reply_to_id=None
            if send_detailed_info:
                bot.send_message(chat_id=forward_list[0], text="🔻{}{}🔻{}".format(info, username_human, additional_text), disable_notification=True, reply_to_message_id=reply_to_id)
            sent_message=bot.forward_message(chat_id=forward_list[0], from_chat_id=forward_list[1], message_id=msg.message_id, disable_notification=True)
            forwarded_id=sent_message.message_id
            del sent_message
            store_message_id(msg.message_id, forwarded_id, 1)


def status_update(bot, update):
    #chat = update.message.chat
    chat_id = update.message.chat_id
    if update.message.new_chat_members:
        users = update.message.new_chat_members
        for user in users:
            if user.id == bot.id:
                if chat_id not in blacklist:
                    bot.send_message(chat_id=chat_id, text="Hello, this is jerrybot.")
                logger.info("Myself joined the group {0}".format(chat_id))
            else:
                if chat_id not in blacklist:
                    bot.send_message(chat_id=chat_id, text="Welcome, {name} !".format(name=user.first_name))
                logger.info("{0} joined the group {1}".format(user.id, chat_id))
    elif update.message.left_chat_member:
        user = update.message.left_chat_member
        if chat_id not in blacklist:
            bot.send_message(chat_id=chat_id, text="Bye, {name} !".format(name=user.first_name))
        logger.info("{0} left the group {1}".format(user.id, chat_id))
#    else:
#        if update.message.text:
#            bot.send_message(chat_id=chat_id, text="Text: {text}".format(text=update.message.text))

def reply_to_query(bot, update):
    user = update.inline_query.from_user
    query = update.inline_query.query
    query = query.strip()

    def gen_result_randomdraw(query, username, user_id):
        if len(query) == 0:
            myseed=int("{}{}".format(time.strftime("%Y%m%d", time.localtime()), user_id))
        else:
            myseed=int("{}{}{}".format(int(hashlib_md5(query.encode('utf-8')).hexdigest(), 16), time.strftime("%Y%m%d", time.localtime()), user_id))
        random_seed(a=myseed, version=2)
        result=random_choice(("大吉", "吉", "小吉", "尚可", "小凶", "凶", "大凶"))
        if len(query) == 0:
            query="我什么都不说，这是坠吼得"
            result="你好, {0}\n\n(这个人懒死了，什么都没有写)\n所求事项: {1}\n结果: {2}".format(username, query, result)
        else:
            result="你好, {0}\n\n所求事项: {1}\n结果: {2}".format(username, query, result)
        return result

    randomdraw_description="请输入" if len(query)==0 else query
    buttons=[InlineKeyboardButton(text="我也试试", switch_inline_query_current_chat="")]
    keyboard=[buttons]
    if len(query) != 0:
        button_caption="{}...".format(query[0:5]) if len(query)>6 else query
        buttons.append(InlineKeyboardButton(text=button_caption, switch_inline_query_current_chat=query))
    keyboard.append([InlineKeyboardButton(text="转发", switch_inline_query=query)])
    results=[InlineQueryResultArticle(
                    id="randomdraw",
                    title="未卜先知",
                    description=randomdraw_description,
                    input_message_content=InputTextMessageContent(message_text=gen_result_randomdraw(query, display_username(user, atuser=True), user.id)),
                    reply_markup=InlineKeyboardMarkup(keyboard),
                    thumb_url="http://whatever",
                    thumb_width=80,
                    thumb_height=80
             )]
    bot.answer_inline_query(inline_query_id=update.inline_query.id, results=results, cache_time=0)
    logger.info("Inline query from {}".format(user.id))



class forwarded_single_message:
    def __init__(self, original_id, forwarded_id):
        self.original_id = original_id
        self.forwarded_id = forwarded_id
        self.forward_time = int(time.time())
    def is_expired(self):
        expire_time=86400/2
        if (int(time.time()) - self.forward_time) >= expire_time:
            return True
        else:
            return False


def store_message_id(original_id, forwarded_id, group_id):
    global cached_message_id_table
    cached_message_id_table[group_id][original_id]=forwarded_single_message(original_id, forwarded_id)
    keys_to_del=list()
    for (key, single_message) in cached_message_id_table[group_id].items():
        if single_message.is_expired():
            #cached_message_id_table.pop(key)
            keys_to_del.append(key)
    for key_to_del in keys_to_del:
        cached_message_id_table[group_id].pop(key_to_del)

def get_message_id(original_id, group_id):
    global cached_message_id_table
    if not cached_message_id_table[group_id].get(original_id):
        # Message too old
        return None
    else:
        return cached_message_id_table[group_id][original_id].forwarded_id



def extra_handler(bot, update):
    msg=update.message
    #Handle video_note
    if msg.video_note:
        forward_message(bot, update, True)
    if msg.text:
        text=msg.text
    else:
        text="No text"
    logger.info("Unknown message type. Text: {}".format(text))

def dig(bot, update, args):
    if len(args) > 0:
        for i in args:
            if i.find(";") >= 0 or i.find("&") >= 0  or i.find("|") >=0:
                update.message.reply_text("dig: Syntax error")
                logger.info("Unsuccessful dig from " + str(update.message.from_user.id))
                return
        update.message.reply_text(subprocess.getoutput("dig {}".format(" ".join(args))))
    else:
        update.message.reply_text("Usage: /dig <domain>")
    logger.info("Dig from " + str(update.message.from_user.id))

def ping(bot, update, args):
    if len(args) > 0:
        for i in args:
            if i.find(";") >= 0 or i.find("&") >= 0  or i.find("|") >=0:
                update.message.reply_text("ping: Syntax error")
                logger.info("Unsuccessful ping from " + str(update.message.from_user.id))
                return
        update.message.reply_text(subprocess.getoutput("ping {}".format(" ".join(args))))
    else:
        update.message.reply_text("Usage: /ping <domain/ip>")
    logger.info("Ping from " + str(update.message.from_user.id))

def geoip(bot, update, args):
    if len(args) == 1:
        try:
            r = json.loads('{ "data": '+urllib.request.urlopen("http://freeapi.ipip.net/"+socket.gethostbyname(args[0])).read().decode('UTF-8')+'}')
        except:
            update.message.reply_text("No output")
        else:
            update.message.reply_text(" ".join(r['data']))
    else:
        update.message.reply_text("Usage: /geoip <ip>")
    logger.info("Geoip from " + str(update.message.from_user.id))


# Add all handlers to the dispatcher and run the bot
updater.dispatcher.add_handler(tg.InlineQueryHandler(reply_to_query))
updater.dispatcher.add_handler(tg.CommandHandler('start', start))
updater.dispatcher.add_handler(tg.CommandHandler('hello', hello))
updater.dispatcher.add_handler(tg.CommandHandler('chatinfo', chatinfo))
updater.dispatcher.add_handler(tg.CommandHandler('mode', forward_mode_changer, pass_args=True))
updater.dispatcher.add_handler(tg.CommandHandler('dig', dig, pass_args=True))
updater.dispatcher.add_handler(tg.CommandHandler('ping', ping, pass_args=True))
updater.dispatcher.add_handler(tg.CommandHandler('geoip', geoip, pass_args=True))
updater.dispatcher.add_handler(tg.MessageHandler(tg.Filters.status_update, status_update))
updater.dispatcher.add_handler(tg.CallbackQueryHandler(handle_chatinfo_click, pattern=r'chatinfo'))
updater.dispatcher.add_handler(tg.CallbackQueryHandler(handle_link_click, pattern=r'link'))
updater.dispatcher.add_handler(tg.CallbackQueryHandler(handle_adminlist_click, pattern=r'listadmins'))
updater.dispatcher.add_handler(tg.MessageHandler(tg.Filters.text, text_handler, edited_updates=True))
updater.dispatcher.add_handler(tg.MessageHandler(tg.Filters.sticker, sticker_handler))
updater.dispatcher.add_handler(tg.MessageHandler((tg.Filters.audio | tg.Filters.video | tg.Filters.photo | tg.Filters.contact | tg.Filters.document | tg.Filters.location | tg.Filters.reply), forward_message))
updater.dispatcher.add_handler(tg.MessageHandler(tg.Filters.all, extra_handler))
updater.start_polling()
updater.idle()
