------------------------------------------------------------------------------
-- Aergo Standard Token Interface (Proposal) - 20211028
-- Allowed approval
------------------------------------------------------------------------------

extensions["limited_approval"] = true

state.var {
  _allowance = state.map(),   -- address/address -> unsigned_bignum
}

-- Approve an account to spend the specified amount of Tx sender's tokens
-- @type    call
-- @param   operator (address) operator's address
-- @param   amount   (ubig)    amount of allowed tokens
-- @event   approve(Tx sender, operator, amount)

function approve(operator, amount)
  _typecheck(operator, 'address')
  amount = _check_bignum(amount)

  local owner = system.getSender()

  assert(owner ~= operator, "ARC1: cannot approve self as operator")

  _allowance[owner .. "/" .. operator] = amount

  contract.event("approve", owner, operator, bignum.tostring(amount))
end


-- Increase the amount of tokens that Tx sender allowed to an account
-- @type    call
-- @param   operator (address) operator's address
-- @param   amount   (ubig)    amount of increased tokens
-- @event   increaseAllowance(Tx sender, operator, amount)

function increaseAllowance(operator, amount)
  _typecheck(operator, 'address')
  amount = _check_bignum(amount)

  local owner = system.getSender()
  local pair = owner .. "/" .. operator

  assert(_allowance[pair], "ARC1: not approved")

  _allowance[pair] = _allowance[pair] + amount

  contract.event("increaseAllowance", owner, operator, bignum.tostring(amount))
end


-- Decrease the amount of tokens that Tx sender allowed to an account
-- @type    call
-- @param   operator (address) operator's address
-- @param   amount   (ubig)    amount of decreased tokens
-- @event   decreaseAllowance(Tx sender, operator, amount)

function decreaseAllowance(operator, amount)
  _typecheck(operator, 'address')
  amount = _check_bignum(amount)

  local owner = system.getSender()
  local pair = owner .. "/" .. operator

  assert(_allowance[pair], "ARC1: not approved")

  if _allowance[pair] < amount then
    _allowance[pair] = 0
  else
    _allowance[pair] = _allowance[pair] - amount
  end

  contract.event("decreaseAllowance", owner, operator, bignum.tostring(amount))
end


-- Get amount of remaining tokens that an account allowed to another
-- @type    query
-- @param   owner    (address) owner's address
-- @param   operator (address) operator's address
-- @return  (number) amount of remaining tokens

function allowance(owner, operator)
  _typecheck(owner, 'address')
  _typecheck(operator, 'address')

  return _allowance[owner .."/".. operator] or bignum.number(0)
end


-- Transfer tokens from an account to another using the allowance mechanism
-- @type    call
-- @param   from   (address) sender's address
-- @param   to     (address) recipient's address
-- @param   amount (ubig)    amount of tokens to send
-- @param   ...    additional data, is sent unaltered in call to 'tokensReceived' on 'to'
-- @return  value returned from 'tokensReceived' callback, or nil
-- @event   transfer(from, to, amount, operator)

function limitedTransferFrom(from, to, amount, ...)
  _typecheck(from, 'address')
  _typecheck(to, 'address')
  amount = _check_bignum(amount)

  local operator = system.getSender()

  assert(operator ~= from, "ARC1: use the transfer function")

  local pair = from .. "/" .. operator

  assert(_allowance[pair], "ARC1: not approved")
  assert(_allowance[pair] >= amount, "ARC1: insufficient allowance")

  _allowance[pair] = _allowance[pair] - amount

  contract.event("transfer", from, to, bignum.tostring(amount), operator)

  return _transfer(from, to, amount, ...)
end


abi.register(approve, increaseAllowance, decreaseAllowance, limitedTransferFrom)
abi.register_view(allowance)


-- Burn tokens from an account using the allowance mechanism
-- @type    call
-- @param   from    (address) sender's address
-- @param   amount  (ubig)    amount of tokens to burn
-- @event   burn(from, amount, operator)

if extensions["burnable"] == true then

function limitedBurnFrom(from, amount)
  _typecheck(from, 'address')
  amount = _check_bignum(amount)

  assert(extensions["burnable"], "ARC1: burnable extension not available")

  local operator = system.getSender()

  assert(operator ~= from, "ARC1: use the burn function")

  local pair = from .. "/" .. operator

  assert(_allowance[pair], "ARC1: caller not approved by holder")
  assert(_allowance[pair] >= amount, "ARC1: insufficient allowance")

  _allowance[pair] = _allowance[pair] - amount

  contract.event("burn", from, bignum.tostring(amount), operator)

  _burn(from, amount)
end

abi.register(limitedBurnFrom)

end
