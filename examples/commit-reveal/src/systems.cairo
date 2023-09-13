#[system]
mod create_game {
    use option::Option;

    use starknet::ContractAddress;
    use dojo::world::Context;

    use commit_reveal::components::{Game};

    fn execute(ctx: Context, player1: ContractAddress, player2: ContractAddress) -> u32 {
        assert(player1.is_non_zero(), 'invalid player1 address');
        assert(player2.is_non_zero(), 'invalid player2 address');

        let game_id = ctx.world.uuid();

        set!(
            ctx.world,
            (Game { game_id, player1, player2, winner: starknet::contract_address_const::<0x0>() })
        );

        game_id
    }
}


#[system]
mod commit_value {
    use starknet::ContractAddress;
    use dojo::world::Context;

    use commit_reveal::components::{Game, Statement, Choice};

    // commit_value = pedersen(value, secret);
    fn execute(ctx: Context, game_id: u32, commit_value: felt252) {
        // retrieve game
        let game = get!(ctx.world, game_id, (Game));
        assert(game.game_id.is_non_zero(), 'game doesnt exists');

        // check if ctx.origin is player1 or player2
        assert(ctx.origin == game.player1 || ctx.origin == game.player2, 'invalid player');

        // check if player already commited a value
        let mut statement = get!(ctx.world, (game_id, ctx.origin), (Statement));
        assert(statement.commit_value.is_zero(), 'already committed');

        // write commit
        statement.commit_value = commit_value;
        statement.reveal_value = Choice::Idle;
        set!(ctx.world, (statement))
    }
}

#[system]
mod reveal_value {
    use starknet::ContractAddress;
    use dojo::world::Context;
    use option::OptionTrait;
    use core::pedersen::pedersen;

    use commit_reveal::components::{Game, Statement, Choice, StatementTrait};
    use commit_reveal::components::{IntoFelt252Choice, TryIntoChoiceFelt252};

    use super::get_winner;

    use debug::PrintTrait;

    fn execute(ctx: Context, game_id: u32, reveal_value_: felt252, reveal_secret: felt252) {
        // reveal_value: Choice --> 'Failed to deserialize param #2
        let reveal_value: Choice = reveal_value_.try_into().unwrap();
        assert(reveal_value != Choice::Idle, 'invalid value');

        // retrieve game
        let mut game = get!(ctx.world, game_id, (Game));
        assert(game.game_id.is_non_zero(), 'game doesnt exists');
        assert(game.winner.is_zero(), 'game end');

        // check if ctx.origin is player1 or player2
        assert(ctx.origin == game.player1 || ctx.origin == game.player2, 'invalid player');

        let mut statement = get!(ctx.world, (game_id, ctx.origin), (Statement));
        // check if player already commited a value
        assert(statement.commit_value.is_non_zero(), 'no value committed');
        // check if player already revealed 
        assert(statement.reveal_secret.is_zero(), 'already revealed');

        // check if commit_value & reveal_value match 
        // commit_value == pedersen(reveal_value, reveal_secret) 
        let excepted_commit_value = pedersen(reveal_value.into(), reveal_secret);
        let is_cheating = statement.commit_value != excepted_commit_value;

        // retrieve opponent address
        let opponent_address = if game.player1 == ctx.origin {
            game.player2
        } else {
            game.player1
        };

        let mut opponent_statement = get!(ctx.world, (game_id, opponent_address), (Statement));
        // check if opponent already commited
        assert(opponent_statement.commit_value.is_non_zero(), 'waiting opponent commit');

        if is_cheating {
            'cheating'.print();
            // opponent wins
            game.winner = opponent_address;
            set!(ctx.world, (game));
            return;
        }

        // check if opponent already revealed
        let has_opponent_revealed = opponent_statement.reveal_secret.is_non_zero();

        'has_opponent_revealed'.print();
        has_opponent_revealed.print();

        if !has_opponent_revealed {
            // store reveal_value/reveal_secret if player is first to reveal
            statement.reveal_value = reveal_value;
            statement.reveal_secret = reveal_secret;
            set!(ctx.world, (statement));
        } else {
            // finalize game
            let winner = get_winner(
                ctx.origin, reveal_value, opponent_address, opponent_statement.reveal_value
            );

            match winner {
                Option::Some(address) => {
                    'winner'.print();
                    address.print();
                    // set game winner
                    game.winner = address;
                    set!(ctx.world, (game));
                },
                Option::None => {
                    'even'.print();
                    // reset both player statements
                    statement.reset(ctx);
                    opponent_statement.reset(ctx);
                },
            };
        }
    }
}


use starknet::ContractAddress;
use commit_reveal::components::Choice;

fn get_winner(
    player_address: ContractAddress,
    player_choice: Choice,
    opponent_address: ContractAddress,
    opponent_choice: Choice
) -> Option<ContractAddress> {
    match player_choice {
        Choice::Idle => {
            Option::None
        },
        Choice::Rock => {
            match opponent_choice {
                Choice::Idle => {
                    Option::None
                },
                Choice::Rock => {
                    Option::None
                },
                Choice::Paper => {
                    Option::Some(opponent_address)
                },
                Choice::Scissor => {
                    Option::Some(player_address)
                },
            }
        },
        Choice::Paper => {
            match opponent_choice {
                Choice::Idle => {
                    Option::None
                },
                Choice::Rock => {
                    Option::Some(player_address)
                },
                Choice::Paper => {
                    Option::None
                },
                Choice::Scissor => {
                    Option::Some(opponent_address)
                },
            }
        },
        Choice::Scissor => {
            match opponent_choice {
                Choice::Idle => {
                    Option::None
                },
                Choice::Rock => {
                    Option::Some(opponent_address)
                },
                Choice::Paper => {
                    Option::Some(player_address)
                },
                Choice::Scissor => {
                    Option::None
                },
            }
        }
    }
}
