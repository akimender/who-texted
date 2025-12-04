from fastapi import WebSocket
import random
import uuid

from constants import animal_names
from models import Player, Room, Round, Response, Vote
from prompts import generate_prompt

def validate_room_id(request, rooms):
    room_id = request.roomId
    if room_id not in rooms:
        return False
    return True

def generate_room_code(rooms=None):
    """Generate a unique room code. If rooms dict provided, ensures uniqueness."""
    max_attempts = 100
    for _ in range(max_attempts):
        code = "".join(random.choice("ABCDEFGHJKMNPQRTUVWXYZ") for _ in range(4))
        if rooms is None or code not in rooms:
            return code
    # Fallback: use UUID if we can't generate unique code
    return str(uuid.uuid4())[:8].upper()

def get_unique_display_name(players):
    used = {p.displayName for p in players}
    for name in animal_names:
        if name not in used:
            return name
    return "Anonymous"


async def send(ws: WebSocket, payload: dict):
    """Send JSON to a single client."""
    await ws.send_json(payload)


async def broadcast(rooms, connections, room_id: str, payload: dict, exclude_player_id=None):
    room = rooms.get(room_id) # get room information
    if not room:
        print(f"Room {room_id} doesn't exist")
        return
    
    # send payload to every included player in the room (to update)
    for player in room.players:
        if player.id == exclude_player_id:
            continue
        ws = connections.get(player.id)
        if ws:
            print(f"BROADCASTING {payload}")
            await ws.send_json(payload)


def initialize_new_room(rooms, player_id: str, username: str):
    room_id = generate_room_code(rooms)
    display_name = get_unique_display_name([]) # assign a display name to hosting player

    host_player = Player(
        id=player_id,
        username=username,
        displayName=display_name,
        isHost=True,
        points = 0
    )

    new_room = Room(
        id=room_id,
        hostId=player_id,
        players=[host_player],
        state="lobby",
        currentRound=0,
        currentPrompt=None,
        rounds=[]
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
        isHost=False,
        points = 0
    )

    # Add player to room
    room.players.append(new_player)

    return display_name, room


# --- Game Logic Functions ---

def assign_round_roles(players: list, target_player_id: str) -> dict:
    """
    Assigns roles for a round.
    Returns:
    {
        'targetPlayerId': str,
        'promptSenderId': str,  # Random player (not target)
        'realImpersonatorId': str,  # Random player (not target)
        'fakeResponderIds': List[str]  # All other players
    }
    """
    # Get all player IDs except the target
    available_players = [p.id for p in players if p.id != target_player_id]
    
    if len(available_players) < 2:
        raise ValueError("Not enough players for role assignment (need at least 3 players)")
    
    # Randomly select prompt sender (different from target)
    prompt_sender_id = random.choice(available_players)
    
    # Randomly select real impersonator (different from target and sender)
    real_impersonator_candidates = [p for p in available_players if p != prompt_sender_id]
    real_impersonator_id = random.choice(real_impersonator_candidates)
    
    # All other players (except target and real impersonator) are fake responders
    fake_responder_ids = [p.id for p in players if p.id != target_player_id and p.id != real_impersonator_id]
    
    return {
        'targetPlayerId': target_player_id,
        'promptSenderId': prompt_sender_id,
        'realImpersonatorId': real_impersonator_id,
        'fakeResponderIds': fake_responder_ids
    }


async def start_new_round(room: Room, rooms: dict, connections: dict) -> None:
    """
    Starts a new round according to specification:
    - Creates new Round object
    - Sends RoundSetupResponse (optional UX enhancement)
    - Sends PromptDisplayResponse to all players
    """
    round_number = room.currentRound
    round_data = initialize_round(room, round_number)
    room.currentRoundData = round_data
    room.currentPrompt = round_data.prompt
    
    # Get player names
    target_player = next((p for p in room.players if p.id == round_data.targetPlayerId), None)
    sender_player = next((p for p in room.players if p.id == round_data.promptSenderId), None)
    
    if not target_player or not sender_player:
        raise ValueError("Target or sender player not found")
    
    target_name = target_player.displayName or target_player.username
    sender_name = sender_player.displayName or sender_player.username
    
    # Send RoundSetupResponse to responding players (UX enhancement - not in spec but useful)
    from models import RoundSetupResponse
    for player in room.players:
        if player.id == round_data.targetPlayerId:
            continue  # Target doesn't respond
        
        role = "real_impersonator" if player.id == round_data.realImpersonatorId else "fake_responder"
        ws = connections.get(player.id)
        if ws:
            response = RoundSetupResponse(
                room=room,
                targetPlayerName=target_name,
                promptSenderName=sender_name,
                yourRole=role
            ).model_dump()
            await send(ws, response)
    
    # Send PromptDisplayResponse to all players (spec requirement)
    from models import PromptDisplayResponse
    prompt_response = PromptDisplayResponse(
        room=room,
        promptText=round_data.prompt,
        targetPlayerName=target_name
    ).model_dump()
    
    # Broadcast to all players (use room.id as room_id)
    await broadcast(rooms, connections, room.id, prompt_response)


def initialize_round(room: Room, round_number: int) -> Round:
    """
    Initializes a new round:
    - Selects target player (round-robin or random)
    - Assigns roles
    - Generates prompt
    - Creates new Round object
    """
    players = room.players
    
    if len(players) < 3:
        raise ValueError("Need at least 3 players to start a round")
    
    # Select target player (round-robin based on round number)
    target_index = (round_number - 1) % len(players)
    target_player = players[target_index]
    
    # Assign roles
    roles = assign_round_roles(players, target_player.id)
    
    # Get player names for prompt generation
    target_name = target_player.displayName or target_player.username
    sender_player = next((p for p in players if p.id == roles['promptSenderId']), None)
    if not sender_player:
        raise ValueError(f"Prompt sender {roles['promptSenderId']} not found in players")
    sender_name = sender_player.displayName or sender_player.username
    
    # Generate prompt
    prompt_text = generate_prompt(target_name, sender_name)
    
    # Create round
    new_round = Round(
        id=str(uuid.uuid4()),
        roundNumber=round_number,
        prompt=prompt_text,
        targetPlayerId=roles['targetPlayerId'],
        promptSenderId=roles['promptSenderId'],
        realImpersonatorId=roles['realImpersonatorId'],
        responses=[],
        votes=[],
        state="prompt"
    )
    
    return new_round


def validate_response(room: Room, player_id: str, response_text: str) -> bool:
    """
    Validates a response submission.
    - Checks if player is in room
    - Checks if game is in 'responding' state
    - Checks if player hasn't already submitted
    - Checks if player is NOT the target (target doesn't respond)
    - Validates response length
    """
    if not room.currentRoundData:
        return False
    
    # Check if round is in responding state (Room.state is "playing" during game)
    if not room.currentRoundData or room.currentRoundData.state != "responding":
        return False
    
    # Check if player is in room
    player = next((p for p in room.players if p.id == player_id), None)
    if not player:
        return False
    
    # Check if player is the target (target doesn't respond)
    if player_id == room.currentRoundData.targetPlayerId:
        return False
    
    # Check if player already submitted
    existing_response = next(
        (r for r in room.currentRoundData.responses if r.playerId == player_id),
        None
    )
    if existing_response:
        return False
    
    # Validate response length (1-200 characters)
    if not response_text or len(response_text.strip()) == 0:
        return False
    if len(response_text) > 200:
        return False
    
    return True


def process_response(room: Room, player_id: str, response_text: str) -> Response:
    """
    Processes and stores a response submission.
    Returns the created Response object.
    Note: We store playerId in Response for internal use, but hide it in VotingPhaseResponse
    """
    round_data = room.currentRoundData
    is_real = (player_id == round_data.realImpersonatorId)
    
    response = Response(
        id=str(uuid.uuid4()),
        playerId=player_id,  # Store for reveal/scoring, but hide in voting phase
        text=response_text.strip(),
        isReal=is_real,
        voteCount=0
    )
    
    round_data.responses.append(response)
    return response


def check_all_responses_submitted(room: Room) -> bool:
    """
    Checks if all players have submitted responses.
    """
    if not room.currentRoundData:
        return False
    
    # All players except target should submit
    expected_responders = [p.id for p in room.players if p.id != room.currentRoundData.targetPlayerId]
    # Responses have playerId set (not None) when stored
    submitted_ids = {r.playerId for r in room.currentRoundData.responses if r.playerId is not None}
    
    return len(expected_responders) == len(submitted_ids) and all(
        pid in submitted_ids for pid in expected_responders
    )


def process_vote(room: Room, voter_id: str, response_id: str) -> bool:
    """
    Processes a vote submission.
    Returns True if all players have voted.
    """
    if not room.currentRoundData:
        return False
    
    # Check if round is in voting state (Room.state is "playing" during game)
    if not room.currentRoundData or room.currentRoundData.state != "voting":
        return False
    
    # Check if voter is the target (target doesn't vote)
    if voter_id == room.currentRoundData.targetPlayerId:
        return False
    
    # Check if player already voted
    existing_vote = next(
        (v for v in room.currentRoundData.votes if v.voterId == voter_id),
        None
    )
    if existing_vote:
        return False
    
    # Check if response exists
    response = next(
        (r for r in room.currentRoundData.responses if r.id == response_id),
        None
    )
    if not response:
        return False
    
    # Record vote
    vote = Vote(voterId=voter_id, responseId=response_id)
    room.currentRoundData.votes.append(vote)
    
    # Update vote count on response
    response.voteCount += 1
    
    # Check if all players have voted (all except target player)
    expected_voters = [p.id for p in room.players if p.id != room.currentRoundData.targetPlayerId]
    voted_ids = {v.voterId for v in room.currentRoundData.votes}
    
    return len(expected_voters) == len(voted_ids) and all(
        vid in voted_ids for vid in expected_voters
    )


def calculate_round_scores(round_data: Round, players: list) -> dict:
    """
    Calculates scores for a completed round.
    Returns:
    {
        player_id: {
            'points_earned': int,
            'reason': str
        }
    }
    """
    scores = {p.id: {'points_earned': 0, 'reason': ''} for p in players}
    
    # Get real response
    real_response = next((r for r in round_data.responses if r.isReal), None)
    if not real_response:
        return scores
    
    # Count correct guesses (votes for real response)
    correct_guesses = [v for v in round_data.votes if v.responseId == real_response.id]
    num_correct = len(correct_guesses)
    num_wrong = len(round_data.votes) - num_correct
    
    # Real Impersonator scoring (per spec)
    # +2 per correct guess, +1 per fooled guess (wrong guess)
    real_impersonator_points = (num_correct * 2) + num_wrong
    scores[round_data.realImpersonatorId]['points_earned'] = real_impersonator_points
    scores[round_data.realImpersonatorId]['reason'] = f"Real response: {num_correct} correct guesses (+{num_correct * 2}), {num_wrong} fooled (+{num_wrong})"
    
    # Fake Responders scoring
    # +1 per vote received
    for response in round_data.responses:
        if not response.isReal and response.playerId:
            # Only score if playerId exists (defensive check)
            if response.playerId in scores:
                fake_points = response.voteCount
                scores[response.playerId]['points_earned'] = fake_points
                if fake_points > 0:
                    scores[response.playerId]['reason'] = f"Fake response received {fake_points} vote(s)"
                else:
                    scores[response.playerId]['reason'] = "Fake response received 0 votes"
    
    # Guessers scoring
    # +1 for correctly identifying real response
    for vote in correct_guesses:
        if vote.voterId != round_data.realImpersonatorId:  # Don't double-count
            scores[vote.voterId]['points_earned'] += 1
            if scores[vote.voterId]['reason']:
                scores[vote.voterId]['reason'] += f", +1 for correct guess"
            else:
                scores[vote.voterId]['reason'] = "+1 for correct guess"
    
    return scores


def check_round_completion(room: Room) -> bool:
    """
    Checks if round is complete (all responses submitted and all votes cast).
    """
    if not room.currentRoundData:
        return False
    
    # Check responses
    expected_responders = [p.id for p in room.players if p.id != room.currentRoundData.targetPlayerId]
    # Responses have playerId set (not None) when stored
    submitted_ids = {r.playerId for r in room.currentRoundData.responses if r.playerId is not None}
    all_responses_submitted = len(expected_responders) == len(submitted_ids)
    
    # Check votes
    expected_voters = [p.id for p in room.players if p.id != room.currentRoundData.targetPlayerId]
    voted_ids = {v.voterId for v in room.currentRoundData.votes}
    all_voted = len(expected_voters) == len(voted_ids)
    
    return all_responses_submitted and all_voted


def check_game_completion(room: Room) -> bool:
    """
    Returns True if currentRound >= maxRounds.
    """
    return room.currentRound >= room.maxRounds


def validate_state_transition(current_state: str, new_state: str) -> bool:
    """
    Validates legal state transitions.
    """
    valid_transitions = {
        "lobby": ["roundSetup"],
        "roundSetup": ["prompt"],
        "prompt": ["responding"],
        "responding": ["voting"],
        "voting": ["reveal"],
        "reveal": ["scoring"],
        "scoring": ["roundSetup", "finished"],
        "finished": []
    }
    
    return new_state in valid_transitions.get(current_state, [])