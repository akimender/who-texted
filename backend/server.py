from fastapi import FastAPI, WebSocket, WebSocketDisconnect
import uuid
import random

app = FastAPI()

rooms = {}     # roomId: { "players": [..], "hostId": str }
connections = {}  # playerId: WebSocket

animal_names = [
    "Otter", "Giraffe", "Panda", "Walrus",
    "Falcon", "Tiger", "Koala", "Hawk"
]

def get_unique_display_name(players):
    used = {p["displayName"] for p in players}
    for name in animal_names:
        if name not in used:
            return name
    return "Player"


@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    await ws.accept()

    player_id = str(uuid.uuid4())
    connections[player_id] = ws
    print("Client connected:", player_id)

    try:
        while True:
            data = await ws.receive_json()

            # ---- CREATE ROOM ----
            if data["type"] == "create_room":
                username = data["username"]
                room_id = "".join(random.choice("ABCDEFGHJKMNPQRTUVWXYZ") for _ in range(4))

                display_name = get_unique_display_name([])

                rooms[room_id] = {
                    "players": [{
                        "id": player_id,
                        "username": username,
                        "displayName": display_name,
                        "isHost": True
                    }],
                    "hostId": player_id
                }

                await ws.send_json({
                    "type": "room_joined",
                    "playerId": player_id,
                    "roomId": room_id,
                    "displayName": display_name,
                    "isHost": True,
                    "room": rooms[room_id]
                })

            # ---- JOIN ROOM ----
            elif data["type"] == "join_room":
                username = data["username"]
                room_id = data["roomId"]

                if room_id not in rooms:
                    await ws.send_json({
                        "type": "join_failed",
                        "reason": "Room does not exist"
                    })
                    continue

                room = rooms[room_id]

                display_name = get_unique_display_name(room["players"])

                new_player = {
                    "id": player_id,
                    "username": username,
                    "displayName": display_name,
                    "isHost": False
                }
                room["players"].append(new_player)

                # Send room_joined only to the new player
                await ws.send_json({
                    "type": "room_joined",
                    "playerId": player_id,
                    "roomId": room_id,
                    "displayName": display_name,
                    "isHost": False,
                    "room": room
                })

                # Broadcast room update to all players except new one
                for p_id, conn in connections.items():
                    if p_id != player_id:
                        await conn.send_json({
                            "type": "room_update",
                            "room": room
                        })

    except WebSocketDisconnect:
        print("Client disconnected:", player_id)
        del connections[player_id]
