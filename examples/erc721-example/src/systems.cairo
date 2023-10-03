#[system]
mod ItemActions {
    use starknet::{ContractAddress, get_caller_address};

    use dojo_erc::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};

    use erc721_example::models::{Player, Item};

    fn claim(
        world: IWorldDispatcher, 
        erc721_address: ContractAddress, 
        item_id: u32
    ) {

        let claimant = get!(world, get_caller_address(), Player);
        let mut item = get!(world, item_id, Item);

        // confirm that claimant has enough exp
        assert(claimant.exp_points >= item.exp_required, 'Not enough exp');

        // transfer nft to claimant

        // we assume that the world initially owns all items and 
        // this contract is approved to spend them
        let token = IERC721Dispatcher{contract_address: erc721_address};
        token.transfer_from(world.contract_address, claimant.address, item.minted);

        item.minted += 1;
        set!(world, (item));
    }
}
