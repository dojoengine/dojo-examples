use starknet::ContractAddress;

const TAX_META_ID: u128 = 0;

#[derive(Model, Copy, Drop, Serde)]
struct TaxMeta {
    #[key]
    id: u128,
    admin: ContractAddress,
    recipient: ContractAddress,
    numerator: u32,
    denominator: u32,
    payment_token_address: ContractAddress
}


#[derive(Model, Copy, Drop, Serde)]
struct Token {
    #[key]
    id: u128,
    owner: ContractAddress,
    price: u128,
    minted: bool
}


#[derive(Model, Copy, Drop, Serde)]
struct Account {
    #[key]
    address: ContractAddress,
    balance: u128,
    sum_of_prices: u128,
    paid_thru: u128
}

#[generate_trait]
impl AccountImpl of AccountTrait {
    fn can_be_foreclosed(self: Account) -> bool {
        (self.balance == 0
            && self.paid_thru < starknet::get_block_timestamp().into()
            && self.sum_of_prices > 0)
    }
}
