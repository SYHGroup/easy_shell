#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import subprocess
import argparse
import socket
import time
import datetime
import traceback
from threading import Thread
import curses

def background(func):
    def wrapped(*args, **kwargs):
        tr = Thread(target=func, args=args, kwargs=kwargs)
        tr.daemon = True
        tr.start()
        return tr
    return wrapped

def ascii_color_text(text, color, end="\033[0m"):
    if   color in (0, "bl"): # black
        return f"\033[30;49m{text}{end}"
    elif color in (1, "r"):  # red
        return f"\033[31;49m{text}{end}"
    elif color in (2, "g"):  # green
        return f"\033[32;49m{text}{end}"
    elif color in (3, 'y'):  # yellow
        return f"\033[33;49m{text}{end}"
    elif color in (4, 'b'):  # blue
        return f"\033[34;49m{text}{end}"
    elif color in (5, 'm'):  # magenta
        return f"\033[35;49m{text}{end}"
    elif color in (6, 'c'):  # cyan
        return f"\033[36;49m{text}{end}"
    elif color in (7, 'w'):  # white
        return f"\033[37;49m{text}{end}"
    else:
        return text

parser = argparse.ArgumentParser(description='Mtr data plotter')
if __name__ != "__main__":
    parser.exit(1, message="Please run the script interactively.")
parser.add_argument('address')
parser.add_argument('-6', '--ipv6', action='store_true', help='Use IPv6')
parser.add_argument('-o', '--output', default='mtrp.txt', help='Output file')
parser.add_argument('--tsu', action='store_true', help='Use tsu -c mtr in termux')
parser.add_argument('-T', '--tcp', action='store_true', help='Use TCP')
parser.add_argument('-u', '--udp', action='store_true', help='Use UDP')
parser.add_argument('-P', '--port', default='443', help='TCP or UDP port')
args = parser.parse_args()
if args.ipv6:
    inetfamily=socket.AF_INET6
else:
    inetfamily=socket.AF_INET
addrinfo = socket.getaddrinfo(args.address, None, family=inetfamily, proto=socket.IPPROTO_TCP)
ipaddr = [addr[4][0] for addr in addrinfo]
assert ipaddr
IP = ipaddr[0]
assert IP
print('*** Mtr data plotter ***')
print('Address:', IP)
print('Started at', time.strftime("%Y%m%d %H:%M:%S", time.localtime()))

MTRARGS = ['mtr', '-n', '-c', '2147483646', '-l', '-i', '10']
if args.tsu:
    MTRARGS = ['tsu', '-c'] + MTRARGS
if args.tcp:
    MTRARGS.extend(['-T', '-P', args.port])
elif args.udp:
    MTRARGS.extend(['-u', '-P', args.port])

class Hop:
    def __init__(self):
        self.hostname = None
        self.addr = set()
        self._sent = 0
        self._recv = 0
        self.alive = False
        self._time = 0  # current ttl, in microseconds (10e-6)
        self._atime = 0 # all recv ttl, in microseconds
        self.tmdata = list()
    @background
    def addr_found(self, addr):
        self.addr.add(addr)
        try:
            self.hostname = socket.gethostbyaddr(addr)[0]
        except Exception:
            pass
    def send(self):
        self._sent += 1
    def recv(self, ms):
        self._recv += 1
        self._time = ms
        self._atime += ms
    @property
    def avg(self):
        return self._atime / self._recv if self._recv else 0
    @property
    def loss(self):
        return 1 - self._recv / self._sent if self._sent else 0
    def __repr__(self):
        return f"Hop({self.addr} {self.alive=} {self._sent=} {self._recv=} {self._time=} {self._atime=})"
class MtrRawData:
    def __init__(self, dest, ofhandle, ipv6=False):
        self.dest = dest
        self.ofhandle = ofhandle
        self.ipv6 = ipv6
        self.maxhopidx = 0
        self._hops = list()
        self._thopidx = 0
        self._rhopidx = 0
        self._tmtrid = ""
        self._rmtrid = ""
        self._lastrecv = -1
        self._starttime = 0
        self._messages = ""
        self._msgtime = 0.0
    def show_msg(self, text):
        self._messages = text
        self._msgtime = time.time()
    def format_info(self):
        def time2str4(mtime):
            mstr = f"{float(mtime): <0.2f}"
            if mtime > 9999 and len(mstr) > 4:
                return "10e4 "
            else:
                return mstr[:4] + " "
        buffer = list()
        if self._messages and time.time() - self._msgtime < 10:
            buffer += self._messages.split('\n')[:20]
        buffer.append("   Last Avg  Loss         Address")
        for (idx, hop) in enumerate(self._hops):
            line = ""
            line += f"{idx+1: >2d} "
            line += time2str4(hop._time/1000) if hop.alive else "inf  "
            line += time2str4(hop.avg/1000)
            line += time2str4(hop.loss*100)
            line += f'{" ".join(hop.addr): >15s}'
            if hop.hostname:
                line += " "
                line += hop.hostname
            buffer.append(line)
        return buffer
    def draw(self):
        pad.clear()
        lidx = 0
        ltmidx = 0
        banner = f'Mtr data plotter {IP}  {time.strftime("%Y%m%d %H:%M:%S", time.localtime())}'
        banner = banner[:PADX]
        pad.addnstr(0, 0, banner, len(banner))
        timebanner = time.strftime("%Y%m%d %H:%M:%S", self._starttime)
        pad.addnstr(1, 0, timebanner, len(timebanner), curses.color_pair(6))
        for (idx, hop) in enumerate(self._hops):
            idx += 2 # for title bars
            pad.addnstr(idx, 0, f"{idx-1: >2d} ", 3)
            for (tmidx, tm) in enumerate(hop.tmdata):
                lidx = idx
                if tm < 0:
                    pad.addch(idx, 3+tmidx, '?', curses.color_pair(1))
                elif tm < 10*1000:
                    pad.addch(idx, 3+tmidx, '.', curses.color_pair(2))
                elif tm < 50*1000:
                    pad.addch(idx, 3+tmidx, '+', curses.color_pair(2))
                elif tm < 100*1000:
                    pad.addch(idx, 3+tmidx, '.', curses.color_pair(4))
                elif tm < 200*1000:
                    pad.addch(idx, 3+tmidx, '+', curses.color_pair(4))
                elif tm < 300*1000:
                    pad.addch(idx, 3+tmidx, '.', curses.color_pair(3))
                else:
                    pad.addch(idx, 3+tmidx, '+', curses.color_pair(3))
                ltmidx = tmidx
        for (strid, mstr) in enumerate(self.format_info()):
            mstr = mstr[:PADX]
            pad.addnstr(lidx+2+strid, 0, mstr, len(mstr))
        if ltmidx >= PADX - 3 - 1:
            self.draw_file()
            def pop_all(l):
                _, l[:] = l[:], []
                return None
            for hop in self._hops:
                pop_all(hop.tmdata)
            self._starttime = 0
        pad._flushpad()
    def draw_file_banner(self):
        banner = f'Mtr data plotter {IP}  {time.strftime("%Y%m%d %H:%M:%S", time.localtime())}'
        banner += "\n"
        self.ofhandle.write(banner)
        self.ofhandle.flush()
    def draw_file(self, end=False):
        buffer = ""
        timebanner = time.strftime("%Y%m%d %H:%M:%S", self._starttime)
        timebanner += "\n"
        timebanner = ascii_color_text(timebanner, 6)
        buffer += timebanner
        for (idx, hop) in enumerate(self._hops):
            line = f"{idx+1: >2d} "
            for (tmidx, tm) in enumerate(hop.tmdata):
                if tm < 0:
                    line += ascii_color_text("?", 1)
                elif tm < 10*1000:
                    line += ascii_color_text(".", 2)
                elif tm < 50*1000:
                    line += ascii_color_text("+", 2)
                elif tm < 100*1000:
                    line += ascii_color_text(".", 4)
                elif tm < 200*1000:
                    line += ascii_color_text("+", 4)
                elif tm < 300*1000:
                    line += ascii_color_text(".", 3)
                else:
                    line += ascii_color_text("+", 3)
            buffer += f"{line}\n"
        if end:
            buffer += "\n"
            buffer += "\n".join(self.format_info())
            buffer += "\n"
        self.ofhandle.write(buffer)
        self.ofhandle.flush()
    def process_input(self, text):
        if not self._starttime:
            self._starttime = time.localtime()
        if text.startswith('x '):   # x 0 33000 => transmit
            (_, hopidx, mtrid) = text.split()
            hopidx = int(hopidx)
            if self._thopidx > hopidx:
                # last biggest hop index
                self.maxhopidx = self._thopidx
                while len(self._hops) - 1 > self.maxhopidx:
                    self._hops.pop(-1)
            while len(self._hops) < hopidx + 1:
                self._hops.append(Hop())
            if self._tmtrid and self._tmtrid != self._rmtrid: # last transfer was not received
                if self._lastrecv == self._thopidx:
                    self.show_msg(f"Duplicate addnone {text=}")
                else:
                    self._hops[self._thopidx].alive = False
                    self._hops[self._thopidx].tmdata.append(-1)
                    self._lastrecv = self._thopidx
            self._hops[hopidx].send()
            self._thopidx = hopidx
            self._tmtrid = mtrid
        elif text.startswith('h '): # h 0 x.x.x.x => new hop with addr x.x.x.x
            (_, hopidx, addr) = text.split()
            hopidx = int(hopidx)
            if self.maxhopidx and hopidx > self.maxhopidx:
                return
            self._hops[hopidx].addr_found(addr)
        elif text.startswith('p '): # p 0 100 33000
            (_, hopidx, ms, mtrid) = text.split()
            self._rmtrid = mtrid
            if self._rmtrid != self._tmtrid: # this receive is garbage
                self.show_msg(f"Bad {self._rmtrid=}, {self._tmtrid=}, {text=}")
                return
            (hopidx, ms) = (int(hopidx), int(ms))
            if self.maxhopidx and hopidx > self.maxhopidx:
                return
            if self._lastrecv == self._thopidx:
                self.show_msg(f"Duplicate recv {text=}")
            else:
                self._hops[hopidx].alive = True
                self._hops[hopidx].recv(ms)
                self._hops[hopidx].tmdata.append(ms)
                self._lastrecv = self._thopidx
            lhopidx = len(self._hops) - 1 if hopidx == 0 else hopidx - 1
            while lhopidx != hopidx and \
                len(self._hops[lhopidx].tmdata) < len(self._hops[hopidx].tmdata) - (1 if hopidx == 0 else 0):
                self.show_msg(f"hop {lhopidx} lost one packet!")
                self._hops[lhopidx].recv(-1)
                self._hops[lhopidx].tmdata.append(-1)
            self._rhopidx = hopidx
        self.draw()
# init screen
def initscr():
    stdscr = curses.initscr()
    curses.noecho()
    curses.cbreak()
    curses.start_color()
    curses.use_default_colors()
    curses.curs_set(False)
    stdscr.keypad(True)
    for i in range(7):
        curses.init_pair(i+1, i+1, -1) # see https://docs.python.org/3/howto/curses.html#attributes-and-color
    return stdscr

def endscr():
    curses.curs_set(True)
    curses.nocbreak()
    stdscr.keypad(False)
    curses.echo()
    curses.endwin()

stdscr = initscr()
class Scr:
    scr = stdscr
    def __init__(self):
        (self.y, self.x) = stdscr.getmaxyx()
    def _resize(self):
        curses.update_lines_cols()
        self.__init__()
    def __getattr__(self, attr):
        return getattr(self.pad, attr)
scr = Scr()
(PADY, PADX) = (100, 50+3 if scr.x <= 50+3 else scr.x//50*50+3)
virtpad = curses.newpad(PADY + 1, PADX + 1)
class Pad:
    pad = virtpad
    def __init__(self):
        self.resize()
    def resize(self):
        self.ymin = self.xmin = 0
        self.ymax = min(scr.y-1, PADY-1)
        self.xmax = min(scr.x-1, PADX-1)
    def __getattr__(self, attr):
        def wrapped(*args, **kwargs):
            try:
                return getattr(self.pad, attr)(*args, **kwargs)
            except Exception:
                try:
                    mtrraw.show_msg(traceback.format_exc())
                except Exception:
                    pass
        if attr in ("addch", 'addnstr', 'addstr'):
            return wrapped
        if attr == "refresh":
            if curses.is_term_resized(scr.y, scr.x):
                scr._resize()
                self.resize()
                mtrraw.show_msg('Auto Window resize.')
            return wrapped
        else:
            return getattr(self.pad, attr)
    def _flushpad(self):
        self.refresh(self.ymin, self.xmin, 0, 0, self.ymax, self.xmax)
pad = Pad()

@background
def interact(p):
    while True:
        c = stdscr.getch()
        if c == ord('q'):
            p.terminate()
            break
        if c == ord('r'):
            scr._resize()
            pad.resize()
            mtrraw.show_msg('Window resize')
        elif c == curses.KEY_UP:
            if pad.ymin > 0:
                pad.ymin -= 1
        elif c == curses.KEY_DOWN:
            if PADY > scr.y and PADY - scr.y > pad.ymin:
                pad.ymin += 1
        elif c == curses.KEY_LEFT:
            if pad.xmin > 0:
                pad.xmin -= 1
        elif c == curses.KEY_RIGHT:
            if PADX > scr.x and PADX - scr.x > pad.xmin:
                pad.xmin += 1
        else:
            continue
        if curses.is_term_resized(scr.y, scr.x):
            scr._resize()
            pad.resize()
            mtrraw.show_msg('Auto Window resize.')
        pad.refresh(pad.ymin, pad.xmin, 0, 0, pad.ymax, pad.xmax)

class Pstderr:
    err = ""
    def __init__(self, p):
        self.p = p
    @background
    def read(self):
        while p.poll() is None:
            line = p.stderr.readline()
            if line:
                self.err += line
                self.err += "\n"
                self.err = self.err[:4096]
with open(args.output, 'w') as ofhandle:
    p = pstderr = None
    try:
        p = subprocess.Popen([*MTRARGS, "-6" if args.ipv6 else "-4", IP], env={"LANG": "C"},
                            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, encoding='utf-8')
        pstderr = Pstderr(p)
        pstderr.read()
        mtrraw = MtrRawData(IP, ofhandle)
        mtrraw.draw_file_banner()
        interact(p)
        while p.poll() is None:
            line = p.stdout.readline()
            if line:
                mtrraw.process_input(line)
    except (KeyboardInterrupt, SystemExit):
        try:
            mtrraw.draw_file(end=True)
        except Exception:
            traceback.print_exc()
        endscr()
        print('Bye')
    except Exception:
        try:
            mtrraw.draw_file(end=True)
        except Exception:
            traceback.print_exc()
        endscr()
        traceback.print_exc()
    else:
        try:
            mtrraw.draw_file(end=True)
        except Exception:
            traceback.print_exc()
        endscr()
    if pstderr:
        print(pstderr.err)
    print('Stopped at', time.strftime("%Y%m%d %H:%M:%S", time.localtime()))
    for tries in range(10):
        if p is None or p.poll():
            break
        else:
            print('Terminate mtr')
            time.sleep(1)
            p.terminate()
    else:
        print('Kill mtr')
        p.kill()
