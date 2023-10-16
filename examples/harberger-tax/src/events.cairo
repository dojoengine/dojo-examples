use starknet::ContractAddress;

#[derive(Drop, Clone, Serde, PartialEq, starknet::Event)]
struct TokenMinted {
    id: u128,
}

#[derive(Drop, Clone, Serde, PartialEq, starknet::Event)]
struct TokenOwnershipChanged {
    id: u128,
    from: ContractAddress,
    to: ContractAddress
}

#[derive(Drop, Clone, Serde, PartialEq, starknet::Event)]
struct TaxAdminChanged {
    from: ContractAddress,
    to: ContractAddress
}

#[derive(Drop, Clone, Serde, PartialEq, starknet::Event)]
struct TaxRecipientChanged {
    from: ContractAddress,
    to: ContractAddress
}

#[derive(Drop, Clone, Serde, PartialEq, starknet::Event)]
enum Event {
    TokenMinted: TokenMinted,
    TokenOwnershipChanged: TokenOwnershipChanged,
    TaxAdminChanged: TaxAdminChanged,
    TaxRecipientChanged: TaxRecipientChanged,
}