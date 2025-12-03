#!/usr/bin/env python3
import os
import random
import string
import time
import subprocess
import threading
import itertools

# ───────────── SPINNER ───────────── #
def spinner(text):
    stop_flag = {"stop": False}

    def spin():
        for c in itertools.cycle(['-', '\\', '|', '/']):
            if stop_flag["stop"]:
                break
            print(f"\r{text} {c}", end="", flush=True)
            time.sleep(0.1)
        print(f"\r{text} ✔", flush=True)

    t = threading.Thread(target=spin)
    t.start()

    def stop():
        stop_flag["stop"] = True
        t.join()

    return stop

# ───────────── INSTALL DEPENDENCIES ───────────── #
def install_dependencies():
    stop = spinner("Installing Dependencies")
    process = subprocess.Popen(
        "sudo apt update -y >/dev/null 2>&1 && sudo apt install -y python3 >/dev/null 2>&1",
        shell=True
    )
    while process.poll() is None:
        time.sleep(0.1)
    stop()
    time.sleep(0.3)

# ───────────── RANDOM TEXT ───────────── #
def random_text(length=60):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

# ───────────── FILE CYCLE ───────────── #
def file_cycle():
    folder = "24-7"
    os.makedirs(folder, exist_ok=True)
    os.chdir(folder)

    print("\nStarted 24/7 File Operations...\n")

    while True:
        try:
            filename = f"{random_text(6)}.txt"

            # CREATE
            with open(filename, "w") as f:
                for _ in range(random.randint(5, 25)):
                    f.write(random_text() + "\n")
            print(f"Created <{filename}>")
            time.sleep(2)

            # EDIT
            with open(filename, "a") as f:
                f.write("\n# Edited\n")
            print(f"Edited <{filename}>")
            time.sleep(1)

            # DELETE
            os.remove(filename)
            print(f"Deleted <{filename}>")
            time.sleep(1)

        except Exception as e:
            print(f"Error: {e}")
            time.sleep(3)

# ───────────── RUNNER ───────────── #
if __name__ == "__main__":
    install_dependencies()
    file_cycle()
