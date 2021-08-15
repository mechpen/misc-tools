#!/usr/bin/python3

import time
import signal
import queue
import threading
from collections import defaultdict
from urllib.request import urlopen

running = True
resp_queue = queue.Queue()

def sig_handler(signum, stack):
    global running
    print("\nstopping")
    running = False

def do_one_request(url, timeout=1):
    start = time.time()
    try:
        resp = urlopen(url, timeout=timeout)
    except Exception as e:
        resp_queue.put((str(e), -1))
    else:
        resp_queue.put((str(resp.status), time.time()-start))

    sleep = start + timeout - time.time()
    if sleep > 0:
        time.sleep(sleep)

def start_requests(url, timeout):
    while running:
        do_one_request(url, timeout)

def main(args):
    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    interval = 1
    threads = []
    for _ in range(args.rps):
        t = threading.Thread(target=start_requests, args=(args.url, interval))
        t.start()
        threads.append(t)

    while running:
        time.sleep(interval)
        result = defaultdict(list)
        total = 0
        while not resp_queue.empty():
            (res, delta) = resp_queue.get()
            result[res].append(delta)
            total += 1

        line = "total=" + str(total)
        for key in sorted(result.keys()):
            deltas = result[key]
            line += " "
            line += key + "=" + str(len(deltas))
            line += "(%.2f/%.2f/%.2f)" % (
                max(deltas), min(deltas), sum(deltas)/len(deltas))
        print(line)

    for t in threads:
        t.join()

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="generate http load for testing")
    parser.add_argument(
        "--rps", type=int, default=100,
        help="request per second")
    parser.add_argument(
        "url",
        help="url")
    args = parser.parse_args()
    main(args)
