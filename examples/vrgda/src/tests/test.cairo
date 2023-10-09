#[cfg(test)]
mod test {
    // dojo core imports
    use dojo::world::{IWorldDispatcherTrait, IWorldDispatcher};
    use dojo::test_utils::spawn_test_world;

    // starknet imports
    use starknet::syscalls::deploy_syscall;

    // project imports
    use example_vrgda::models::{
        gold_balance, GoldBalance, item_balance, ItemBalance, auction, Auction
    };

    use example_vrgda::systems::aution_systems;
    use example_vrgda::systems::{IAuctionSystemsDispatcher, IAuctionSystemsDispatcherTrait};

    use core::traits::TryInto;
    use core::option::OptionTrait;

    fn setup() -> (IWorldDispatcher, IAuctionSystemsDispatcher) {
        // deploy executor, and get world
        let world: IWorldDispatcher = spawn_test_world(
            array![
                gold_balance::TEST_CLASS_HASH,
                item_balance::TEST_CLASS_HASH,
                auction::TEST_CLASS_HASH
            ]
        );

        // deploy the auction_systems contract and get
        // the contract address
        let (auction_systems_contract_address, _) = deploy_syscall(
            aution_systems::TEST_CLASS_HASH.try_into().unwrap(), 0, array![].span(), false
        )
            .unwrap();

        // connect the contract address to its dispatcher so that
        // we can use it to call contract methods/functions
        let auction_systems_contract = IAuctionSystemsDispatcher {
            contract_address: auction_systems_contract_address
        };

        (world, auction_systems_contract)
    }

    #[test]
    #[available_gas(600000000)]
    fn test_start_and_buy() {
        let (world, auction_systems_contract) = setup();

        let game_id = 1;
        let item_id = 1;
        let amount = 1;

        // change block timestamp to 1 because the initial 
        // value is 0. This will then be checked to ensure
        // that the auction was started
        starknet::testing::set_block_timestamp(1);

        // start auction
        auction_systems_contract.start(world, game_id, item_id);

        // confirm that auction was started 
        let auction = get!(world, (game_id, item_id), (Auction));
        assert(auction.start_time == 1, 'should be 1');

        // buy from auction
        auction_systems_contract.buy(world, game_id, item_id, amount);

        // confirm that sale was successful 
        let auction = get!(world, (game_id, item_id), (Auction));
        assert(auction.sold == 1, 'should be 1');
    }
}

