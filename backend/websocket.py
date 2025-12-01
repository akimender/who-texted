from fastapi import WebSocket, WebSocketDisconnect
import uuid

from models import (
    Room, Player,
    RoomJoinedResponse, RoomUpdateResponse, ChatMessageResponse
)
from handlers import parse_message
from helpers import send, broadcast, create_room, join_room

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
                    room_id, display_name = create_room(rooms, player_id, request.username)

                    response = RoomJoinedResponse(
                        playerId=player_id,
                        roomId=room_id,
                        displayName=display_name,
                        isHost=True,
                        room=rooms[room_id]
                    )
                    await send(ws, response.model_dump())

                case "join_room":
                    room_id = request.roomId

                    if room_id not in rooms:
                        continue  # Handle errors better later

                    display_name, room = join_room(
                        rooms, player_id, request.username, room_id
                    )

                    await send(ws, RoomJoinedResponse(
                        playerId=player_id,
                        roomId=room_id,
                        displayName=display_name,
                        isHost=False,
                        room=room
                    ).model_dump())

                    await broadcast(
                        rooms,
                        connections,
                        room_id,
                        RoomUpdateResponse(room=room).model_dump()
                    )

                case "send_message":
                    room_id = request.roomId
                    room = rooms[room_id]

                    sender = next(p for p in room.players if p.id == player_id)

                    payload = ChatMessageResponse(
                        type="chat_message",
                        senderId=sender.id,
                        senderDisplayName=sender.displayName,
                        text=request.text
                    ).model_dump()

                    await broadcast(
                        rooms,
                        connections,
                        room_id,
                        payload
                    )

                case "leave_room":
                    room_id = request.roomId

                    if room_id not in rooms: # check if room_id still exists in rooms
                        break

                    room = rooms[room_id]
                    room.players = [p for p in room.players if p.id != player_id] # remove player with specified player_id

                    await broadcast(
                        rooms,
                        connections,
                        room_id,
                        RoomUpdateResponse(room=room).model_dump(),
                        exclude_player_id=player_id # only send update to existing players
                    )

    except WebSocketDisconnect:
        print("Client disconnected:", player_id)

        # Remove player from rooms
        for room_id, room in rooms.items():
            if any(p.id == player_id for p in room.players):
                room.players = [p for p in room.players if p.id != player_id]

                # Broadcast updated room
                await broadcast(
                    rooms,
                    connections,
                    room_id,
                    RoomUpdateResponse(room=room).model_dump(),
                    exclude_player_id=player_id
                )
                break

        connections.pop(player_id, None)
