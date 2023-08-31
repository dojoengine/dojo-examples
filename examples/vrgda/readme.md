## VRGDA

- [VRGDA](https://www.paradigm.xyz/2022/08/vrgda)
- [Dojo Defi](https://github.com/dojoengine/dojo/tree/main/crates/dojo-defi)

### Overview

This is an incomplete implementation showing how you can use the VRGDA dojo-module in a dojo world easily.

In this example we create a system that is responsible to maintaining the state of an VRGDA within a dojo component. This component is stored using a component key, so multiple auctions can run at the same time within the world, and multiple games can be run.

#### Systems

- `buy`: responsible for buying the VRGDA
- `start_auction`: responsible for starting the auction
- `view_price`: responsible for viewing the price of the auction


#### TODO:
- [] Add game start and end, along with checks on systems
- [] Integrate ERC20 or ERC721 modules