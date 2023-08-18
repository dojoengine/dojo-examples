use starknet::ContractAddress;

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct Ship {
    #[key]
    player: ContractAddress,
    id: u8,
    x: u32,
    y: u32
}

#[derive(Component, Copy, Drop, Serde, SerdeLen)]
struct Fleet {
    #[key]
    player: ContractAddress,
    units: u8,
}

