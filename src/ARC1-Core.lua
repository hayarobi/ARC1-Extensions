------------------------------------------------------------------------------
-- Aergo Standard Token Interface (Proposal) - 20211028
-- Core (+Burnable)
------------------------------------------------------------------------------

---- State Data for Token
state.var {

  _balances = state.map(),        -- address -> unsigned_bignum
  _totalSupply = state.value(),   -- unsigned_bignum

  _name = state.value(),          -- string
  _symbol = state.value(),        -- string
  _decimals = state.value(),      -- string

  -- Pausable
  _paused = state.value(),        -- boolean

  -- Blacklist
  _blacklist = state.map()        -- address -> boolean

}

address0 = '1111111111111111111111111111111111111111111111111111' -- null address

-- Type check
-- @type internal
-- @param x variable to check
-- @param t (string) expected type

local function _typecheck(x, t)

  if (x and t == 'address') then -- a string of alphanumeric char. except for '0, I, O, l'

    assert(type(x) == 'string', "address must be string type")

    -- check address length
    assert(52 == #x, string.format("invalid address length: %s (%s)", x, #x))

    -- check character
    local invalidChar = string.match(x, '[^123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]')
    assert(nil == invalidChar, string.format("invalid address format: %s contains invalid char %s", x, invalidChar or 'nil'))

  elseif (x and t == 'ubig') then   -- a positive big number

    -- check unsigned bignum
    assert(bignum.isbignum(x), string.format("invalid type: %s != %s", type(x), t))
    assert(x >= bignum.number(0), string.format("%s must be positive number", bignum.tostring(x)))

  else
    -- check default lua types
    assert(type(x) == t, string.format("invalid type: %s != %s", type(x), t or 'nil'))

  end
end


-- call this at constructor
-- @type internal
-- @param name (string) name of this token
-- @param symbol (string) symbol of this token
-- @param decimals (number) decimals of this token

local function _init(name, symbol, decimals)

  _typecheck(name, 'string')
  _typecheck(symbol, 'string')
  _typecheck(decimals, 'number')

  assert(decimals > 0)

  _name:set(name)
  _symbol:set(symbol)
  _decimals:set(decimals)

  _totalSupply:set(bignum.number(0))
  _paused:set(false)

end

-- Get a token name
-- @type    query
-- @return  (string) name of this token

function name()
  return _name:get()
end


-- Get a token symbol
-- @type    query
-- @return  (string) symbol of this token

function symbol()
  return _symbol:get()
end


-- Get a token decimals
-- @type    query
-- @return  (number) decimals of this token

function decimals()
  return _decimals:get()
end


-- Get a balance of an account
-- @type    query
-- @param   owner  (address)
-- @return  (ubig) balance of owner

function balanceOf(owner)
  _typecheck(owner, 'address')

  return _balances[owner] or bignum.number(0)
end


-- return total supply.
-- @type    query
-- @return  (ubig) total supply of this token

function totalSupply()
  return _totalSupply:get()
end


abi.register_view(name, symbol, decimals, totalSupply, balanceOf)


-- Hook "tokensReceived" function on the recipient after a 'transfer'
-- @type internal
-- @param   from   (address) sender's address
-- @param   to     (address) recipient's address
-- @param   amount (ubig) amount of token to send
-- @param   ...     addtional data, MUST be sent unaltered in call to 'tokensReceived' on 'to'

local function _callTokensReceived(from, to, amount, ...)

  -- if to ~= system.getContractID() and system.isContract(to) then
  if to ~= address0 and system.isContract(to) then
    contract.call(to, "tokensReceived", system.getSender(), from, amount, ...)
  end
end

-- Transfer tokens from an account to another
-- @type    internal
-- @param   from    (address) sender's address
-- @param   to      (address) recipient's address
-- @param   amount   (ubig)   amount of token to send
-- @param   ...     addtional data, MUST be sent unaltered in call to 'tokensReceived' on 'to'

local function _transfer(from, to, amount, ...)
  assert(not _paused:get(), "paused contract")
  assert(not _blacklist[from],'sender is on blacklist')
  assert(not _blacklist[to],'recipient is on blacklist')

  assert(_balances[from] and _balances[from] >= amount, "not enough balance")

  _balances[from] = _balances[from] - amount
  _balances[to] = (_balances[to] or bignum.number(0)) + amount

  _callTokensReceived(from, to, amount, ...)
end

-- Mint new tokens to an account
-- @type    internal
-- @param   to      (address) recipient's address
-- @param   amount  (ubig) amount of tokens to mint

local function _mint(to, amount, ...)
  assert(not _paused:get(), "paused contract")
  assert(not _blacklist[to],'recipient is on blacklist')

  _totalSupply:set((_totalSupply:get() or bignum.number(0)) + amount)
  _balances[to] = (_balances[to] or bignum.number(0)) + amount

  _callTokensReceived(system.getSender(), to, amount, ...)
end


-- Burn tokens from an account
-- @type    internal
-- @param   from   (address)
-- @param   amount  (ubig) amount of tokens to burn

local function _burn(from, amount)
  assert(not _paused:get(), "paused contract")
  assert(not _blacklist[from],'sender is on blacklist')

  assert(_balances[from] and _balances[from] >= amount, "not enough balance")

  _totalSupply:set(_totalSupply:get() - amount)
  _balances[from] = _balances[from] - amount
end




-- Transfer tokens to an account (from TX sender)
-- @type    call
-- @param   to      (address) recipient's address
-- @param   amount  (ubig) amount of tokens to send
-- @param   ...     addtional data, MUST be sent unaltered in call to 'tokensReceived' on 'to'
-- @event   transfer(TX sender, to, amount)

function transfer(to, amount, ...)
  _typecheck(to, 'address')
  _typecheck(amount, 'ubig')

  _transfer(system.getSender(), to, amount, ...)

  contract.event("transfer", system.getSender(), to, amount)
end


-- Burn tokens (from TX sender)
-- @type    call
-- @param   amount  (ubig) amount of token to burn
-- @event   burn(TX sender, amount)

function burn(amount)
  _typecheck(amount, 'ubig')

  _burn(system.getSender(), amount)

--  contract.event("burn", system.getSender(), amount)
  contract.event("transfer", system.getSender(), address0, amount)
end


abi.register(transfer, burn)
