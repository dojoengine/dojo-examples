use starknet::ContractAddress;

#[derive(Model, Copy, Drop, Serde)]
struct Player {
    #[key]
    address: ContractAddress,
    // Total experienc points accumulated by the player so far.
    exp_points: u32,
}

#[derive(Model, Copy, Drop, Serde)]
struct Item {
    #[key]
    id: u32,
    // Experience point required to claim the token.
    exp_required: u32,
    // The amount of items minted so far.  
    minted: u256
}
