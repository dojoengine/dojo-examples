use harberger::models::TaxMeta;
use dojo::world::IWorldDispatcher;
use starknet::ContractAddress;

trait IHarbergerTaxSystems<TContractState> {
    /// Initializes the contract with a new tax metadata.
    ///
    /// It may only be called once and should be called immediately 
    /// after contract deployment
    ///
    /// # Arguments
    ///
    /// * `world`: The `IWorldDispatcher` for interacting with the dojo world.
    /// * `new_tax_meta`: The new `TaxMeta` to be set for the contract.
    /// * `token_ids`: The array of token ids to be minted.
    ///
    /// # Panics
    ///
    /// Panics if the contract is already initialized or if any of the validation checks fail.
    fn initialize(
        self: @TContractState,
        world: IWorldDispatcher,
        new_tax_meta: TaxMeta,
        token_ids: Array<u128>
    );


    /// Mint tokens so that they may be used, bought and sold in the contract.
    ///
    /// # Arguments
    ///
    /// * `world`: The `IWorldDispatcher` for interacting with the dojo world.
    /// * `token_ids`: The array of token ids to be minted.
    ///
    /// # Panics
    ///
    /// Panics if the called by an account other than owner account.
    fn mint(self: @TContractState, world: IWorldDispatcher, token_ids: Array<u128>);


    /// Changes the tax recipient address.
    ///
    /// # Arguments
    ///
    /// * `world`: The `IWorldDispatcher` for interacting with the dojo world.
    /// * `new_recipient`: The new tax recipient address.
    ///
    /// # Panics
    ///
    /// Panics if the caller does not have permission to change the recipient.
    fn change_tax_recipient(
        self: @TContractState, world: IWorldDispatcher, new_recipient: ContractAddress
    );

    /// Changes the tax admin address.
    ///
    /// # Arguments
    ///
    /// * `world`: The `IWorldDispatcher` for interacting with the dojo world.
    /// * `new_admin`: The new tax admin address.
    ///
    /// # Panics
    ///
    /// Panics if the caller does not have permission to change the admin.
    fn change_tax_admin(self: @TContractState, world: IWorldDispatcher, new_admin: ContractAddress);

    /// Deposits funds into the caller's account within the contract.
    ///
    /// # Arguments
    ///
    /// * `world`: The `IWorldDispatcher` for interacting with the dojo world.
    /// * `amount`: The amount of funds to deposit.
    ///
    /// # Panics
    ///
    /// Panics if the fund transfer fails or if any of the validation checks fail.
    fn deposit(self: @TContractState, world: IWorldDispatcher, amount: u128);


    /// Withdraws funds from the caller's account within the contract.
    ///
    /// # Arguments
    ///
    /// * `world`: The `IWorldDispatcher` for interacting with the dojo world.
    /// * `amount`: The amount of funds to withdraw.
    ///
    /// # Panics
    ///
    /// Panics if the withdrawal amount is greater than the account balance or if the fund transfer fails.
    fn withdraw(self: @TContractState, world: IWorldDispatcher, amount: u128);

    /// Calculates and returns the taxes due for a specific address.
    ///
    /// # Arguments
    ///
    /// * `world`: The `IWorldDispatcher` for interacting with the dojo world.
    /// * `address`: The address for which taxes are to be calculated.
    ///
    /// # Returns
    ///
    /// The calculated taxes due for the specified address.
    fn get_taxes_due(
        self: @TContractState, world: IWorldDispatcher, address: ContractAddress
    ) -> u128;

    /// Collects taxes owed by a specified address and updates account balances.
    ///
    /// # Arguments
    ///
    /// * `world`: The `IWorldDispatcher` for interacting with the dojo world.
    /// * `address`: The address for which taxes are to be collected.
    ///
    /// # Returns
    ///
    /// `true` if the payer has sufficient funds to pay the taxes; `false` otherwise.
    fn collect_taxes(
        self: @TContractState, world: IWorldDispatcher, address: ContractAddress
    ) -> bool;


    /// Forecloses a token, transferring ownership and resetting its price.
    ///
    /// # Arguments
    ///
    /// * `world`: The `IWorldDispatcher` for interacting with the dojo world.
    /// * `token_id`: The ID of the token to foreclose.
    ///
    /// # Panics
    ///
    /// Panics if the token cannot be foreclosed or if any validation checks fail.
    fn foreclose(self: @TContractState, world: IWorldDispatcher, token_id: u128);


    /// Buys a token from its current owner, updating account balances and token ownership.
    ///
    /// This function can also be used to update the price of a token. The same address
    /// just needs to be specified as seller and buyer
    ///
    /// # Arguments
    ///
    /// * `world`: The `IWorldDispatcher` for interacting with the dojo world.
    /// * `token_id`: The ID of the token to be bought.
    /// * `max_price`: The maximum price the buyer is willing to pay.
    /// * `price`: The price at which the token is bought.
    ///
    /// # Panics
    ///
    /// Panics if the maximum price is too low, the buyer has insufficient funds, or other conditions are not met.
    fn buy(
        self: @TContractState, world: IWorldDispatcher, token_id: u128, max_price: u128, price: u128
    );
}
