from fastapi import WebSocket
import random

from constants import animal_names

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


async def broadcast(rooms, connections, room_id: str, payload: dict):
    """Send JSON to all players in a room."""
    for player in rooms[room_id]["players"]:
        pid = player["id"]
        ws = connections.get(pid)
        if ws:
            await ws.send_json(payload)


def create_room(rooms, player_id: str, username: str):
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


def join_room(rooms, player_id: str, username: str, room_id: str):
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