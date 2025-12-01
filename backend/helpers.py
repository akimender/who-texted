from fastapi import WebSocket
import random

from constants import animal_names
from models import Player, Room

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


async def broadcast(rooms, connections, room_id: str, payload: dict, exclude_player_id=None):
    room = rooms.get(room_id)
    if not room:
        print(f"Room {room_id} doesn't exist")
        return
    
    for player in room.players:
        if player.id == exclude_player_id:
            continue
        ws = connections.get(player.id)
        if ws:
            await ws.send_json(payload)


def create_room(rooms, player_id: str, username: str):
    room_id = generate_room_code()
    display_name = get_unique_display_name([]) # assign a display name to hosting player

    host_player = Player(
        id=player_id,
        username=username,
        displayName=display_name,
        isHost=True
    )

    new_room = Room(
        id=room_id,
        hostId=player_id,
        players=[host_player],
        state="lobby",
        currentRound=0,
        currentPrompt=None
    )

    rooms[room_id] = new_room

    return room_id, display_name


def join_room(rooms, player_id: str, username: str, room_id: str):
    room: Room = rooms[room_id]
    display_name = get_unique_display_name(room.players)

    # Create new player for joining player
    new_player = Player(
        id=player_id,
        username=username,
        displayName=display_name,
        isHost=False
    )

    # Add player to room
    room.players.append(new_player)

    return display_name, room