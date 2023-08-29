use starknet::ContractAddress;

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct GoldBalance {
    #[key]
    game_id: u64,
    #[key]
    player_id: ContractAddress,
    balance: u32,
}

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct ItemBalance {
    #[key]
    game_id: u64,
    #[key]
    player_id: ContractAddress,
    #[key]
    item_id: ContractAddress,
    balance: u32,
}

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct Auction {
    #[key]
    game_id: u64,
    #[key]
    item_id: u128,
    target_price: u128,
    decay_constant: u128,
    max_sellable: u128,
    time_scale: u128,
    start_time: u64,
    sold: u128,
}
