from fastapi import FastAPI, WebSocket, WebSocketDisconnect
import uuid
import random
import json

app = FastAPI()

rooms = {}
connections = {}

animal_names = [
    "Otter", "Giraffe", "Panda", "Walrus",
    "Falcon", "Tiger", "Koala", "Hawk"
]


### HELPER METHODS ###
def generate_room_code():
    return "".join(random.choice("ABCDEFGHJKMNPQRTUVWXYZ") for _ in range(4))


def get_unique_display_name(players):
    used = {p["displayName"] for p in players}
    for name in animal_names:
        if name not in used:
            return name
    return "Player"


async def send(ws: WebSocket, payload: dict):
    """Send JSON to a single client."""
    await ws.send_json(payload)


async def broadcast(room_id: str, payload: dict, exclude_player_id=None):
    """Send JSON to all players in a room."""
    for player in rooms[room_id]["players"]:
        pid = player["id"]
        if pid == exclude_player_id:
            continue
        ws = connections.get(pid)
        if ws:
            await ws.send_json(payload)


def create_room(player_id: str, username: str):
    room_id = generate_room_code()
    display_name = get_unique_display_name([]) # assign a display name to hosting player

    new_room = {
        "id": room_id,
        "hostId": player_id,
        "players": [{
            "id": player_id,
            "username": username,
            "displayName": display_name,
            "isHost": True
        }],
        "state": "lobby",
        "currentRound": 0,
        "currentPrompt": None
    }

    rooms[room_id] = new_room

    return room_id, display_name


def join_room(player_id: str, username: str, room_id: str):
    room = rooms[room_id]
    display_name = get_unique_display_name(room["players"])

    new_player = {
        "id": player_id,
        "username": username,
        "displayName": display_name,
        "isHost": False
    }

    room["players"].append(new_player)

    return display_name, room


### WEBSOCKET ENDPOINT ###
@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
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
                room_id, display_name = create_room(player_id, username)

                await send(ws, {
                    "type": "room_joined",
                    "playerId": player_id,
                    "roomId": room_id,
                    "displayName": display_name,
                    "isHost": True,
                    "room": rooms[room_id]   # now full room data
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

                display_name, room = join_room(player_id, username, room_id)

                # Send to the player who joined
                await send(ws, {
                    "type": "room_joined",
                    "playerId": player_id,
                    "roomId": room_id,
                    "displayName": display_name,
                    "isHost": False,
                    "room": room
                })

                # Broadcast updated room to others
                await broadcast(room_id, {
                    "type": "room_update",
                    "room": room
                }, exclude_player_id=player_id)

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

                await broadcast(room_id, message_payload)

    except WebSocketDisconnect:
        print("Client disconnected:", player_id)
        connections.pop(player_id, None)
