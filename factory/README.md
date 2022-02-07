# ARC1 Token Factory

It is a contract that is used to create ARC1 token contracts

We create a new token by calling the `new_token` function and informing
the arguments:

* Name
* Symbol
* Decimals
* Initial Supply
* Options (optional)
* Owner   (optional)

The options is a table informing which extensions to add to the token:

* mintable
* blacklist
* pausable
* all_approval
* limited_approval

The `owner` is the address that will be registered as the owner of the
token contract. By default it is the entity calling the factory, but
we can specify any address.


## Creating from another contract

The call uses this format:

```lua
contract.call(arc1_factory, "new_token", name, symbol, decimals,
              initial_supply, options)
```

The function returns the contract address.

Here is an example:

```lua
local token = contract.call(arc1_factory, "new_token", name, symbol, 18,
                            '1000000', {mintable=true,blacklist=true})
```

And how to inform a max supply (for mintable tokens):

```lua
local token = contract.call(arc1_factory, "new_token", name, symbol, 18,
                            '1000000', {mintable=true,max_supply='5000000'})
```

> :warning: Notice that the `initial_supply` and `max_supply` do not contain
> the decimals. They can be either string or bignum.

The factory can also be called from herajs, herapy, libaergo...


## Token Factory Address

<table>
  <tr><td>testnet</td><td>AmggWvbwQGUxXkk5BGAnmv3C3VocveuaPQDb8N7QDYbi6FkAJeBs</td></tr>
  <tr><td>alphanet</td><td>AmhAdUDbfmDR3sCreuqnrVS5pk31a8kf8aMieuzwSJQWdMi5Ukpe</td></tr>
</table>


## Updating the Factory

If some of the contract files were modified, a new factory can be created.

Run:

```
./build.sh
```

Then deploy the generated `output.lua` to the network and update services
that use it.
