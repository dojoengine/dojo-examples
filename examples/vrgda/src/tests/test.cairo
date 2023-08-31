#[cfg(test)]
mod test {
    use core::traits::Into;
    use array::ArrayTrait;
    use debug::PrintTrait;

    // dojo core imports
    use dojo::world::{IWorldDispatcherTrait, IWorldDispatcher};
    use dojo::test_utils::spawn_test_world;

    // project imports
    use example_vrgda::components::{
        gold_balance, GoldBalance, ItemBalance, item_balance, Auction, auction
    };
    use example_vrgda::systems::{buy, start_auction};

    fn setup() -> IWorldDispatcher {
        // components
        let mut components = array![
            gold_balance::TEST_CLASS_HASH, item_balance::TEST_CLASS_HASH, auction::TEST_CLASS_HASH
        ];

        // // systems
        let mut systems = array![buy::TEST_CLASS_HASH, start_auction::TEST_CLASS_HASH];

        // deploy executor, world and register components/systems
        spawn_test_world(components, systems)
    }

    #[test]
    #[available_gas(600000000)]
    fn test_start() {
        let mut world = setup();

        let game_id = 1;
        let item_id = 1;
        let amount = 1;

        world.execute('start_auction', array![game_id, item_id]);

        let auctions = get!(world, (game_id, item_id), (Auction));

        auctions.sold.print();

        world.execute('buy', array![game_id, item_id, amount]);
    }
}

