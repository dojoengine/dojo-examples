> [!NOTE] 
> This example is not a complete or fully functional implementation of the Battleship game. Rather, it serves as a basic demonstration to illustrate how one can integrate the dojo ERC20 library into a game world.

## Battleship Game with Token Rewards
In this example, we delve into the mechanics of a traditional Battleship board game with a modern twist, where two players engage in naval warfare, strategically seeking to sink each other's ships. Unlike the classic game, this version integrates the ERC20 token system through the dojo's ERC20 crate, tying players' actions with financial incentives and penalties.

### Game Overview
Players are set against each other on a virtual sea grid, deploying a fleet of ships and taking turns to launch attacks on specific grid coordinates (x, y). This game is not just about winning battles; it's also about earning ERC20 tokens, which are transferred among players based on their actions and the outcomes of those actions.

#### How it Works: A Step-by-Step Guide
1. **Initialization:** Each player places their ships on the grid. The game is now ready to begin, and the ERC20 tokens are prepared for transfer through dojo's ERC20 crate.
2. **Attack System:** On a player's turn, they call the attack system, submitting the coordinates (x, y) of their attack.
   - **Successful Attack:** If the chosen coordinates correspond to a defender's ship position, the attacker will receive 1 ERC20 token with a precision of 18 decimals. The defender's Ships and Fleet models will be updated accordingly to reflect the damage.
   - **Unsuccessful Attack:** If the coordinates do not correspond to a ship, no tokens are transferred, and the game continues with the next player's turn.
3. **Winning the Game:** The game continues until one player's entire fleet is sunk. The victorious player will have accumulated ERC20 tokens throughout the game, reflecting their strategic prowess.

#### Integration with dojo's ERC20 Crate
Transfers of ERC20 tokens between players are handled securely and transparently, leveraging dojo's ERC20 crate. This allows the game to bridge traditional entertainment with the emerging world of blockchain and digital assets, offering players not only a competitive challenge but also a potential financial reward.



