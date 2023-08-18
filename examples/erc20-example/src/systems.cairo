#[system]
mod attack {
    use array::ArrayTrait;
    use core::traits::Into;
    use starknet::ContractAddress;
    use zeroable::Zeroable;

    use dojo::world::Context;
    use dojo_erc::erc20::systems::erc20_transfer_from;

    use erc20_example::components::{Fleet, Ship};

    const ONE_TOKEN: felt252 = 1000000000000000000;

    fn execute(ctx: Context, attacker: ContractAddress, defender: ContractAddress, x: u32, y: u32) {
        assert(!x.is_zero() || !y.is_zero(), 'Coordinates must be > 0');
        let mut attacked_ship: Ship = get!(ctx.world, defender, Ship);

        // If the attacker hit one of the defender ships we transfer one erc20 token.
        if attacked_ship.x == x && attacked_ship.y == y {
            let calldata: Array<felt252> = array![defender.into(), attacker.into(), ONE_TOKEN];
            // The ERC20 system is invoked here. 
            ctx.world.execute('erc20_transfer_from', calldata);
            // Change the ship coordinates to 0;
            attacked_ship.x = 0;
            attacked_ship.x = 0;
            set!(ctx.world, (attacked_ship));

            let mut defender_fleet = get!(ctx.world, defender, Fleet);
            // Reduce the defender fleet's units. 
            defender_fleet.units -= 1;
            set!(ctx.world, (defender_fleet));
        }
    }
}
