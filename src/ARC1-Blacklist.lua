------------------------------------------------------------------------------
-- Aergo Standard Token Interface (Proposal) - 20211028
-- Blacklist
------------------------------------------------------------------------------

state.var {

  -- Blacklist
  _blacklist = state.map()    -- address -> boolean
}


-- Add accounts to blacklist.
-- @type    call
-- @param   account_list    (list of address)
-- @event   addToBlacklist(account_list)

function addToBlacklist(account_list)
  assert(system.getSender() == system.getCreator(), "only owner can blacklist anothers")

  for i = 1, #account_list do
    _typecheck(account_list[i], 'address')
    _blacklist[account_list[i]] = true
  end

  contract.event("addToBlacklist", account_list)
end


-- removes accounts from blacklist
-- @type    call
-- @param   account_list    (list of address)
-- @event   removeFromBlacklist(account_list)

function removeFromBlacklist(account_list)
  assert(system.getSender() == system.getCreator(), "only owner can blacklist anothers")

  for i = 1, #account_list do
    _typecheck(account_list[i], 'address')
    _blacklist[account_list[i]] = nil
  end

  contract.event("removeFromBlacklist", account_list)
end


-- Retrun true when an account is on blacklist
-- @type    query
-- @param   account   (address)

function isOnBlacklist(account)
  _typecheck(account, 'address')

  return _blacklist[account] == true
end


-- Transfer tokens from an account to another by filtering with Blacklist
-- @type    call
-- @param   to     (address) recipient's address
-- @param   amount (ubig)    amount of tokens to send
-- @param   ...     addtional data, MUST be sent unaltered in call to 'tokensReceived' on 'to'
-- @event   transfer(Tx sender, to, amount)

-- function transferByF(to, amount, ...)
--  assert(not isOnBlacklist(system.getSender()),'receiver account is on blacklist')
--  assert(not isOnBlacklist(to),'receiver account is on blacklist')

--  transfer(to, amount, ...)
-- end


abi.register(addToBlacklist,removeFromBlacklist,transferByF)
abi.register_view(isOnBlacklist)
