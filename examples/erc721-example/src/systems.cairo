#[system]
mod claim_item {
    use array::ArrayTrait;
    use core::traits::Into;
    use starknet::ContractAddress;

    use dojo::world::Context;
    use dojo_erc::erc721::systems::erc721_mint;

    use erc721_example::components::{Player, Item};

    fn execute(ctx: Context, claimant: Player, mut item: Item) {
        // If the claiming player has enough exp the item's token can be minted.
        assert(claimant.exp_points >= item.exp_required, 'Not enough exp');

        let calldata: Array<felt252> = array![
            item.address.into(), (item.minted + 1).into(), claimant.address.into()
        ];
        // The ERC721 system is invoked here.
        ctx.world.execute('erc721_mint', calldata);
        // Update the item component.
        item.minted += 1;
        set!(ctx.world, (item));
    }
}
