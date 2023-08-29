#[system]
mod buy {
    use array::ArrayTrait;
    use core::traits::Into;
    use starknet::ContractAddress;

    use cubit::f128::types::fixed::{Fixed, FixedTrait};
    use dojo::world::Context;
    use dojo_defi::dutch_auction::vrgda::{LogisticVRGDA};

    use example_vrgda::components::{Auction, GoldBalance};

    fn execute(ctx: Context, game_id: u64, item_id: u128, amount: u128) {
        let auction = get!(ctx.world, (game_id, item_id), Auction);
        let player_balance = get!(ctx.world, (game_id, ctx.origin), GoldBalance);
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

    const _69_42: u128 = 1280572973596917000000;
    const _0_31: u128 = 5718490662849961000;
    const MAX_SELLABLE: u128 = 9000;
    const _0_0023: u128 = 42427511369531970;

    fn execute(ctx: Context, game_id: u64, item_id: u128) {
        // create fixed point numbers
        let target_price: felt252 = FixedTrait::new(_69_42, false).into();
        let decay_constant: felt252 = FixedTrait::new(_0_31, false).into();
        let max_sellable: felt252 = FixedTrait::new_unscaled(MAX_SELLABLE, false).into();
        let time_scale: felt252 = FixedTrait::new(_0_0023, false).into();

        // we create a dojo component to store the Auction using a compound key
        // (game_id, item_id) - this way we can have multiple auctions running
        let auction = Auction {
            game_id,
            item_id,
            target_price: target_price.try_into().unwrap(),
            decay_constant: decay_constant.try_into().unwrap(),
            max_sellable: max_sellable.try_into().unwrap(),
            time_scale: time_scale.try_into().unwrap(),
            start_time: get_block_timestamp(), //update to timestamp
            sold: 0,
        };

        set!(ctx.world, (auction));
    }
}
