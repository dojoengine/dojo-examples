use core::pedersen::pedersen;
use starknet::ContractAddress;
use starknet::testing::{set_contract_address, set_account_contract_address};

// dojo core imports
use dojo::world::{IWorldDispatcherTrait, IWorldDispatcher};
use dojo::test_utils::spawn_test_world;

// project imports
use commit_reveal::components::{game, Game};
use commit_reveal::components::{statement, Statement};
use commit_reveal::components::{Choice};

use commit_reveal::systems::{create_game, commit_value, reveal_value};

use debug::PrintTrait;
//

fn ZERO() -> ContractAddress {
    starknet::contract_address_const::<0x0>()
}

fn PLAYER1() -> ContractAddress {
    starknet::contract_address_const::<0x111>()
}

fn PLAYER2() -> ContractAddress {
    starknet::contract_address_const::<0x222>()
}

fn impersonate(address: ContractAddress) {
    set_contract_address(address);
    set_account_contract_address(address);
}

//

fn setup() -> IWorldDispatcher {
    // components
    let mut components = array![game::TEST_CLASS_HASH, statement::TEST_CLASS_HASH,];

    // // systems
    let mut systems = array![
        create_game::TEST_CLASS_HASH, commit_value::TEST_CLASS_HASH, reveal_value::TEST_CLASS_HASH
    ];

    // deploy executor, world and register components/systems
    let world = spawn_test_world(components, systems);

    world.grant_writer('Game', 'create_game');
    world.grant_writer('Game', 'reveal_value');

    world.grant_writer('Statement', 'commit_value');
    world.grant_writer('Statement', 'reveal_value');

    let uuid = world.uuid(); // consume uuid 0

    world
}

#[test]
#[available_gas(600000000)]
fn test_setup() {
    let mut world = setup();
}

#[test]
#[available_gas(600000000)]
fn test_create_game() {
    let mut world = setup();

    impersonate(PLAYER1());

    let create_game_result = world
        .execute('create_game', array![PLAYER1().into(), PLAYER2().into()]);
    let game_id = *create_game_result.at(0);
    assert(game_id == 1, 'should be 1');

    let create_game_result = world
        .execute('create_game', array![PLAYER1().into(), PLAYER2().into()]);
    let game_id = *create_game_result.at(0);
    assert(game_id == 2, 'should be 2');
}


#[test]
#[available_gas(600000000)]
fn test_game_with_winner() {
    let mut world = setup();

    // admin create game
    let create_game_result = world
        .execute('create_game', array![PLAYER1().into(), PLAYER2().into()]);
    let game_id = *create_game_result.at(0);

    simulate_game(
        world,
        game_id,
        player1: PLAYER1(),
        player1_secret: 'p1_secret',
        player1_choice: Choice::Rock,
        player2: PLAYER2(),
        player2_secret: 'p2_secret',
        player2_choice: Choice::Scissor
    );

    // retrieve game
    let game = get!(world, (game_id), (Game));
    assert(game.winner != ZERO(), 'it should have a winner');
    assert(game.winner == PLAYER1(), 'player 1 should win');
}


#[test]
#[available_gas(600000000)]
fn test_game_with_even_result() {
    let mut world = setup();

    // admin create game
    let create_game_result = world
        .execute('create_game', array![PLAYER1().into(), PLAYER2().into()]);
    let game_id = *create_game_result.at(0);

    simulate_game(
        world,
        game_id,
        player1: PLAYER1(),
        player1_secret: 'p1_secret',
        player1_choice: Choice::Paper,
        player2: PLAYER2(),
        player2_secret: 'p2_secret',
        player2_choice: Choice::Paper
    );

    // retrieve game
    let game = get!(world, (game_id), (Game));
    assert(game.winner == ZERO(), 'it should not have a winner');

    // check commit has been reseted
    let statement_p1 = get!(world, (game_id, PLAYER1()), (Statement));
    let statement_p2 = get!(world, (game_id, PLAYER2()), (Statement));

    assert(statement_p1.commit_value == 0, 'commit_value1 should reset');
    assert(statement_p1.reveal_value == Choice::Idle, 'reveal_value1 should reset');
    assert(statement_p1.reveal_secret == 0, 'reveal_secret1 should reset');

    assert(statement_p2.commit_value == 0, 'commit_value2 should reset');
    assert(statement_p2.reveal_value == Choice::Idle, 'reveal_value2 should reset');
    assert(statement_p2.reveal_secret == 0, 'reveal_secret2 should reset');
}


#[test]
#[available_gas(600000000)]
fn test_game_with_even_result_then_replay() {
    let mut world = setup();

    // admin create game
    let create_game_result = world
        .execute('create_game', array![PLAYER1().into(), PLAYER2().into()]);
    let game_id = *create_game_result.at(0);

    // round 1 is even
    simulate_game(
        world,
        game_id,
        player1: PLAYER1(),
        player1_secret: 'p1_secret',
        player1_choice: Choice::Paper,
        player2: PLAYER2(),
        player2_secret: 'p2_secret',
        player2_choice: Choice::Paper
    );

    // retrieve game
    let game = get!(world, (game_id), (Game));
    assert(game.winner == ZERO(), 'it should not have a winner');

    // round 2 
    simulate_game(
        world,
        game_id,
        player1: PLAYER1(),
        player1_secret: 'p1_secret_should_change',
        player1_choice: Choice::Rock,
        player2: PLAYER2(),
        player2_secret: 'p2_secret_should_change',
        player2_choice: Choice::Paper
    );

    // retrieve game
    let game = get!(world, (game_id), (Game));
    assert(game.winner != ZERO(), 'it should have a winner');
    assert(game.winner == PLAYER2(), 'player 2 should win');
}


#[test]
#[available_gas(600000000)]
fn test_game_with_cheater_bad_commit() {
    let mut world = setup();

    // admin create game
    let create_game_result = world
        .execute('create_game', array![PLAYER1().into(), PLAYER2().into()]);
    let game_id = *create_game_result.at(0);

    // player1 commit
    impersonate(PLAYER1());

    let player1_secret = 'player1_secret';
    let player1_choice = Choice::Rock;
    let mut player1_commit_value = pedersen(player1_choice.into(), player1_secret);
    // modifiy commit_value
    player1_commit_value += 1;

    world.execute('commit_value', array![game_id.into(), player1_commit_value]);

    // player2 commit
    impersonate(PLAYER2());

    let player2_secret = 'player2_secret';
    let player2_choice = Choice::Scissor;
    let player2_commit_value = pedersen(player2_choice.into(), player2_secret);

    world.execute('commit_value', array![game_id.into(), player2_commit_value]);

    // // player1 reveal 
    impersonate(PLAYER1());
    world.execute('reveal_value', array![game_id.into(), Choice::Rock.into(), player1_secret]);

    // retrieve game
    let game = get!(world, (game_id), (Game));
    assert(game.winner != ZERO(), 'it should have a winner');
    assert(game.winner == PLAYER2(), 'player 2 should win');
}


#[test]
#[available_gas(600000000)]
fn test_game_with_cheater_bad_reveal_value() {
    let mut world = setup();

    // admin create game
    let create_game_result = world
        .execute('create_game', array![PLAYER1().into(), PLAYER2().into()]);
    let game_id = *create_game_result.at(0);

    // player1 commit
    impersonate(PLAYER1());

    let player1_secret = 'player1_secret';
    let player1_choice = Choice::Rock;
    let player1_commit_value = pedersen(player1_choice.into(), player1_secret);

    world.execute('commit_value', array![game_id.into(), player1_commit_value]);

    // player2 commit
    impersonate(PLAYER2());

    let player2_secret = 'player2_secret';
    let player2_choice = Choice::Scissor;
    let player2_commit_value = pedersen(player2_choice.into(), player2_secret);

    world.execute('commit_value', array![game_id.into(), player2_commit_value]);

    // // player1 reveal another value !
    impersonate(PLAYER1());
    world.execute('reveal_value', array![game_id.into(), Choice::Scissor.into(), player1_secret]);

    // retrieve game
    let game = get!(world, (game_id), (Game));
    assert(game.winner != ZERO(), 'it should have a winner');
    assert(game.winner == PLAYER2(), 'player 2 should win');
}


#[test]
#[available_gas(600000000)]
fn test_game_with_cheater_bad_reveal_secret() {
    let mut world = setup();

    // admin create game
    let create_game_result = world
        .execute('create_game', array![PLAYER1().into(), PLAYER2().into()]);
    let game_id = *create_game_result.at(0);

    // player1 commit
    impersonate(PLAYER1());

    let player1_secret = 'player1_secret';
    let player1_choice = Choice::Rock;
    let player1_commit_value = pedersen(player1_choice.into(), player1_secret);

    world.execute('commit_value', array![game_id.into(), player1_commit_value]);

    // player2 commit
    impersonate(PLAYER2());

    let player2_secret = 'player2_secret';
    let player2_choice = Choice::Scissor;
    let player2_commit_value = pedersen(player2_choice.into(), player2_secret);

    world.execute('commit_value', array![game_id.into(), player2_commit_value]);

    // // player1 reveal another secret !
    impersonate(PLAYER1());
    world.execute('reveal_value', array![game_id.into(), player1_choice.into(), 'no gud secret']);

    // retrieve game
    let game = get!(world, (game_id), (Game));
    assert(game.winner != ZERO(), 'it should have a winner');
    assert(game.winner == PLAYER2(), 'player 2 should win');
}


#[test]
#[available_gas(600000000)]
#[should_panic(
    expected: ('already committed', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED')
)]
fn test_game_cannot_commit_twice() {
    let mut world = setup();

    // admin create game
    let create_game_result = world
        .execute('create_game', array![PLAYER1().into(), PLAYER2().into()]);
    let game_id = *create_game_result.at(0);

    // player1 commit
    impersonate(PLAYER1());

    let player1_secret = 'player1_secret';
    let player1_choice = Choice::Rock;
    let player1_commit_value = pedersen(player1_choice.into(), player1_secret);

    world.execute('commit_value', array![game_id.into(), player1_commit_value]);
    world.execute('commit_value', array![game_id.into(), player1_commit_value + 1]);
}


#[test]
#[available_gas(600000000)]
#[should_panic(
    expected: ('invalid player', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED')
)]
fn test_game_non_in_game_players_cant_commit() {
    let mut world = setup();

    // admin create game
    let create_game_result = world
        .execute('create_game', array![PLAYER1().into(), PLAYER2().into()]);
    let game_id = *create_game_result.at(0);

    // admin try to commit
    impersonate(ZERO());

    let player1_secret = 'player1_secret';
    let player1_choice = Choice::Rock;
    let player1_commit_value = pedersen(player1_choice.into(), player1_secret);

    world.execute('commit_value', array![game_id.into(), player1_commit_value]);
}

#[test]
#[available_gas(600000000)]
#[should_panic(
    expected: (
        'waiting opponent commit', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'
    )
)]
fn test_game_cannot_reveal_without_opponent_commit() {
    let mut world = setup();

    // admin create game
    let create_game_result = world
        .execute('create_game', array![PLAYER1().into(), PLAYER2().into()]);
    let game_id = *create_game_result.at(0);

    // player1 commit
    impersonate(PLAYER1());

    let player1_secret = 'player1_secret';
    let player1_choice = Choice::Rock;
    let player1_commit_value = pedersen(player1_choice.into(), player1_secret);

    world.execute('commit_value', array![game_id.into(), player1_commit_value]);

    //player1 reveal
    world.execute('reveal_value', array![game_id.into(), player1_choice.into(), player1_secret]);
}


//
// helper
//

fn simulate_game(
    world: IWorldDispatcher,
    game_id: felt252,
    player1: ContractAddress,
    player1_secret: felt252,
    player1_choice: Choice,
    player2: ContractAddress,
    player2_secret: felt252,
    player2_choice: Choice
) {
    // player1 commit
    impersonate(player1);

    let player1_commit_value = pedersen(player1_choice.into(), player1_secret);
    world.execute('commit_value', array![game_id.into(), player1_commit_value]);

    // player2 commit
    impersonate(player2);

    let player2_commit_value = pedersen(player2_choice.into(), player2_secret);
    world.execute('commit_value', array![game_id.into(), player2_commit_value]);

    // // player1 reveal
    impersonate(player1);
    world.execute('reveal_value', array![game_id.into(), player1_choice.into(), player1_secret]);

    // player2 reveal
    impersonate(player2);
    world.execute('reveal_value', array![game_id.into(), player2_choice.into(), player2_secret]);
}
