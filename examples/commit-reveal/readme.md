> [!NOTE] 
> This example is not a complete or fully functional implementation of a game. Rather, it serves as a basic demonstration to illustrate how one can integrate the commit reveal scheme into a game world.


## Rock / Paper / Scissor
This is a basic implementation of the famous *Rock / Paper / Scissor* game.

The `create_game` system is used to create games with 2 players addresses.

### Components 

1. **Game**  : Represents a Game between 2 players
- game_id : unique game identifier
- player1 : player 1 address
- player2 : player 2 address
- winner : winner address, (or zero if no winner)

2. **Statement** : Stores infos about commit-reveal for a game_id/player_id
- game_id : unique game identifier
- player_id: player address
- commit_value: player Choice hashed with a secret
- reveal_value: (stored if player if first to reveal)
- reveal_secret: (stored if player if first to reveal)


### Commit - Reveal Scheme

There is 2 phases :

- the commit phase (`commit_value` system) where a player can commit a value without revealing it

The committed value is calculated using pedersen hash function & a salt / secret : 
commit_value = pedersen( clear_value, secret);

- the reveal phase (`reveal_value` system) where the player reveal the commited value and secret used at commit phase.

To reveal the value, the player then send clear_value & secret,
we can then check that the committed value is equal to pedersen(clear_value, secret)

### Blockchain

In a blockchain environement where all datas/txs are public and bots are common users, it allow to commit a value without revealing this value and then proove the integrity of committed value in a second phase.

It can be used for different applications : gaming, voting system, blind auctions, ...

### Salt / Secret

In the current exemple of Rock Paper Scissor, there is only 3 valid value a player can choose. With a fixed salt/secret, one could easily compute hashes for the possible values ( Rock / Paper / Scissor ) and compare it to the opponent committed value.

Therefore the salt/secret used should change each round (as its revealed each round in reveal phase) and should not be guessable by the opponent.