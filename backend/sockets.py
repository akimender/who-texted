import random
import asyncio

from models import (
    RoomJoinedResponse, RoomUpdateResponse, ChatMessageResponse, GameStartedResponse,
    RoundSetupResponse, PromptDisplayResponse, ResponseSubmittedResponse,
    VotingPhaseResponse, VoteSubmittedResponse, RevealPhaseResponse,
    ScoringPhaseResponse, RoundCompleteResponse, GameFinishedResponse
)

from helpers import (
    send, broadcast, initialize_new_room, join_room,
    initialize_round, start_new_round, validate_response, process_response,
    check_all_responses_submitted, process_vote, calculate_round_scores,
    check_game_completion, validate_state_transition
)

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
        isHost=False,
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

async def handle_start_game(rooms, connections, request, player_id):
    room_id = request.roomId
    room = rooms[room_id]
    
    # Validate host
    # May delete because frontend only shows start game button to host anyway
    host = next((p for p in room.players if p.id == player_id), None)
    if not host or not host.isHost:
        print(f"Player {player_id} is not the host, cannot start game")
        return
    
    # Validate minimum players
    if len(room.players) < 3:
        print(f"Need at least 3 players to start game, currently {len(room.players)}")
        return
    
    # Set room state to "playing" (per spec)
    room.currentRound = 1
    room.state = "playing"
    
    try:        
        # Use start_new_round helper (per spec) - this creates round and sends messages
        await start_new_round(room, rooms, connections)
        
        # Broadcast room update AGAIN after round is created so all players get complete state with round data
        complete_update = GameStartedResponse(room=room).model_dump()
        await broadcast(rooms, connections, room_id, complete_update)
        
        # After a delay, transition round to responding state
        await asyncio.sleep(3)  # Give players time to see prompt
        
    except Exception as e:
        print(f"Error starting game: {e}")
        room.state = "lobby"
        room.currentRound = 0
        room.currentRoundData = None
        room.currentPrompt = None

async def handle_send_message(rooms, connections, request, player_id):
    room_id = request.roomId
    
    if room_id not in rooms:
        print(f"Room {room_id} not found")
        return

    sender = next((p for p in rooms[room_id].players if p.id == player_id), None)
    if not sender:
        print(f"Player {player_id} not found in room {room_id}")
        return

    payload = ChatMessageResponse(
        type="chat_message",
        senderId=sender.id,
        senderDisplayName=sender.displayName or sender.username,  # Fallback to username if displayName is None
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
    
    if room_id not in rooms:
        print(f"Room {room_id} not found")
        return

    leaving_player = next((p for p in rooms[room_id].players if p.id == player_id), None)

    rooms[room_id].players = [p for p in rooms[room_id].players if p.id != player_id] # remove player with specified player_id

    if leaving_player and leaving_player.isHost and len(rooms[room_id].players) > 0:
        random_player_index = random.randint(0, len(rooms[room_id].players) - 1)
        rooms[room_id].players[random_player_index].isHost = True
        rooms[room_id].hostId = rooms[room_id].players[random_player_index].id

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

async def handle_submit_response(rooms, connections, request, player_id):
    """Handle response submission from a player."""
    room_id = request.roomId
    room = rooms.get(room_id)
    
    if not room or not room.currentRoundData:
        print(f"Room {room_id} or round data not found")
        return
    
    # Validate response
    if not validate_response(room, player_id, request.text):
        print(f"Invalid response from player {player_id}")
        return
    
    # Process response
    response = process_response(room, player_id, request.text)
    
    # Check if all submitted
    all_submitted = check_all_responses_submitted(room)
    
    # Send confirmation to submitting player
    ws = connections.get(player_id)
    if ws:
        confirm_response = ResponseSubmittedResponse(
            room=room,
            allSubmitted=all_submitted
        ).model_dump()
        await send(ws, confirm_response)
    
    # If all submitted, transition to voting
    if all_submitted:
        # Room.state stays "playing", only Round.state changes
        room.currentRoundData.state = "voting"
        
        # Create anonymous responses for voting (hide playerId and isReal status)
        # Note: Original responses have playerId set, but we create new anonymous copies for voting
        anonymous_responses = [
            Response(
                id=r.id,
                playerId=None,  # Already None per spec
                text=r.text,
                isReal=False,  # Hide real status
                voteCount=0
            ) for r in room.currentRoundData.responses
        ]
        
        # Broadcast voting phase to all players
        voting_response = VotingPhaseResponse(
            room=room,
            responses=anonymous_responses
        ).model_dump()
        
        await broadcast(rooms, connections, room_id, voting_response)


async def handle_submit_vote(rooms, connections, request, player_id):
    """Handle vote submission from a player."""
    room_id = request.roomId
    room = rooms.get(room_id)
    
    if not room or not room.currentRoundData:
        print(f"Room {room_id} or round data not found")
        return
    
    # Process vote
    all_voted = process_vote(room, player_id, request.responseId)
    
    # Send confirmation to voting player
    ws = connections.get(player_id)
    if ws:
        confirm_response = VoteSubmittedResponse(
            room=room,
            allVoted=all_voted
        ).model_dump()
        await send(ws, confirm_response)
    
    # If all voted, transition to reveal
    if all_voted:
        # Room.state stays "playing", only Round.state changes
        room.currentRoundData.state = "reveal"
        
        # Broadcast reveal phase with all information (playerIds already in responses)
        reveal_response = RevealPhaseResponse(
            room=room,
            responses=room.currentRoundData.responses,  # playerId already set
            votes=room.currentRoundData.votes
        ).model_dump()
        
        await broadcast(rooms, connections, room_id, reveal_response)
        
        # After 5 seconds, transition to scoring
        await asyncio.sleep(5)
        
        # Calculate scores
        scores = calculate_round_scores(room.currentRoundData, room.players)
        
        # Update player points
        for player in room.players:
            if player.id in scores:
                player.points += scores[player.id]['points_earned']
        
        # Transition to scoring (Room.state stays "playing")
        room.currentRoundData.state = "scoring"
        
        # Create round summary (convert all values to strings for JSON compatibility)
        round_summary = {
            'roundNumber': str(room.currentRoundData.roundNumber),
            'targetPlayerId': room.currentRoundData.targetPlayerId,
            'realImpersonatorId': room.currentRoundData.realImpersonatorId,
            'totalVotes': str(len(room.currentRoundData.votes))
        }
        
        scoring_response = ScoringPhaseResponse(
            room=room,
            scores={pid: data['points_earned'] for pid, data in scores.items()},
            roundSummary=round_summary
        ).model_dump()
        
        await broadcast(rooms, connections, room_id, scoring_response)
        
        # Store completed round
        room.rounds.append(room.currentRoundData)
        
        # Send round complete message (optional - can be used for UI transitions)
        complete_response = RoundCompleteResponse(room=room).model_dump()
        await broadcast(rooms, connections, room_id, complete_response)


async def handle_next_round(rooms, connections, request, player_id):
    """Handle transition to next round."""
    room_id = request.roomId
    room = rooms.get(room_id)
    
    if not room:
        print(f"Room {room_id} not found")
        return
    
    # Validate host
    host = next((p for p in room.players if p.id == player_id), None)
    if not host or not host.isHost:
        print(f"Player {player_id} is not the host")
        return
    
    # Check if game is complete
    if check_game_completion(room):
        # Game finished
        room.state = "finished"
        
        # Find winner
        if not room.players:
            print("No players in room, cannot determine winner")
            return
        
        # Find player(s) with max points (handle ties)
        max_points = max(p.points for p in room.players)
        winners = [p for p in room.players if p.points == max_points]
        winner = winners[0]  # Use first winner if tie
        final_scores = {p.id: p.points for p in room.players}
        
        finished_response = GameFinishedResponse(
            room=room,
            finalScores=final_scores,
            winner=winner
        ).model_dump()
        
        await broadcast(rooms, connections, room_id, finished_response)
        return
    
    # Start next round
    room.currentRound += 1
    # Room.state stays "playing"
    
    try:
        # Use start_new_round helper (per spec)
        await start_new_round(room, rooms, connections)
        
        # Broadcast room update
        update_response = RoomUpdateResponse(room=room).model_dump()
        await broadcast(rooms, connections, room_id, update_response)
        
        # After delay, transition round to responding state
        await asyncio.sleep(3)  # Give players time to see prompt
        
        if room.currentRoundData:
            room.currentRoundData.state = "responding"
            # Broadcast state update
            update_response = RoomUpdateResponse(room=room).model_dump()
            await broadcast(rooms, connections, room_id, update_response)
        
    except Exception as e:
        print(f"Error starting next round: {e}")
        room.state = "lobby"
        room.currentRoundData = None
        room.currentPrompt = None


async def handle_disconnect(rooms, connections, player_id):
    print("Client disconnected:", player_id)

    # Remove player from rooms
    for room_id, room in rooms.items():
        if any(p.id == player_id for p in room.players):
            room.players = [p for p in room.players if p.id != player_id]
            
            # If game is in progress, clean up player's responses and votes
            if room.currentRoundData:
                # Remove player's responses
                room.currentRoundData.responses = [
                    r for r in room.currentRoundData.responses 
                    if r.playerId != player_id
                ]
                # Remove player's votes
                room.currentRoundData.votes = [
                    v for v in room.currentRoundData.votes 
                    if v.voterId != player_id
                ]
                
                # If player was the target, we need to handle this specially
                # For now, if target disconnects, we'll let the round continue
                # but this is a game-breaking scenario that should be handled better
                if room.currentRoundData.targetPlayerId == player_id:
                    print(f"WARNING: Target player {player_id} disconnected during round!")

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