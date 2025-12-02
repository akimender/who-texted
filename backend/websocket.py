from fastapi import WebSocket, WebSocketDisconnect
import uuid

from sockets import handle_create_room, handle_join_room, handle_send_message, handle_leave_room, handle_disconnect
from helpers import validate_room_id
from handlers import parse_message

async def handle_websocket(ws: WebSocket, rooms: dict, connections: dict):
    await ws.accept()
    player_id = str(uuid.uuid4()) # generates a random player_id 
    connections[player_id] = ws # maps player id to websocket connection

    print("Client connected:", player_id)

    try:
        while True: # keeps connection open
            message = await ws.receive()

            if message["type"] == "websocket.disconnect":
                print(f"Disconnecting {player_id}")
                break

            raw = message.get("text")
            if not raw:
                continue

            request = parse_message(raw) # pydantic

            print(f"REQUEST {request.type}")

            # ---- Routing by type ----
            match request.type:

                case "create_room":
                    handle_create_room(ws, rooms, request, player_id)

                case "join_room":
                    if not validate_room_id(request, rooms):
                        continue

                    handle_join_room(ws, rooms, connections, request, player_id)

                case "send_message":
                    handle_send_message(ws, rooms, connections, request, player_id)

                case "leave_room":
                    if not validate_room_id(request, rooms):
                        break

                    handle_leave_room(rooms, connections, request, player_id)

            print(f"Rooms {rooms}")
            print(f"Connections {connections}")

    except WebSocketDisconnect:
        handle_disconnect(rooms, connections, player_id)
