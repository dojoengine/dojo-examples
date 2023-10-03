use starknet::ContractAddress;

#[derive(Model, Copy, Drop, Serde)]
struct Ship {
    #[key]
    player: ContractAddress,
    id: u8,
    x: u32,
    y: u32
}

#[derive(Model, Copy, Drop, Serde)]
struct Fleet {
    #[key]
    player: ContractAddress,
    units: u8,
}

