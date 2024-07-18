import sys
import time
import simple_websocket
import logging


def main(address):
    ws = simple_websocket.Client(address)
    try:
        while True:
            data = str(time.time())
            # uncomment for interactive input
            # data = input('> ')
            ws.send(data)
            print(f'> {data}')
            data = ws.receive()
            time.sleep(0.1)
            print(f'< {data}')
    except (KeyboardInterrupt, EOFError, simple_websocket.ConnectionClosed):
        ws.close()


if __name__ == '__main__':
    local_address = 'ws://localhost:9999/echo'
    public_internet_address = 'ws://quest.ms.mff.cuni.cz/ws/wstest'

    usage = sys.argv[1]
    if usage == "local":
        address = local_address
    elif usage == "public_internet":
        address = public_internet_address
    else:
        print(f"Usage: {sys.argv[0]} local|local_prefix|public_internet")
        sys.exit(1)

    main(address)
