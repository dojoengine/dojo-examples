#[system]
mod view_price {
    use core::debug::PrintTrait;
    use array::ArrayTrait;
    use core::traits::{Into};
    use starknet::{ContractAddress, get_block_timestamp};

    use cubit::f128::types::fixed::{Fixed, FixedTrait};
    use dojo::world::Context;
    use dojo_defi::dutch_auction::vrgda::{LogisticVRGDA, LogisticVRGDATrait};

    use example_vrgda::components::{Auction, AuctionTrait, GoldBalance};

    fn execute(ctx: Context, game_id: u64, item_id: u128, amount: u128) -> Fixed {
        let mut auction = get!(ctx.world, (game_id, item_id), Auction);

        // convert auction to VRGDA
        let VRGDA = auction.to_LogisticVRGDA();

        // time since auction start
        let time_since_start: u128 = get_block_timestamp().into() - auction.start_time.into();

        // get current price
        VRGDA
            .get_vrgda_price(
                FixedTrait::new((time_since_start), false), // time since start
                FixedTrait::new(auction.sold, false) // amount sold
            )
    }
}

#[system]
mod buy {
    use core::debug::PrintTrait;
    use array::ArrayTrait;
    use core::traits::{Into};
    use starknet::{ContractAddress, get_block_timestamp};

    use cubit::f128::types::fixed::{Fixed, FixedTrait};
    use dojo::world::Context;
    use dojo_defi::dutch_auction::vrgda::{LogisticVRGDA, LogisticVRGDATrait};

    use example_vrgda::components::{Auction, AuctionTrait, GoldBalance};

    fn execute(ctx: Context, game_id: u64, item_id: u128, amount: u128) {
        let mut auction = get!(ctx.world, (game_id, item_id), Auction);
        let mut player_balance = get!(ctx.world, (game_id, ctx.origin), GoldBalance);

        // convert auction to VRGDA
        let VRGDA = auction.to_LogisticVRGDA();

        // time since auction start
        let time_since_start: u128 = get_block_timestamp().into() - auction.start_time.into();

        // get current price
        let price = VRGDA
            .get_vrgda_price(
                FixedTrait::new((time_since_start), false), // time since start
                FixedTrait::new(auction.sold, false) // amount sold
            );

        // add to amount sold
        auction.sold += amount;

        set!(ctx.world, (auction, player_balance));
    }
}

#[system]
mod start_auction {
    use array::ArrayTrait;
    use core::traits::{Into, TryInto};
    use option::OptionTrait;
    use starknet::{ContractAddress, get_block_timestamp};

    use example_vrgda::components::{Auction, GoldBalance};

    use cubit::f128::types::fixed::{Fixed, FixedTrait};
    use dojo::world::Context;
    use dojo_defi::dutch_auction::vrgda::{LogisticVRGDA};

    const target_price: u128 = 1000;
    const _0_31: u128 = 5718490662849961000; // 0.31
    const MAX_SELLABLE: u128 = 9000;
    const _0_0023: u128 = 42427511369531970; // 0.0023

    fn execute(ctx: Context, game_id: u64, item_id: u128) {
        // todo: check if auction already exists
        // todo: check game exists

        // we create a dojo component to store the Auction using a compound key
        // (game_id, item_id) - this way we can have multiple auctions running
        let auction = Auction {
            game_id,
            item_id,
            target_price: FixedTrait::new_unscaled(target_price, false).into(),
            decay_constant: FixedTrait::new(_0_31, false),
            max_sellable: FixedTrait::new_unscaled(MAX_SELLABLE, false),
            time_scale: FixedTrait::new(_0_0023, false),
            start_time: get_block_timestamp(), //update to timestamp
            sold: 0,
        };

        set!(ctx.world, (auction));
    }
}
