#[starknet::contract]
mod harberger_tax_systems {
    #[event]
    use harberger::events::{
        Event, TokenMinted, TaxAdminChanged,
        TaxRecipientChanged, TokenOwnershipChanged
    };
    use harberger::models::{Account, AccountTrait, Token, TaxMeta, TAX_META_ID}; 
    use harberger::interfaces::IHarbergerTaxSystems;

    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use starknet::ContractAddress;
    use core::zeroable::Zeroable;

    #[storage]
    struct Storage {}

    #[external(v0)]
    impl HarbergerTaxSystemsImpl of IHarbergerTaxSystems<ContractState> {
        //////////////////////////////////////////
        /// see `IHarbergerTaxSystems` interface 
        /// for function documentation
        /////////////////////////////////////////

        fn initialize(
            self: @ContractState, 
            world: IWorldDispatcher, 
            new_tax_meta: TaxMeta, 
            token_ids: Array<u128>
        ) {
            let current_tax_meta: TaxMeta = get!(world, TAX_META_ID, TaxMeta);
            assert(current_tax_meta.admin == Zeroable::zero(), 'already initialized');

            assert(new_tax_meta.id == TAX_META_ID, 'wrong meta id');
            assert(new_tax_meta.admin != Zeroable::zero(), 'admin is 0');
            assert(new_tax_meta.recipient != Zeroable::zero(), 'recepient is 0');
            assert(new_tax_meta.numerator != 0, 'numerator is 0');
            assert(new_tax_meta.denominator != 0, 'denominator is 0');
            assert(new_tax_meta.numerator <= new_tax_meta.denominator, 'incorrect fraction');
            assert(new_tax_meta.payment_token_address != Zeroable::zero(), 'zero contract address');


            set!(world, (new_tax_meta));

            self.mint(world, token_ids);
        }


        fn mint(self: @ContractState, world: IWorldDispatcher, token_ids: Array<u128>) {
            let tax_meta: TaxMeta = get!(world, TAX_META_ID, TaxMeta);

            assert(tax_meta.admin == starknet::get_caller_address(), 'permission denied');

            let mut token_ids = token_ids;
            loop {
                match token_ids.pop_front() {
                    Option::Some(token_id) => {
                        let mut token: Token = get!(world, token_id, Token);
                        assert(token.minted == false, 'already minted');
                        token.minted = true;
                        set!(world, (token));
                        emit!(world, TokenMinted{id: token_id});

                    },
                    Option::None => {break;}
                };
            };
        }

        

        fn change_tax_admin(self: @ContractState, world: IWorldDispatcher, new_admin: ContractAddress) {
            let mut tax_meta: TaxMeta = get!(world, TAX_META_ID, TaxMeta);
            let caller = starknet::get_caller_address();
            assert(
                    tax_meta.admin == caller, 
                        'permission denied'
            );

            tax_meta.admin = new_admin;
            set!(world, (tax_meta));

            emit!(world, TaxAdminChanged{from : caller, to: new_admin});


        }




        fn change_tax_recepient(self: @ContractState, world: IWorldDispatcher, new_recepient: ContractAddress) {
            let mut tax_meta: TaxMeta = get!(world, TAX_META_ID, TaxMeta);
            let caller = starknet::get_caller_address();

            assert(
                    tax_meta.admin == caller, 
                        'permission denied'
            );

            tax_meta.recipient = new_recepient;
            set!(world, (tax_meta));

            emit!(world, TaxRecipientChanged{from : caller, to: new_recepient});


        }




        fn deposit(self: @ContractState, world: IWorldDispatcher, amount: u128) {
            let tax_meta: TaxMeta = get!(world, TAX_META_ID, TaxMeta);
            let caller = starknet::get_caller_address();

            let payment_token = IERC20Dispatcher{
                contract_address: tax_meta.payment_token_address
            };

            assert(
                payment_token.transfer_from(
                    caller, 
                    starknet::get_contract_address(), 
                    amount.into()
                ), 
                'transfer failed'
            );
            let mut caller_account: Account = get!(world, caller, Account);
            caller_account.balance += amount;
            set!(world, (caller_account));
        }




        fn withdraw(self: @ContractState, world: IWorldDispatcher, amount: u128) {
            let caller: ContractAddress = starknet::get_caller_address();

            // collect any taxes owed by caller 
            self.collect_taxes(world, caller);

            let mut caller_account: Account = get!(world, caller, Account);

            assert(caller_account.balance >= amount, 'insufficient funds');
            caller_account.balance -= amount;

            let tax_meta: TaxMeta = get!(world, TAX_META_ID, TaxMeta);
            let payment_token = IERC20Dispatcher{
                contract_address: tax_meta.payment_token_address
            };

            assert(payment_token.transfer(caller, amount.into()), 'transfer failed');

            set!(world, (caller_account));
        }





        fn get_taxes_due(self: @ContractState, world: IWorldDispatcher, address: ContractAddress ) -> u128 {
            let account: Account = get!(world, address, Account);
            let tax_meta: TaxMeta = get!(world, TAX_META_ID, TaxMeta);
            let one_day = 86400;
            let taxes = ( account.sum_of_prices * (starknet::get_block_timestamp().into() - account.paid_thru) * tax_meta.numerator.into() )
                        / tax_meta.denominator.into() / one_day;
            return taxes;
        }



        fn foreclose(self: @ContractState, world: IWorldDispatcher, token_id: u128) {
            let mut token: Token = get!(world, token_id, Token);
            assert(token.owner != Zeroable::zero(), 'token not owned');

            let mut token_owner_account: Account = get!(world, token.owner, Account);
            assert(token_owner_account.can_be_foreclosed(), 'account cant be foreclosed');
        
            token_owner_account.sum_of_prices -= token.price;

            // reset token
            token.owner = Zeroable::zero();
            token.price = Zeroable::zero();

            set!(world, (token, token_owner_account));
        }


        fn collect_taxes(self: @ContractState, world: IWorldDispatcher, address: ContractAddress) -> bool {
            let tax_meta: TaxMeta = get!(world, TAX_META_ID, TaxMeta);
            let mut tax_recipient_account: Account = get!(world, tax_meta.recipient, Account);
            let mut tax_payer_account: Account = get!(world, address, Account);

            let taxes = self.get_taxes_due(world, address);

            let payer_has_sufficient_funds: bool = taxes <= tax_payer_account.balance;
            
            if payer_has_sufficient_funds {
                tax_payer_account.paid_thru = starknet::get_block_timestamp().into();
                tax_recipient_account.balance += taxes;
                tax_payer_account.balance -= taxes;
            } else {
                tax_payer_account.paid_thru += (starknet::get_block_timestamp().into() - tax_payer_account.paid_thru) * tax_payer_account.balance / taxes;
                tax_recipient_account.balance += tax_payer_account.balance;
                tax_payer_account.balance = Zeroable::zero();
            }
                
            set!(world, (tax_payer_account, tax_recipient_account));

            payer_has_sufficient_funds

        }


        fn buy(self: @ContractState, world: IWorldDispatcher, token_id: u128, max_price: u128, price: u128) {

            let mut token: Token = get!(world, token_id, Token);
            assert(token.minted == true, 'token not minted');

            let seller: ContractAddress = token.owner;
            let buyer: ContractAddress = starknet::get_caller_address();

            // collect all taxes that buyer and seller owe
            // before retrieving their account information
            // to retrieve accurate balances
            self.collect_taxes(world, seller);
            if seller != buyer {self.collect_taxes(world, buyer);}

            let mut buyer_account: Account = get!(world, buyer, Account);
            let mut seller_account: Account = get!(world, seller, Account);


            // forclose seller account if possible. 
            if seller_account.can_be_foreclosed(){
                self.foreclose(world, token.id);

                // foreclosure changes the token owner
                // and price so we update it here
                token = get!(world, token.id, Token);
            }

            if (seller != buyer) {
                assert(max_price >= token.price, 'max_price too low');
                assert(buyer_account.balance >= token.price, 'insufficient fund');

                seller_account.balance += token.price;
                buyer_account.balance -= token.price;
                token.owner = buyer;
            }
            

            seller_account.sum_of_prices -= token.price;
            buyer_account.sum_of_prices += price;
            token.price = price;

            set!(world, (seller_account, buyer_account, token));

            emit!(world, TokenOwnershipChanged{ id: token_id, from : seller, to: buyer});

        }
    }

}