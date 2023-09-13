use starknet::ContractAddress;
use dojo::world::{Context, IWorldDispatcher, IWorldDispatcherTrait};


#[derive(Component, Copy, Drop, Serde)]
struct Game {
    #[key]
    game_id: u32,
    player1: ContractAddress,
    player2: ContractAddress,
    winner: ContractAddress,
}

#[derive(Component, Copy, Drop, Serde)]
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
    fn reset(ref self: Statement, ctx: Context);
}

impl StatementImpl of StatementTrait {
    fn reset(ref self: Statement, ctx: Context) {
        let mut statement = get!(ctx.world, (self.game_id, self.player_id), (Statement));
        statement.commit_value = 0;
        statement.reveal_value = Choice::Idle;
        statement.reveal_secret = 0;
        set!(ctx.world, (statement));
    }
}


#[derive(Copy, Drop, Serde, PartialEq)]
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


impl ChoiceStorageSize of dojo::StorageSize<Choice> {
    #[inline(always)]
    fn unpacked_size() -> usize {
        1
    }

    #[inline(always)]
    fn packed_size() -> usize {
        252
    }
}


use debug::PrintTrait;

impl ChoicePrint of PrintTrait<Choice> {
    fn print(self: Choice) {
        let felt: felt252 = self.into();
        felt.print();
    }
}
