#[system]
mod ShipActions {
    use starknet::ContractAddress;
    use zeroable::Zeroable;

    use dojo_erc::token::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};

    use erc20_example::models::{Fleet, Ship};

    const ONE_TOKEN: u256 = 1_000_000_000_000_000_000; // 1 * 10^18

    #[external(v0)]
    fn attack(
        self: @ContractState,
        world: IWorldDispatcher,
        erc20_address: ContractAddress,
        attacker: ContractAddress,
        defender: ContractAddress,
        x: u32,
        y: u32
    ) {
        assert(!x.is_zero() || !y.is_zero(), 'Coordinates must be > 0');

        let mut defender_ship: Ship = get!(world, defender, Ship);

        // If the attacker hit one of the defender ships we transfer one erc20 token.
        if defender_ship.x == x && defender_ship.y == y {

            // The ERC20 system is invoked here.
            let token = IERC20Dispatcher { contract_address: erc20_address };
            assert(token.transfer_from(defender, attacker, ONE_TOKEN), 'transfer failed');

            // Change the ship coordinates to 0;
            defender_ship.x = 0;
            defender_ship.x = 0;
            set!(world, (defender_ship));

            // Reduce the defender fleet's units. 
            let mut defender_fleet = get!(world, defender, Fleet);
            defender_fleet.units -= 1;
            set!(world, (defender_fleet));
        }
    }
}
