# Harberger Tax System

Welcome to the Harberger Tax System! This smart contract is designed to implement a Harberger tax mechanismusing Dojo . We'll explain what Harberger taxes are and provide an overview of how they are implemented in this code.

This implementation is heavily inspired by https://programtheblockchain.com/posts/2018/09/19/implementing-harberger-tax-deeds/ so you can check the article out to understand harberger taxes better.

## What Are Harberger Taxes?

Harberger taxes are a unique taxation system that encourages efficient allocation of resources. Here's how they work:

1. **Self-Assessment**: Individuals or entities declare the value of their assets. They must be willing to sell the asset at this value.

2. **Tax Payment**: They pay taxes based on their self-assessed values.

3. **Continuous Market Interaction**: Asset owners must sell the asset to anyone willing to pay the declared price. This ensures assets are used efficiently.

## Example Usage

Let's walk through an example of how a Harberger tax system would work with this smart contract:

1. **Initialization and Minting Tokens**: The contract is initialized with specific tax parameters, including the tax admin, tax recipient, and tax rates. Tokens can also be minted, making them available for sale.

2. **Deposits**: Users would deposit funds so they can purchase one or more of the minted tokens.

3. **Buying Tokens**: Users can purchase tokens, specifying the maximum price they are willing to pay as well as the new price they want to set for the token. The new price would also be the price they pay taxes on. The amount paid is then deducted from their account balance and added to the previous owner's account balance.

4. **Tax Collection**: The contract can calculate the taxes due for any address based on the tax rate specified and the `collect_taxes` function can be called to collect taxes owed by an address by anyone at anytime. If the taxes are not paid, the token is foreclosed.

5. **Foreclosure**: Forclosure here means resetting ownership of a token and setting the price to zero when an account does not have sufficient funds to pay/cover taxes.


## Implementation Details

### Contract Functions

#### `initialize`

This function initializes the Harberger Tax System with a specific tax structure and mints initial tokens which will be available for sale. 

```
initialize(world, new_tax_meta, token_ids);
```

#### `mint`

This function mints additional tokens provided the caller has sufficient permission. 

```
mint(world, token_ids);
```

#### `change_tax_admin`

Changes the tax admin to a new address. 

```
change_tax_admin(world, new_admin);
```

#### `change_tax_recipient`

Changes the tax recipient to a new address. 

```
change_tax_recipient(world, new_recipient);
```

#### `deposit`

Allows users to deposit funds into their contract managed accounts. 

```
deposit(world, amount);
```

#### `withdraw`

Lets users withdraw funds from their contract managed accounts. 

```
withdraw(world, amount);
```

#### `get_taxes_due`

Calculates the taxes due for a given address. 

```
let taxes = get_taxes_due(world, address);
```

#### `foreclose`

This function allows the foreclosure of a token when an account is eligible. 

```
foreclose(world, token_id);
```

#### `collect_taxes`

Collects taxes owed by an address. 

```
let success = collect_taxes(world, address);
```

#### `buy`

Enables the purchase of a token by specifying the maximum price they are willing to pay and the new price they would like to sell the token for and pay taxes on. 

```
buy(world, token_id, max_price, price);
```



The whole system tries to encourage efficient resource allocation and fair taxation.