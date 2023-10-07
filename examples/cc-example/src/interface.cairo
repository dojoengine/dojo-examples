use starknet::ContractAddress;

#[starknet::interface]
trait ICryptsAndCaverns<TState> {
    #[derive(Copy, Drop, Serde)]
    struct DungeonSerde {
        size: u8,
        environment: u8,
        structure: u8,
        legendary: u8,
        layout: Pack,
        entities: EntityData,
        affinity: felt252,
        dungeon_name: Span<felt252>
    }

    fn owner_of(self: @TState, token_id: u256) -> ContractAddress;
    fn get_svg(self: @ContractState, token_id: u128) -> Array<felt252>;

}