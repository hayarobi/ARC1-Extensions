------------------------------------------------------------------------------
-- Aergo Standard Token Interface (Proposal) - 20211028
-- Allowed approval
------------------------------------------------------------------------------

state.var {

  -- limited approval
  _allowance = state.map(),   -- address/address -> unsigned_bignum
}


-- Approve an account to spend the specified amount of Tx sender's tokens
-- @type    call
-- @param   spender (address) spender's address
-- @param   amount  (ubig)    amount of allowed tokens
-- @event   approve(Tx sender, spender, amount)

function approve(spender, amount)
  _typecheck(spender, 'address')
  _typecheck(amount, 'ubig')

  assert(system.getSender() ~= spender, "cannot set approve self")

  _allowance[system.getSender().."/".. spender] = amount

  contract.event("approve", system.getSender(), spender, amount)
end


-- Increase the amount of tokens that Tx sender allowed to an account
-- @type    call
-- @param   spender (address) spender's address
-- @param   amount  (ubig)    amount of increased tokens
-- @event   increaseAllowance(Tx sender, spender, amount)

function increaseAllowance(spender, amount)
  _typecheck(spender, 'address')
  _typecheck(amount, 'ubig')

  assert(_allowance[system.getSender().."/".. spender], "no approved")

  _allowance[system.getSender().."/".. spender] = _allowance[system.getSender().."/".. spender] + amount

  contract.event("increaseAllowance", system.getSender(), spender, amount)
end


-- Decrease the amount of tokens that Tx sender allowed to an account
-- @type    call
-- @param   spender (address) spender's address
-- @param   amount  (ubig)    amount of decreased tokens
-- @event   decreaseAllowance(Tx sender, spender, amount)

function decreaseAllowance(spender, amount)
  _typecheck(spender, 'address')
  _typecheck(amount, 'ubig')

  assert(_allowance[system.getSender().."/".. spender], "no approved")

  if _allowance[system.getSender().."/".. spender] < amount then
    _allowance[system.getSender().."/".. spender] = 0
  else
    _allowance[system.getSender().."/".. spender] = _allowance[system.getSender().."/".. spender] - amount
  end

  contract.event("decreaseAllowance", system.getSender(), spender, amount)
end


-- Get amount of remaining tokens that an account allowed to another
-- @type    query
-- @param   owner   (address) owner's address
-- @param   spender (address) spender's address
-- @return  (number) amount of remaining tokens

function allowance(owner, spender)
  _typecheck(owner, 'address')
  _typecheck(spender, 'address')

  return _allowance[owner .."/".. spender] or bignum.number(0)
end


-- Transfer tokens from an account to another using the allowance mechanism
-- @type    call
-- @param   from   (address) sender's address
-- @param   to     (address) recipient's address
-- @param   amount (ubig)    amount of tokens to send
-- @param   ...     addtional data, MUST be sent unaltered in call to 'tokensReceived' on 'to'
-- @event   transferFrom(Tx sender, from, to, amount)

function transferFromLtd(from, to, amount, ...)
  _typecheck(from, 'address')
  _typecheck(to, 'address')
  _typecheck(amount, 'ubig')

  assert(_allowance[from .."/".. system.getSender()], "no approved")
  assert(_allowance[from .."/".. system.getSender()] >= amount, "insufficient allowance")

  _transfer(from, to, amount, ...)
  _allowance[from .."/".. system.getSender()] = _allowance[from .."/".. system.getSender()] - amount

  -- contract.event("transferFrom", system.getSender(), from, to, amount)
  contract.event("transfer", from, to, amount)
end


-- Burn tokens from an account using the allowance mechanism
-- @type    call
-- @param   from    (address) sender's address
-- @param   amount  (ubig)    amount of tokens to burn
-- @event   burnFrom(Tx sender, from, amount)

function burnFromLtd(from, amount)
  _typecheck(from, 'address')
  _typecheck(amount, 'ubig')

  assert(_allowance[from .."/".. system.getSender()], "no approved")
  assert(_allowance[from .."/".. system.getSender()] >= amount, "insufficient allowance")

  _burn(from, amount)
  _allowance[from .."/".. system.getSender()] = _allowance[from .."/".. system.getSender()] - amount

  -- contract.event("burnFrom", system.getSender(), from, amount)
  contract.event("transfer", from, address0, amount)
end


abi.register(approve,increaseAllowance,decreaseAllowance,transferFromLtd,burnFromLtd)
abi.register_view(allowance)
