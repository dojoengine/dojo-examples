use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo::database::schema::{Enum, Ty, SchemaIntrospection, serialize_member_type};

use starknet::ContractAddress;

use core::debug::PrintTrait;


#[derive(Model, Copy, Drop, Serde)]
struct Game {
    #[key]
    game_id: u32,
    player1: ContractAddress,
    player2: ContractAddress,
    winner: ContractAddress,
}

#[derive(Model, Copy, Drop, Serde)]
struct Statement {
    #[key]
    game_id: u32,
    #[key]
    player_id: ContractAddress,
    commit_value: felt252,
    reveal_value: Choice,
    reveal_secret: felt252,
}


trait StatementTrait {
    fn reset(ref self: Statement, world: IWorldDispatcher);
}

impl StatementImpl of StatementTrait {
    fn reset(ref self: Statement, world: IWorldDispatcher) {
        let mut statement = get!(world, (self.game_id, self.player_id), (Statement));
        statement.commit_value = 0;
        statement.reveal_value = Choice::Idle;
        statement.reveal_secret = 0;
        set!(world, (statement));
    }
}


#[derive(Serde, Copy, Drop, PartialEq)]
enum Choice {
    Idle,
    Rock,
    Paper,
    Scissor
}

impl IntoFelt252Choice of Into<Choice, felt252> {
    fn into(self: Choice) -> felt252 {
        match self {
            Choice::Idle => 'idle',
            Choice::Rock => 'rock',
            Choice::Paper => 'paper',
            Choice::Scissor => 'scissor',
        }
    }
}

impl TryIntoChoiceFelt252 of TryInto<felt252, Choice> {
    fn try_into(self: felt252) -> Option<Choice> {
        if self == 'idle' {
            Option::Some(Choice::Idle)
        } else if self == 'rock' {
            Option::Some(Choice::Rock)
        } else if self == 'paper' {
            Option::Some(Choice::Paper)
        } else if self == 'scissor' {
            Option::Some(Choice::Scissor)
        } else {
            Option::None
        }
    }
}


impl ChoicePrint of PrintTrait<Choice> {
    fn print(self: Choice) {
        let felt: felt252 = self.into();
        felt.print();
    }
}


impl ChoiceSchemaIntrospectionImpl of SchemaIntrospection<Choice> {
    #[inline(always)]
    fn size() -> usize {
        1
    }

    #[inline(always)]
    fn layout(ref layout: Array<u8>) {
        layout.append(251);
    }

    #[inline(always)]
    fn ty() -> Ty {
        Ty::Enum(
            Enum {
                name: 'Choice',
                attrs: array![].span(),
                children: array![
                    ('Idle', serialize_member_type(@Ty::Tuple(array![].span()))),
                    ('Rock', serialize_member_type(@Ty::Tuple(array![].span()))),
                    ('Paper', serialize_member_type(@Ty::Tuple(array![].span()))),
                    ('Scissor', serialize_member_type(@Ty::Tuple(array![].span()))),
                ]
                    .span()
            }
        )
    }
}

