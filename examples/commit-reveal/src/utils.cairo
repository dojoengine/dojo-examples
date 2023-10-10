use starknet::ContractAddress;
use commit_reveal::models::Choice;

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
