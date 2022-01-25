state = {}

function state.map()
    return {}
end

function state.value()
    amount = {v=nil}

    function amount:get()
        return self.v
    end

    function amount:set(v)
        self.v = v
    end

    return amount
end

system = {cr = '2222222', se = '2222222'}
--system = {cr=nil, se=nil}
function system.getCreator()
      return system.cr
end

function system.getSender()
    return system.se
end

function system.setCreator(c)
      system.cr = c
end

function system.setSender(c)
      system.se = c
end

local function _typecheck(x, t)
    return true
end

contract = {}

function contract.event(...)
    print(...)
    return true
end

bignum = {}
function bignum.number(a)
    return a
end

  -- mintable
_minter = state.map()   -- address/address -> boolean
_balances = state.map()
_totalSupply = state.value()
_paused = state.value()

_totalSupply:set(0)
_paused:set(false)

local function _mint(to, amount, ...)
  assert(not _paused:get(), "paused contract")

  _totalSupply:set((_totalSupply:get() or bignum.number(0)) + amount)
  _balances[to] = (_balances[to] or bignum.number(0)) + amount
end

local function _burn(from, amount)
  assert(not _paused:get(), "paused contract")
  assert(_balances[from] and _balances[from] >= amount, "not enough balance")

  _totalSupply:set(_totalSupply:get() - amount)
  _balances[from] = _balances[from] - amount
end

local function _transfer(from, to, amount, ...)
  assert(not _paused:get(), "paused contract")
  assert(_balances[from] and _balances[from] >= amount, "not enough balance")

  _balances[from] = _balances[from] - amount
  _balances[to] = (_balances[to] or bignum.number(0)) + amount
end


function balanceOf(owner)
  _typecheck(owner, 'address')
  return _balances[owner] or bignum.number(0)
end

function transfer(to, amount, ...)
  _typecheck(to, 'address')
  _typecheck(amount, 'ubig')

  _transfer(system.getSender(), to, amount, ...)
--  _callTokensReceived(from, to, amount, ...)

  contract.event("transfer", system.getSender(), to, amount)
end

-- Get allowance to Minter Role of an account
-- @type    query
-- @param   account   (address) an address
-- @return  (bool) true/false
function isMinter(account)
  _typecheck(account, 'address')
  return (account == system.getCreator()) or (_minter[account]==true)
end

-- Add Minter Role to an account
-- @type    call
-- @param   account  (address) a minter's address
-- @event   addMinter(account)
function addMinter(account)
  _typecheck(account, 'address')

  assert(system.getSender() == system.getCreator(), "only contract owner can add to minter")

  _minter[account] = true
  contract.event("addMinter", account)
end

-- Remove Minter Role form an account
-- @type    call
-- @param   account  (address) an address
-- @event   removeMinter(account)
function removeMinter(account)
  _typecheck(account, 'address')

  assert(system.getSender() == system.getCreator(), "only contract owner can remove minter")
  assert(isMinter(account), "only minter can be removed from minters")

  _minter[account] = nil
  contract.event("removeMinter", account)
end

-- Renounce Minter Role of an account
-- @type    call
-- @event   removeMinter(account)
function renounceMinter()
  assert(system.getSender() ~= system.getCreator(), "contract owner can't renounce minter role")
  assert(isMinter(system.getSender()), "only minter can renounce to mint")

  _minter[system.getSender()] = nil
  contract.event("removeMinter", system.getSender())
end

-- Mint new tokens at an account
-- @type    call
-- @param   account  (address) receiver
-- @param   amount  (ubig) an amount of token to mint
-- @event   mint(minter, receiver, amount)
function mint(account, amount)
  _typecheck(account, 'address')
  _typecheck(amount, 'ubig')

  assert(isMinter(system.getSender()), "only minter can mint")

  _mint(account, amount)

  contract.event("mint", system.getSender(), account, amount)
end

system.setCreator('2222222')
system.setSender('2222222')

addMinter('3222222')
system.setSender('3222222')

mint('2222222',1000)
print(balanceOf('2222222'))

system.setSender('2222222')
removeMinter('3222222')

addMinter('3222222')
system.setSender('3222222')

mint('2222222',1000)
print(balanceOf('2222222'))

renounceMinter()

system.setSender('2222222')

addMinter('3222222')
system.setSender('3222222')

mint('2222222',1000)
print(balanceOf('2222222'))

------------------------------------------------------------------------------
-- Aergo Standard Token Interface (Proposal) - 20211028
-- Pausable
------------------------------------------------------------------------------

--state.var {
  -- pauable
_pauser = state.map()   -- address/address -> boolean
--}

-- Get allowance to Pauser Role of an account
-- @type    query
-- @param   account   (address) an address
-- @return  (bool) true/false
function isPauser(account)
  return (account == system.getCreator()) or (_pauser[account]==true)
end

-- Add Pauser Role to an account
-- @type    call
-- @param   account  (address) a pauser's address
-- @event   addPauser(account)
function addPauser(account)
  _typecheck(account, 'address')

  assert(system.getSender() == system.getCreator(), "only contract owner can approve pauser role")

  _pauser[account] = true
  contract.event("addPauser", account)
end

-- Remove Pauser Role form an account
-- @type    call
-- @param   account  (address) an address
-- @event   removePauser(account)
function removePauser(account)
  _typecheck(account, 'address')

  assert(system.getSender() == system.getCreator(), "only contract owner can remove pauser role")
  assert(isPauser(account), "only minter can be removed pauser role")

  _pauser[account] = nil
  contract.event("removePauser", account)
end

-- Renounce Pauser Role of an account
-- @type    call
-- @event   removePauser(account)
function renouncePauser()
  assert(system.getSender() ~= system.getCreator(), "contract owner can't renounce pauser role")
  assert(isPauser(system.getSender()), "only minter can renounce pauser role")

  _pauser[system.getSender()] = nil
  contract.event("removePauser", system.getSender())
end


-- Returns true if the contract is paused, and false otherwise.
-- @type    query
-- @return  (bool) true/false
function paused()
  return (_paused:get())
end

-- Called by only the contract creator's account to pause, triggers stopped state.
-- @type    call
-- @event   pause(pauser)
function pause()
  assert(not _paused:get(), "paused contract")
  assert(isPauser(system.getSender()), "only pauser can pause")

  _paused:set(true)
  contract.event("pause", system.getSender())
end

-- Called by only the contract creator's account to unpause, returns to normal state.
-- @type    call
-- @event   unpause(unpauser)
function unpause()
  assert(_paused:get(), "unpaused contract")
  assert(isPauser(system.getSender()), "only pauser can unpause")

  _paused:set(false)
  contract.event("unpause", system.getSender())
end

system.setCreator('2222222')
system.setSender('2222222')

pause()
unpause()

mint('2222222',1000)
transfer('3222222',1000)
print('3', balanceOf('3222222'))

addPauser('3222222')
system.setSender('3222222')

pause()
unpause()

mint('2222222',1000)
transfer('4222222',1000)
print('4', balanceOf('4222222'))

--
system.setSender('2222222')
removePauser('3222222')

mint('2222222',1000)
transfer('3222222',1000)
print('3', balanceOf('3222222'))

addPauser('3222222')
system.setSender('3222222')

pause()
unpause()

mint('2222222',1000)
transfer('4222222',1000)
print('4', balanceOf('4222222'))

renouncePauser()
print(isPauser('3222222'))

---------

------------------------------------------------------------------------------
-- Aergo Standard Token Interface (Proposal) - 20211028
-- Allowed approval
------------------------------------------------------------------------------

-- Token Data
--state.var {

  -- Allowed approval
 _allowance = state.map()   -- address/address -> unsigned_bignum
--}

-- Sets amount as the allowance of spender over the caller’s tokens
-- @type    call
-- @param   spender (address) a spender's address
-- @param   amount  (ubig) an amount of allowed tokens
-- @event   approve(owner, operator, amount)
function approve(spender, amount)
  _typecheck(spender, 'address')
  _typecheck(amount, 'ubig')

  assert(system.getSender() ~= spender, "cannot set approve self")

  _allowance[system.getSender().."/".. spender] = amount

  contract.event("approve", system.getSender(), spender, amount)
end

-- Atomically increases the allowance granted to spender by the caller.
-- @type    call
-- @param   spender (address) a spender's address
-- @param   amount  (ubig) an amount of increased tokens
-- @event   increaseAllowance(owner, operator, amount)
function increaseAllowance(spender, amount)
  _typecheck(spender, 'address')
  _typecheck(amount, 'ubig')

  assert(_allowance[system.getSender().."/".. spender], "no approved")

  _allowance[system.getSender().."/".. spender] = _allowance[system.getSender().."/".. spender] + amount

  contract.event("increaseAllowance", system.getSender(), spender, amount)
end

-- Atomically decreases the allowance granted to spender by the caller.
-- @type    call
-- @param   spender (address) a spender's address
-- @param   amount  (ubig) an amount of decreased tokens
-- @event   decreaseAllowance(owner, operator, amount)
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

-- Returns the remaining number of tokens that spender will be allowed to spend on behalf of owner
-- @type    query
-- @param   owner   (address) a owner's address
-- @param   spender (address) a spender's address
function allowance(owner, spender)
  _typecheck(owner, 'address')
  _typecheck(spender, 'address')

  return _allowance[owner .."/".. spender] or bignum.number(0)
end

-- Moves amount tokens from sender to recipient using the allowance mechanism.
-- @type    call
-- @param   from   (address) a owner's address
-- @param   to     (address) a spender's address
-- @param   amount  (ubig) an amount of tokens to send
-- @param   ...     addtional data, MUST be sent unaltered in call to 'tokensReceived' on 'to'
-- @event   transferFrom(operator, sender, receiver, amount)
function transferFromLtd(from, to, amount, ...)
  _typecheck(from, 'address')
  _typecheck(to, 'address')
  _typecheck(amount, 'ubig')

  assert(_allowance[from .."/".. system.getSender()], "no approved")
  assert(_allowance[from .."/".. system.getSender()] >= amount, "insufficient allowance")

  _transfer(from, to, amount, ...)

  _allowance[from .."/".. system.getSender()] = _allowance[from .."/".. system.getSender()] - amount

--  _callTokensReceived(from, to, amount, ...)

  contract.event("transferFrom", system.getSender(), from, to, amount)
end

-- burn 'from's token.
-- Tx sender have to be approved to spend from 'from'
-- @type    call
-- @param   from    (address) a sender's address
-- @param   to      (address) a receiver's address
-- @param   amount   (ubig) an amount of token to send
-- @param   ...     addtional data, MUST be sent unaltered in call to 'tokensReceived' on 'to'
-- @event   burnFrom(operator, sender, receiver, amount)
function burnFromLtd(from, amount, ...)
  _typecheck(from, 'address')
  _typecheck(amount, 'ubig')

  assert(_allowance[from .."/".. system.getSender()], "no approved")
  assert(_allowance[from .."/".. system.getSender()] >= amount, "insufficient allowance")

  _burn(from, amount)

  contract.event("burnFrom", system.getSender(), from, amount)
end

---
system.setSender('4222222')
approve('3222222',1500)
print('allow', '4222222', '3222222', allowance('4222222', '3222222'))

system.setSender('3222222')
transferFromLtd('4222222','5222222',1000)
print('5', balanceOf('5222222'))
print('4', balanceOf('4222222'))
print('allow', '4222222', '3222222', allowance('4222222', '3222222'))

system.setSender('4222222')
increaseAllowance('3222222',1000)
print('allow', '4222222', '3222222', allowance('4222222', '3222222'))

system.setSender('3222222')
transferFromLtd('4222222','5222222',500)
print('5', balanceOf('5222222'))
print('4', balanceOf('4222222'))

burnFromLtd('4222222',500)
print('4', balanceOf('4222222'))



-- state.var {

  -- Blacklist
_blacklist = state.map()    -- address -> boolean
-- }

-- Add account list to blacklist
-- Tx sender have to be approved to spend from 'from'
-- @type    call
-- @param   addr_list    (list of address)
-- @event   addBlacklist(addr_list)
function addToBlacklist(addr_list)
  assert(system.getSender() == system.getCreator(), "only contract owner can blacklist")

  for i = 1, #addr_list do
    _typecheck(addr_list[i], 'address')
    _blacklist[addr_list[i]] = true
  end

  contract.event("addBlacklist", addr_list)
end

-- Add account list to blacklist
-- Tx sender have to be approved to spend from 'from'
-- @type    call
-- @param   addr_list    (list of address)
-- @event   addBlacklist(addr_list)
function removeFromBlacklist(addr_list)
  assert(system.getSender() == system.getCreator(), "only contract owner can blacklist")
  for i = 1, #addr_list do
    _typecheck(addr_list[i], 'address')
    _blacklist[addr_list[i]] = nil
  end
  contract.event("rmBlacklist", addr_list)
end


function isOnBlacklist(addr)
  _typecheck(account, 'address')
  return _blacklist[addr] == true
end

function transferByF(to, amount, ...)
  assert(not isOnBlacklist(to),'receiver account is on blacklist')
  transfer(to, amount, ...)
end

----
system.setSender('2222222')
addToBlacklist({'3222222'})

print(isOnBlacklist('3222222'))
print(isOnBlacklist('2222222'))

removeFromBlacklist({'3222222'})
print(isOnBlacklist('3222222'))

transferByF('3222222',1000)

----

------------------------------------------------------------------------------
-- Aergo Standard Token Interface (Proposal) - 20211028
-- All approval
------------------------------------------------------------------------------

------------------------------------------------------------------------------
---- State Data for Token
------------------------------------------------------------------------------

--state.var {
  -- All Approval
_operators = state.map()   -- address/address -> boolean
--}

-- Get allowance from owner to spender
-- @type    query
-- @param   owner       (address) owner's address
-- @param   operator    (address) allowed address
-- @return  (bool) true/false
function isApprovedForAll(owner, operator)
  return (owner == operator) or (_operators[owner.."/".. operator] == true)
end

-- Allow operator to use all sender's token
-- @type    call
-- @param   operator  (address) a operator's address
-- @param   approved  (boolean) true/false
-- @event   setApprovalForAll(owner, operator, approved)
function setApprovalForAll(operator, approved)
  _typecheck(operator, 'address')
  _typecheck(approved, 'boolean')

  assert(system.getSender() ~= operator, "cannot set approve self as operator")

  if not approved then
     _operators[system.getSender().."/".. operator] = nil
  else
    _operators[system.getSender().."/".. operator] = true
  end

  contract.event("setApprovalForAll", system.getSender(), operator, approved)
end

-- Transfer 'from's token to target 'to'.
-- Tx sender have to be approved to spend from 'from'
-- @type    call
-- @param   from    (address) a sender's address
-- @param   to      (address) a receiver's address
-- @param   amount   (ubig) an amount of token to send
-- @param   ...     addtional data, MUST be sent unaltered in call to 'tokensReceived' on 'to'
-- @event   transferFrom(operator, sender, receiver, amount)
function transferFromAll(from, to, amount, ...)
  _typecheck(from, 'address')
  _typecheck(to, 'address')
  _typecheck(amount, 'ubig')

  assert(isApprovedForAll(from, system.getSender()), "caller is not approved for holder")

  _transfer(from, to, amount, ...)
 -- _callTokensReceived(from, to, amount, ...)
  contract.event("transferFrom", system.getSender(), from, to, amount)
end

-- burn 'from's token.
-- Tx sender have to be approved to spend from 'from'
-- @type    call
-- @param   from    (address) a sender's address
-- @param   to      (address) a receiver's address
-- @param   amount   (ubig) an amount of token to send
-- @param   ...     addtional data, MUST be sent unaltered in call to 'tokensReceived' on 'to'
-- @event   burnFrom(operator, from, amount)
function burnFromAll(from, amount, ...)
  _typecheck(from, 'address')
  _typecheck(amount, 'ubig')

  assert(isApprovedForAll(from, system.getSender()), "caller is not approved for holder")
  _burn(from, amount)

  contract.event("burnFrom", system.getSender(), from, amount)
end

system.setSender('2222222')
mint('4222222',2000)

system.setSender('4222222')
setApprovalForAll('3222222',true)

print('allow', '4222222', '3222222', isApprovedForAll('4222222', '3222222'))


system.setSender('3222222')
transferFromAll('4222222','5222222',500)

print('5', balanceOf('5222222'))
print('4', balanceOf('4222222'))

system.setSender('4222222')
setApprovalForAll('3222222',false)

system.setSender('3222222')
burnFromAll('4222222',500)
print('4', balanceOf('4222222'))
