"""
Prompt templates for the game.
These are formatted with {target} (person being impersonated) and {sender} (person who sent the message).
"""

PROMPT_TEMPLATES = [
    "{sender} why did you leave your hoodie at my house again??",
    "{sender} can you pick me up from the airport tomorrow?",
    "{sender} did you see what happened at the party last night?",
    "{sender} are you free this weekend?",
    "{sender} can you help me move next week?",
    "{sender} did you finish the project we were working on?",
    "{sender} where did you put my keys?",
    "{sender} can you cover my shift tomorrow?",
    "{sender} did you remember to feed my cat?",
    "{sender} are you coming to the game tonight?",
    "{sender} can you lend me some money?",
    "{sender} did you see my text from yesterday?",
    "{sender} are you still mad at me?",
    "{sender} can you grab me some coffee on your way?",
    "{sender} did you talk to {target} about what happened?",
    "{sender} are you going to the concert this weekend?",
    "{sender} can you proofread my essay?",
    "{sender} did you get my package?",
    "{sender} are you okay? I haven't heard from you.",
    "{sender} can you pick up some groceries?",
    "{sender} did you see the new episode?",
    "{sender} are you free to hang out tonight?",
    "{sender} can you help me with my homework?",
    "{sender} did you remember to lock the door?",
    "{sender} are you coming to dinner?",
]

def generate_prompt(target_player_name: str, sender_player_name: str) -> str:
    """Generate a random prompt by selecting a template and filling in player names."""
    import random
    template = random.choice(PROMPT_TEMPLATES)
    return template.format(target=target_player_name, sender=sender_player_name)

