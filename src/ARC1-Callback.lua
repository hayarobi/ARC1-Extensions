
-- The ARC1 smart contract calls this function on the recipient after a 'transfer'
-- @type    call
-- @param   operator    (address) a address which called token 'transfer' function
-- @param   from        (address) sender's address
-- @param   amount      (ubig)    amount of tokens received
-- @param   ...         additional data, by-passed from 'transfer' arguments

function tokensReceived(operator, from, amount, ...)
  -- add & implement this function to a token handler contract
end
