from fastapi import WebSocketDisconnect
import uuid
import json

from helpers import send, broadcast, create_room, join_room

async def handle_websocket(ws, rooms, connections):
    await ws.accept()

    player_id = str(uuid.uuid4())
    connections[player_id] = ws # maps player id to websocket

    print("Client connected:", player_id)

    try:
        while True:
            message = await ws.receive()

            if message["type"] == "websocket.disconnect":
                break

            raw = message.get("text")
            if raw is None:
                continue

            try:
                data = json.loads(raw)
            except json.JSONDecodeError:
                continue

            event_type = data.get("type")
            username = data.get("username")
            if not event_type:
                continue

            print(f"event_type: {event_type}, username: {username}")

            # --- CREATE ROOM ---
            if event_type == "create_room":
                room_id, display_name = create_room(rooms, player_id, username)

                await send(ws, {
                    "type": "room_joined",
                    "playerId": player_id,
                    "roomId": room_id,
                    "displayName": display_name,
                    "isHost": True,
                    "room": rooms[room_id]   # now full room data
                })

                await broadcast(rooms=rooms, connections=connections, room_id=room_id, payload={
                    "type": "room_update",
                    "room": rooms[room_id]
                })


            # --- JOIN ROOM ---
            elif event_type == "join_room":
                room_id = data["roomId"]

                if room_id not in rooms:
                    await send(ws, {
                        "type": "join_failed",
                        "reason": "Room does not exist"
                    })
                    continue

                display_name, room = join_room(rooms=rooms, player_id=player_id, username=username, room_id=room_id)

                # Send to the player who joined
                await send(ws, {
                    "type": "room_joined",
                    "playerId": player_id,
                    "roomId": room_id,
                    "displayName": display_name,
                    "isHost": False,
                    "room": room
                })

                # Broadcast updated room to everyone
                await broadcast(rooms=rooms, connections=connections, room_id=room_id, payload={
                    "type": "room_update",
                    "room": room
                })

            # --- SEND MESSAGE ---
            elif event_type == "send_message":
                room_id = data["roomId"]
                text = data["text"]

                # find player's display name
                room = rooms[room_id]
                sender = next(p for p in room["players"] if p["id"] == player_id)

                message_payload = {
                    "type": "chat_message",
                    "senderId": sender["id"],
                    "senderDisplayName": sender["displayName"],
                    "text": text
                }

                await broadcast(rooms=rooms, connections=connections, room_id=room_id, payload=message_payload)

    except WebSocketDisconnect:
        print("Client disconnected:", player_id)
        connections.pop(player_id, None)
