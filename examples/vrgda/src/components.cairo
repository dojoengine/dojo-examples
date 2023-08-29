use starknet::ContractAddress;
use dojo_defi::dutch_auction::vrgda::{LogisticVRGDA};
use cubit::f128::types::fixed::{Fixed, FixedTrait};

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct Game {
    #[key]
    game_id: u64,
    start_time: u64,
    status: bool,
}


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
    item_id: u128,
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

#[generate_trait]
impl ImplAuction of AuctionTrait {
    fn to_LogisticVRGDA(self: Auction) -> LogisticVRGDA {
        let target_price = FixedTrait::new(self.target_price, false);
        let decay_constant = FixedTrait::new(self.decay_constant, false);
        let max_sellable = FixedTrait::new(self.max_sellable, false);
        let time_scale = FixedTrait::new(self.time_scale, false);

        LogisticVRGDA { target_price, decay_constant, max_sellable, time_scale }
    }
}

