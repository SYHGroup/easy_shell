import ctypes
import random
import sys
import threading
import time

try:
    import win32gui
    from pynput import keyboard, mouse
except:
    print("pip install pywin32 pynput")
    sys.exit(1)

RAND = 0.01                 # Seconds
TARGETKEY = mouse.Button.x1 # Target Key
STOPKEY = keyboard.Key.f8   # Stop Key

def is_admin():
    # https://stackoverflow.com/questions/130763/request-uac-elevation-from-within-a-python-script
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

if is_admin():
    # Code of your program here
    print(f"按住 {TARGETKEY} 开启")
    print(f"按下 {STOPKEY} 停止")
    print(f"间隔 {RAND}")

    k = keyboard.Controller()
    m = mouse.Controller()
    continue_flag = threading.Event()
    stop_flag = threading.Event()
    def script(stop_event, continue_event, rand):
        while True:
            if continue_event.wait(rand):
                if win32gui.GetWindowText(win32gui.GetForegroundWindow()) == "原神":
                    k.press("f")
                    time.sleep(random.uniform(0, rand))
                    k.release("f")
                    time.sleep(random.uniform(0, rand))
                    m.scroll(0, -1)
                    time.sleep(random.uniform(0, rand))
            elif stop_event.wait(rand):
                break
        print("Script thread killed")


    t = threading.Thread(target=script, args=(stop_flag, continue_flag, RAND))
    t.start()

    def on_click(x, y, button, pressed):
        if button == TARGETKEY:
            if pressed == 1:
                continue_flag.set()
            else:
                continue_flag.clear()
        # else:
        #     print(f"{button}")

    m_listener = mouse.Listener(on_click=on_click)
    m_listener.start()

    def on_release(key):
        if key == STOPKEY:
            stop_flag.set()
            m_listener.stop()
            print("Listener thread stoped")
            return False
        # else:
        #     print(f"{key}")

    with keyboard.Listener(on_release=on_release) as k_listener:
        m_listener.join()
        k_listener.join()

else:
    # Re-run the program with admin rights
    ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, " ".join(sys.argv), None, 1)
