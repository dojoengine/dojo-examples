use dojo::world::IWorldDispatcher;
use starknet::ContractAddress;

#[starknet::interface]
trait ICommitRevealSystems<TContractState> {
    fn create_game(
        self: @TContractState,
        world: IWorldDispatcher,
        player1: ContractAddress,
        player2: ContractAddress
    ) -> u32;
    fn commit_value(
        self: @TContractState, world: IWorldDispatcher, game_id: u32, commit_value: felt252
    );
    fn reveal_value(
        self: @TContractState,
        world: IWorldDispatcher,
        game_id: u32,
        reveal_value: felt252,
        reveal_secret: felt252
    );
}


#[dojo::contract]
mod commit_reveal_systems {
    use commit_reveal::models::{Game, Statement, Choice, StatementTrait};
    use commit_reveal::models::{IntoFelt252Choice, TryIntoChoiceFelt252};
    use commit_reveal::utils::get_winner;

    use starknet::ContractAddress;

    use core::pedersen::pedersen;
    use core::option::{Option, OptionTrait};

    #[external(v0)]
    fn create_game(
        self: @ContractState,
        world: IWorldDispatcher,
        player1: ContractAddress,
        player2: ContractAddress
    ) -> u32 {
        assert(player1.is_non_zero(), 'invalid player1 address');
        assert(player2.is_non_zero(), 'invalid player2 address');

        let game_id = world.uuid();

        set!(
            world,
            (Game { game_id, player1, player2, winner: starknet::contract_address_const::<0x0>() })
        );

        game_id
    }


    // commit_value = pedersen(value, secret);
    #[external(v0)]
    fn commit_value(
        self: @ContractState, world: IWorldDispatcher, game_id: u32, commit_value: felt252
    ) {
        // retrieve game
        let game = get!(world, game_id, (Game));
        assert(game.game_id.is_non_zero(), 'game doesnt exists');

        // check if caller is player1 or player2
        let caller = starknet::get_caller_address();
        assert(caller == game.player1 || caller == game.player2, 'invalid player');

        // check if player already commited a value
        let mut statement = get!(world, (game_id, caller), (Statement));
        assert(statement.commit_value.is_zero(), 'already committed');

        // write commit
        statement.commit_value = commit_value;
        statement.reveal_value = Choice::Idle;
        set!(world, (statement))
    }


    #[external(v0)]
    fn reveal_value(
        self: @ContractState,
        world: IWorldDispatcher,
        game_id: u32,
        reveal_value_: felt252,
        reveal_secret: felt252
    ) {
        // reveal_value: Choice --> 'Failed to deserialize param #2
        let reveal_value: Choice = reveal_value_.try_into().unwrap();
        assert(reveal_value != Choice::Idle, 'invalid value');

        // retrieve game
        let mut game = get!(world, game_id, (Game));
        assert(game.game_id.is_non_zero(), 'game doesnt exists');
        assert(game.winner.is_zero(), 'game end');

        // check if get_caller_address() is player1 or player2
        let caller = starknet::get_caller_address();
        assert(caller == game.player1 || caller == game.player2, 'invalid player');

        let mut statement = get!(world, (game_id, caller), (Statement));
        // check if player already commited a value
        assert(statement.commit_value.is_non_zero(), 'no value committed');
        // check if player already revealed 
        assert(statement.reveal_secret.is_zero(), 'already revealed');

        // check if commit_value & reveal_value match 
        // commit_value == pedersen(reveal_value, reveal_secret) 
        let excepted_commit_value = pedersen(reveal_value.into(), reveal_secret);
        let is_cheating = statement.commit_value != excepted_commit_value;

        // retrieve opponent address
        let opponent_address = if game.player1 == caller {
            game.player2
        } else {
            game.player1
        };

        let mut opponent_statement = get!(world, (game_id, opponent_address), (Statement));
        // check if opponent already commited
        assert(opponent_statement.commit_value.is_non_zero(), 'waiting opponent commit');

        if is_cheating {
            // opponent wins
            game.winner = opponent_address;
            set!(world, (game));
            return;
        }

        // check if opponent already revealed
        let has_opponent_revealed = opponent_statement.reveal_secret.is_non_zero();

        if !has_opponent_revealed {
            // store reveal_value/reveal_secret if player is first to reveal
            statement.reveal_value = reveal_value;
            statement.reveal_secret = reveal_secret;
            set!(world, (statement));
        } else {
            // finalize game
            let winner = get_winner(
                caller, reveal_value, opponent_address, opponent_statement.reveal_value
            );

            match winner {
                Option::Some(address) => {
                    // set game winner
                    game.winner = address;
                    set!(world, (game));
                },
                Option::None => {
                    // reset both player statements
                    statement.reset(world);
                    opponent_statement.reset(world);
                },
            };
        }
    }
}
