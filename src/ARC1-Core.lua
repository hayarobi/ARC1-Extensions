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

    assert(type(x) == 'string', "ARC1: address must be string type")

    -- check address length
    assert(52 == #x, string.format("ARC1: invalid address length: %s (%s)", x, #x))

    -- check character
    local invalidChar = string.match(x, '[^123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]')
    assert(nil == invalidChar, string.format("ARC1: invalid address format: %s contains invalid char %s", x, invalidChar or 'nil'))

  elseif (x and t == 'ubig') then   -- a positive big number

    -- check unsigned bignum
    assert(bignum.isbignum(x), string.format("ARC1: invalid type: %s != %s", type(x), t))
    assert(x >= bignum.number(0), string.format("ARC1: %s must be positive number", bignum.tostring(x)))

  elseif (x and t == 'uint') then   -- a positive number

    assert(type(x) == 'number', string.format("ARC1: invalid type: %s != number", type(x)))
    assert(math.floor(x) == x, "ARC1: the number must be an integer")
    assert(x >= 0, "ARC1: the number must be 0 or positive")

  else
    -- check default lua types
    assert(type(x) == t, string.format("ARC1: invalid type: %s != %s", type(x), t or 'nil'))

  end
end

function _check_bignum(x)
  if type(x) == 'string' then
    assert(string.match(x, '[^0-9]') == nil, "ARC1: amount contains invalid character")
    x = bignum.number(x)
  end
  _typecheck(x, 'ubig')
  return x
end

-- call this at constructor
-- @type internal
-- @param name (string) name of this token
-- @param symbol (string) symbol of this token
-- @param decimals (number) decimals of this token

local function _init(name, symbol, decimals)

  _typecheck(name, 'string')
  _typecheck(symbol, 'string')
  _typecheck(decimals, 'uint')

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
  if owner == nil then
    owner = system.getSender()
  else
    _typecheck(owner, 'address')
  end

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
-- @param   ...    additional data, is sent unaltered in call to 'tokensReceived' on 'to'
-- @return  value returned from 'tokensReceived' callback, or nil

local function _callTokensReceived(from, to, amount, ...)
  if system.isContract(to) then
    return contract.call(to, "tokensReceived", system.getSender(), from, amount, ...)
  else
    return nil
  end
end

-- Transfer tokens from an account to another
-- @type    internal
-- @param   from    (address) sender's address
-- @param   to      (address) recipient's address
-- @param   amount  (ubig)    amount of token to send
-- @param   ...     additional data, is sent unaltered in call to 'tokensReceived' on 'to'
-- @return  value returned from 'tokensReceived' callback, or nil

local function _transfer(from, to, amount, ...)
  assert(not _paused:get(), "ARC1: paused contract")
  assert(not _blacklist[from], "ARC1: sender is on blacklist")
  assert(not _blacklist[to], "ARC1: recipient is on blacklist")

  assert(_balances[from] and _balances[from] >= amount, "ARC1: not enough balance")

  _balances[from] = _balances[from] - amount
  _balances[to] = (_balances[to] or bignum.number(0)) + amount

  return _callTokensReceived(from, to, amount, ...)

end

-- Mint new tokens to an account
-- @type    internal
-- @param   to      (address) recipient's address
-- @param   amount  (ubig) amount of tokens to mint
-- @return  value returned from 'tokensReceived' callback, or nil

local function _mint(to, amount, ...)
  assert(not _paused:get(), "ARC1: paused contract")
  assert(not _blacklist[to], "ARC1: recipient is on blacklist")

  _totalSupply:set((_totalSupply:get() or bignum.number(0)) + amount)
  _balances[to] = (_balances[to] or bignum.number(0)) + amount

  return _callTokensReceived(system.getSender(), to, amount, ...)
end


-- Burn tokens from an account
-- @type    internal
-- @param   from   (address)
-- @param   amount  (ubig) amount of tokens to burn

local function _burn(from, amount)
  assert(not _paused:get(), "ARC1: paused contract")
  assert(not _blacklist[from], "ARC1: sender is on blacklist")

  assert(_balances[from] and _balances[from] >= amount, "ARC1: not enough balance")

  _totalSupply:set(_totalSupply:get() - amount)
  _balances[from] = _balances[from] - amount
end


-- Transfer tokens to an account (from TX sender)
-- @type    call
-- @param   to      (address) recipient's address
-- @param   amount  (ubig) amount of tokens to send
-- @param   ...     additional data, is sent unaltered in call to 'tokensReceived' on 'to'
-- @return  value returned from 'tokensReceived' callback, or nil
-- @event   transfer(nil, TX sender, to, amount)

function transfer(to, amount, ...)
  _typecheck(to, 'address')
  amount = _check_bignum(amount)

  contract.event("transfer", system.getSender(), to, bignum.tostring(amount), nil)

  return _transfer(system.getSender(), to, amount, ...)
end


-- Burn tokens (from TX sender)
-- @type    call
-- @param   amount  (ubig) amount of token to burn
-- @event   burn(nil, TX sender, amount)

function burn(amount)
  amount = _check_bignum(amount)

  _burn(system.getSender(), amount)

  contract.event("burn", system.getSender(), bignum.tostring(amount), nil)
end


abi.register(transfer, burn)
