use starknet::ContractAddress;

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct Player {
    #[key]
    address: ContractAddress,
    // Total experienc points accumulated by the player so far.
    exp_points: u32,
}

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct Item {
    #[key]
    address: ContractAddress,
    // Experience point required to claim the token.
    exp_required: u32,
    // The amount of items minted so far.  
    minted: u32,
}
