#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from card import COLORS, SPECIALS
from card import RED, BLUE, GREEN, YELLOW
from random import choice, random

def color_from_str(string):
    """Decodes a Card object from a string"""
    # Actuall it should't be "in special"
    if string not in SPECIALS:
        color, value = string.split('_')
        del value
        return color

def cards_sum(deck):
        # r, b, g, y
        card_count = {RED: 0, BLUE: 0, GREEN: 0, YELLOW: 0}
        for card in deck:
            card_count[color_from_str(card)] += 1
        return card_count

def color_choice(deck):
    sum = cards_sum(deck)
    chosen_color = None
    chosen_number = 0
    for color in (RED, BLUE, GREEN, YELLOW):
        if chosen_number <= sum[color]:
            sum[color] = chosen_number
            chosen_color = color
    if chosen_number == 0 or chosen_color is None:
        chosen_color = choice((RED, BLUE, GREEN, YELLOW))
    return chosen_color

def debug_print(mylist):
    result = ''
    for item in mylist:
        result += str(item)
        result += '\t'
    return result

def randchance(chance):
    if chance > random():
        return True
    else:
        return False

class Game():
    def __init__(self):
        self.deck = list()
        self.special = list()
        self.functional = list()
        # draw, call_bluff, pass
        # call_bluff > draw
        self.choose_color = list()
        self.is_playing = False
        self.anti_cheat = ''
    def clear_deck(self):
        self.deck = list()
        self.special = list()
        self.functional = list()
        self.choose_color = list()
        self.anti_cheat = ''
    def add_card(self, result_id, anti_cheat):
        self.anti_cheat = anti_cheat
        if result_id in ('hand', 'gameinfo', 'nogame'):
            return
        elif result_id.startswith('mode_'):
            return
        elif len(result_id) == 36:
            return
        elif result_id == 'call_bluff':
            self.functional.append(result_id)
        elif result_id == 'draw':
            self.functional.append(result_id)
        elif result_id == 'pass':
            self.functional.append(result_id)
        elif result_id in COLORS:
            self.choose_color.append(result_id)
        elif result_id in SPECIALS:
            self.special.append(result_id)
        else:
            self.deck.append(result_id)
    def play_card(self):
        if len(self.choose_color):
            return color_choice(self.deck)
        elif len(self.deck):
            if len(self.special) and randchance(0.1):
                return choice(self.special)
            else:
                return choice(self.deck)
        elif len(self.special):
            return choice(self.special)
        elif len(self.functional):
            if 'pass' in self.functional:
                return 'pass'
            else:
                if 'call_bluff' in self.functional and randchance(0.4):
                    return 'call_bluff'
                else:
                    return choice(self.functional)
