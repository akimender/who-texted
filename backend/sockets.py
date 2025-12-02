import random

from models import (
    RoomJoinedResponse, RoomUpdateResponse, ChatMessageResponse, GameStartedResponse
)

from helpers import send, broadcast, initialize_new_room, join_room

async def handle_create_room(ws, rooms, request, player_id):
    room_id, display_name = initialize_new_room(rooms, player_id, request.username)

    response = RoomJoinedResponse(
        playerId=player_id,
        roomId=room_id,
        displayName=display_name,
        isHost=True,
        room=rooms[room_id]
    ).model_dump()

    await send(ws, response)

async def handle_join_room(ws, rooms, connections, request, player_id):
    room_id = request.roomId

    display_name, room = join_room(
        rooms, player_id, request.username, room_id
    )

    response = RoomJoinedResponse(
        playerId=player_id,
        roomId=room_id,
        displayName=display_name,
        isHost=True,
        room=rooms[room_id]
    ).model_dump()

    await send(ws, response)

    payload = RoomUpdateResponse(room=room).model_dump()

    await broadcast(
        rooms=rooms,
        connections=connections,
        room_id=room_id,
        payload=payload
    )

async def handle_start_game(rooms, connections, request):
    room_id = request.roomId
    rooms[room_id].state = "game_starting" # temporary for now - need to test joining game together
    rooms[room_id].currentRound = 1

    response = GameStartedResponse(room=rooms[room_id]).model_dump()

    await broadcast(
        rooms, connections, room_id, response
    )

async def handle_send_message(rooms, connections, request, player_id):
    room_id = request.roomId

    sender = next(p for p in rooms[room_id].players if p.id == player_id)

    payload = ChatMessageResponse(
        type="chat_message",
        senderId=sender.id,
        senderDisplayName=sender.displayName,
        text=request.text
    ).model_dump()

    await broadcast(
        rooms=rooms,
        connections=connections,
        room_id=room_id,
        payload=payload
    )

async def handle_leave_room(rooms, connections, request, player_id):
    room_id = request.roomId

    leaving_player = next((p for p in rooms[room_id].players if p.id == player_id), None)

    rooms[room_id].players = [p for p in rooms[room_id].players if p.id != player_id] # remove player with specified player_id

    if leaving_player and leaving_player.isHost and len(rooms[room_id].players) > 0:
        random_player_index = random.randint(0, len(rooms[room_id].players) - 1)
        rooms[room_id].players[random_player_index].isHost = True

    # if room has no players, remove the room from rooms
    if len(rooms[room_id].players) > 0:
        response = RoomUpdateResponse(room=rooms[room_id]).model_dump()
        await broadcast(
            rooms=rooms,
            connections=connections,
            room_id=room_id,
            payload=response,
            exclude_player_id=player_id # only send update to existing players
        )
    else:
        del rooms[room_id]

async def handle_disconnect(rooms, connections, player_id):
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