#[cfg(test)]
mod test {
    use core::traits::Into;
    use array::ArrayTrait;

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

        world.execute('start_auction', array![1, 1]);

        let call_data = array![1, 2].span();

        let auctions = world.entity('Auction', call_data, 0, dojo::SerdeLen::<Auction>::len());

        assert(*auctions[5] == 0, 'not 0');
    }
}

