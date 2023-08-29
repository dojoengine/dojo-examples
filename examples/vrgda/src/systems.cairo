#[system]
mod buy {
    use core::debug::PrintTrait;
    use array::ArrayTrait;
    use core::traits::Into;
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

        // convert time to fixed point number
        let current_time: u128 = get_block_timestamp().into();
        let start_time: u128 = auction.start_time.into();
        let time_since_start = FixedTrait::new((current_time - start_time), false);

        // convert amount to fixed point number sold
        let number_sold = FixedTrait::new(auction.sold, false);

        let price = VRGDA.get_vrgda_price(time_since_start, number_sold);

        price.print();

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
    const _0_31: u128 = 5718490662849961000;
    const MAX_SELLABLE: u128 = 9000;
    const _0_0023: u128 = 42427511369531970;

    fn execute(ctx: Context, game_id: u64, item_id: u128) {
        // todo: check if auction already exists
        // todo: check game exists
        // create fixed point numbers
        let target_price: felt252 = FixedTrait::new_unscaled(target_price, false).into();
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
