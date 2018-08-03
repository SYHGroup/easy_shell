#!/usr/bin/env python3
# -*- coding: utf-8 -*-
RED = 'r'
BLUE = 'b'
GREEN = 'g'
YELLOW = 'y'
COLORS = (RED, BLUE, GREEN, YELLOW)

# Special cards
CHOOSE = 'colorchooser'
DRAW_FOUR = 'draw_four'
SPECIALS = (CHOOSE, DRAW_FOUR)

NOGREY = {
    'BQADBAAD-AIAAl9XmQABxEjEcFM-VHIC': 'option_draw',
    'BQADBAAD-gIAAl9XmQABcEkAAbaZ4SicAg': 'option_pass',
    'BQADBAADygIAAl9XmQABJoLfB9ntI2UC': 'option_bluff',
    'BQADBAADxAIAAl9XmQABC5v3Z77VLfEC': 'option_info'
}

STICKERS = {
    'BQADBAAD2QEAAl9XmQAB--inQsYcLTsC': 'b_0',
    'BQADBAAD2wEAAl9XmQABBzh4U-rFicEC': 'b_1',
    'BQADBAAD3QEAAl9XmQABo3l6TT0MzKwC': 'b_2',
    'BQADBAAD3wEAAl9XmQAB2y-3TSapRtIC': 'b_3',
    'BQADBAAD4QEAAl9XmQABT6nhOuolqKYC': 'b_4',
    'BQADBAAD4wEAAl9XmQABwRfmekGnpn0C': 'b_5',
    'BQADBAAD5QEAAl9XmQABQITgUsEsqxsC': 'b_6',
    'BQADBAAD5wEAAl9XmQABVhPF6EcfWjEC': 'b_7',
    'BQADBAAD6QEAAl9XmQABP6baig0pIvYC': 'b_8',
    'BQADBAAD6wEAAl9XmQAB0CQdsQs_pXIC': 'b_9',
    'BQADBAAD7QEAAl9XmQAB00Wii7R3gDUC': 'b_draw',
    'BQADBAAD8QEAAl9XmQAB_RJHYKqlc-wC': 'b_skip',
    'BQADBAAD7wEAAl9XmQABo7D0B9NUPmYC': 'b_reverse',
    'BQADBAAD9wEAAl9XmQABb8CaxxsQ-Y8C': 'g_0',
    'BQADBAAD-QEAAl9XmQAB9B6ti_j6UB0C': 'g_1',
    'BQADBAAD-wEAAl9XmQABYpLjOzbRz8EC': 'g_2',
    'BQADBAAD_QEAAl9XmQABKvc2ZCiY-D8C': 'g_3',
    'BQADBAAD_wEAAl9XmQABJB52wzPdHssC': 'g_4',
    'BQADBAADAQIAAl9XmQABp_Ep1I4GA2cC': 'g_5',
    'BQADBAADAwIAAl9XmQABaaMxxa4MihwC': 'g_6',
    'BQADBAADBQIAAl9XmQABv5Q264Crz8gC': 'g_7',
    'BQADBAADBwIAAl9XmQABjMH-X9UHh8sC': 'g_8',
    'BQADBAADCQIAAl9XmQAB26fZ2fW7vM0C': 'g_9',
    'BQADBAADCwIAAl9XmQAB64jIZrgXrQUC': 'g_draw',
    'BQADBAADDwIAAl9XmQAB17yhhnh46VQC': 'g_skip',
    'BQADBAADDQIAAl9XmQAB_xcaab0DkegC': 'g_reverse',
    'BQADBAADEQIAAl9XmQABiUfr1hz-zT8C': 'r_0',
    'BQADBAADEwIAAl9XmQAB5bWfwJGs6Q0C': 'r_1',
    'BQADBAADFQIAAl9XmQABHR4mg9Ifjw0C': 'r_2',
    'BQADBAADFwIAAl9XmQABYBx5O_PG2QIC': 'r_3',
    'BQADBAADGQIAAl9XmQABTQpGrlvet3cC': 'r_4',
    'BQADBAADGwIAAl9XmQABbdLt4gdntBQC': 'r_5',
    'BQADBAADHQIAAl9XmQABqEI274p3lSoC': 'r_6',
    'BQADBAADHwIAAl9XmQABCw8u67Q4EK4C': 'r_7',
    'BQADBAADIQIAAl9XmQAB8iDJmLxp8ogC': 'r_8',
    'BQADBAADIwIAAl9XmQAB_HCAww1kNGYC': 'r_9',
    'BQADBAADJQIAAl9XmQABuz0OZ4l3k6MC': 'r_draw',
    'BQADBAADKQIAAl9XmQAC2AL5Ok_ULwI': 'r_skip',
    'BQADBAADJwIAAl9XmQABu2tIeQTpDvUC': 'r_reverse',
    'BQADBAADKwIAAl9XmQAB_nWoNKe8DOQC': 'y_0',
    'BQADBAADLQIAAl9XmQABVprAGUDKgOQC': 'y_1',
    'BQADBAADLwIAAl9XmQABqyT4_YTm54EC': 'y_2',
    'BQADBAADMQIAAl9XmQABGC-Xxg_N6fIC': 'y_3',
    'BQADBAADMwIAAl9XmQABbc-ZGL8kApAC': 'y_4',
    'BQADBAADNQIAAl9XmQAB67QJZIF6XAcC': 'y_5',
    'BQADBAADNwIAAl9XmQABJg_7XXoITsoC': 'y_6',
    'BQADBAADOQIAAl9XmQABVrd7OcS2k34C': 'y_7',
    'BQADBAADOwIAAl9XmQABRpJSahBWk3EC': 'y_8',
    'BQADBAADPQIAAl9XmQAB9MwJWKLJogYC': 'y_9',
    'BQADBAADPwIAAl9XmQABaPYK8oYg84cC': 'y_draw',
    'BQADBAADQwIAAl9XmQABO_AZKtxY6IMC': 'y_skip',
    'BQADBAADQQIAAl9XmQABZdQFahGG6UQC': 'y_reverse',
    'BQADBAAD9QEAAl9XmQABVlkSNfhn76cC': 'draw_four',
    'BQADBAAD8wEAAl9XmQABl9rUOPqx4E4C': 'colorchooser',
    'BQADBAAD-AIAAl9XmQABxEjEcFM-VHIC': 'option_draw',
    'BQADBAAD-gIAAl9XmQABcEkAAbaZ4SicAg': 'option_pass',
    'BQADBAADygIAAl9XmQABJoLfB9ntI2UC': 'option_bluff',
    'BQADBAADxAIAAl9XmQABC5v3Z77VLfEC': 'option_info'
}


STICKERS_GREY = {
    'BQADBAADRQIAAl9XmQAB1IfkQ5xAiK4C': 'b_0',
    'BQADBAADRwIAAl9XmQABbWvhTeKBii4C': 'b_1',
    'BQADBAADSQIAAl9XmQABS1djHgyQokMC': 'b_2',
    'BQADBAADSwIAAl9XmQABwQ6VTbgY-MIC': 'b_3',
    'BQADBAADTQIAAl9XmQABAlKUYha8YccC': 'b_4',
    'BQADBAADTwIAAl9XmQABMvx8xVDnhUEC': 'b_5',
    'BQADBAADUQIAAl9XmQABDEbhP1Zd31kC': 'b_6',
    'BQADBAADUwIAAl9XmQABXb5XQBBaAnIC': 'b_7',
    'BQADBAADVQIAAl9XmQABgL5HRDLvrjgC': 'b_8',
    'BQADBAADVwIAAl9XmQABtO3XDQWZLtYC': 'b_9',
    'BQADBAADWQIAAl9XmQAB2kk__6_2IhMC': 'b_draw',
    'BQADBAADXQIAAl9XmQABEGJI6CaH3vcC': 'b_skip',
    'BQADBAADWwIAAl9XmQAB_kZA6UdHXU8C': 'b_reverse',
    'BQADBAADYwIAAl9XmQABGD5a9oG7Yg4C': 'g_0',
    'BQADBAADZQIAAl9XmQABqwABZHAXZIg0Ag': 'g_1',
    'BQADBAADZwIAAl9XmQABTI3mrEhojRkC': 'g_2',
    'BQADBAADaQIAAl9XmQABVi3rUyzWS3YC': 'g_3',
    'BQADBAADawIAAl9XmQABZIf5ThaXnpUC': 'g_4',
    'BQADBAADbQIAAl9XmQABNndVJSQCenIC': 'g_5',
    'BQADBAADbwIAAl9XmQABpoy1c4ZkrvwC': 'g_6',
    'BQADBAADcQIAAl9XmQABDeaT5fzxwREC': 'g_7',
    'BQADBAADcwIAAl9XmQABLIQ06ZM5NnAC': 'g_8',
    'BQADBAADdQIAAl9XmQABel-mC7eXGsMC': 'g_9',
    'BQADBAADdwIAAl9XmQABOHEpxSztCf8C': 'g_draw',
    'BQADBAADewIAAl9XmQABDaQdMxjjPsoC': 'g_skip',
    'BQADBAADeQIAAl9XmQABek1lGz7SJNAC': 'g_reverse',
    'BQADBAADfQIAAl9XmQABWrxoiXcsg0EC': 'r_0',
    'BQADBAADfwIAAl9XmQABlav-bkgSgRcC': 'r_1',
    'BQADBAADgQIAAl9XmQABDjZkqfJ4AdAC': 'r_2',
    'BQADBAADgwIAAl9XmQABT7lH7VVcy3MC': 'r_3',
    'BQADBAADhQIAAl9XmQAB1arPC5x0LrwC': 'r_4',
    'BQADBAADhwIAAl9XmQABWvs7xkCDldkC': 'r_5',
    'BQADBAADiQIAAl9XmQABjwABH5ZonWn8Ag': 'r_6',
    'BQADBAADiwIAAl9XmQABjekJfm4fBDIC': 'r_7',
    'BQADBAADjQIAAl9XmQABqFjchpsJeEkC': 'r_8',
    'BQADBAADjwIAAl9XmQAB-sKdcgABdNKDAg': 'r_9',
    'BQADBAADkQIAAl9XmQABtw9RPVDHZOQC': 'r_draw',
    'BQADBAADlQIAAl9XmQABtG2GixCxtX4C': 'r_skip',
    'BQADBAADkwIAAl9XmQABz2qyEbabnVsC': 'r_reverse',
    'BQADBAADlwIAAl9XmQABAb3ZwTGS1lMC': 'y_0',
    'BQADBAADmQIAAl9XmQAB9v5qJk9R0x8C': 'y_1',
    'BQADBAADmwIAAl9XmQABCsgpRHC2g-cC': 'y_2',
    'BQADBAADnQIAAl9XmQAB3kLLXCv-qY0C': 'y_3',
    'BQADBAADnwIAAl9XmQAB7R_y-NexNLIC': 'y_4',
    'BQADBAADoQIAAl9XmQABl-7mwsjD-cMC': 'y_5',
    'BQADBAADowIAAl9XmQABwbVsyv2MfPkC': 'y_6',
    'BQADBAADpQIAAl9XmQABoBqC0JsemVwC': 'y_7',
    'BQADBAADpwIAAl9XmQABpkwAAeh9ldlHAg': 'y_8',
    'BQADBAADqQIAAl9XmQABpSBEUfd4IM8C': 'y_9',
    'BQADBAADqwIAAl9XmQABMt-2zW0VYb4C': 'y_draw',
    'BQADBAADrwIAAl9XmQABIDf-_TuuxtEC': 'y_skip',
    'BQADBAADrQIAAl9XmQABm9M0Zh-_UwkC': 'y_reverse',
    'BQADBAADYQIAAl9XmQAB_HWlvZIscDEC': 'draw_four',
    'BQADBAADXwIAAl9XmQABY_ksDdMex-wC': 'colorchooser'
}
