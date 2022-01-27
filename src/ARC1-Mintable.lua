------------------------------------------------------------------------------
-- Aergo Standard Token Interface (Proposal) - 20211028
-- Mintable
------------------------------------------------------------------------------

state.var {
  -- mintable
  _minter = state.map(),   	-- address -> boolean
  _max_supply = state.value()     -- unsigned_bignum
}

-- set Max Supply
-- @type    internal
-- @param   amount   (ubig) amount of mintable tokens

local function _setMaxSupply(amount)
  _typecheck(amount, 'ubig')
  _max_supply:set(amount)
end

-- Indicate if an account is a minter
-- @type    query
-- @param   account  (address)
-- @return  (bool) true/false

function isMinter(account)
  _typecheck(account, 'address')

  return (account == system.getCreator()) or (_minter[account]==true)
end


-- Add an account to minters
-- @type    call
-- @param   account  (address)
-- @event   addMinter(account)

function addMinter(account)
  _typecheck(account, 'address')

  assert(system.getSender() == system.getCreator(), "only contract owner can add to minter")

  _minter[account] = true

  contract.event("addMinter", account)
end


-- Remove an account from minters
-- @type    call
-- @param   account  (address)
-- @event   removeMinter(account)

function removeMinter(account)
  _typecheck(account, 'address')

  assert(system.getSender() == system.getCreator(), "only contract owner can remove minter role")
  assert(isMinter(account), "only minter can be removed minter role")

  _minter[account] = nil

  contract.event("removeMinter", account)
end


-- Renounce the Minter Role of TX sender
-- @type    call
-- @event   removeMinter(TX sender)

function renounceMinter()
  assert(system.getSender() ~= system.getCreator(), "contract owner can't renounce minter role")
  assert(isMinter(system.getSender()), "only minter can renounce minter role")

  _minter[system.getSender()] = nil

  contract.event("removeMinter", system.getSender())
end


-- Mint new tokens at an account
-- @type    call
-- @param   account  (address) recipient's address
-- @param   amount   (ubig) amount of tokens to mint
-- @event   mint(account, amount) -- tobe

function mint(account, amount)
  _typecheck(account, 'address')
  _typecheck(amount, 'ubig')

  assert(isMinter(system.getSender()), "only minter can mint")
  assert(not _max_supply:get() or (_totalSupply:get()+amount) <= _max_supply:get(), 'totalSupply is over MaxSupply')
  _mint(account, amount)
  contract.event("mint", account, amount)
end

-- return Max Supply
-- @type    query
-- @return  amount   (ubig) amount of tokens to mint

function maxSupply()
  return _max_supply:get() or bignum.number(0)
end

abi.register(mint, addMinter, removeMinter, renounceMinter)
abi.register_view(isMinter, maxSupply)
