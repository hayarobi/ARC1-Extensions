

-- The ARC1 smart contract calls this function on the recipient after a 'transfer'
-- @type    call
-- @param   operator    (address) a address which called token 'transfer' function
-- @param   from        (address) sender's address
-- @param   value       (ubig)    amount of tokens to send
-- @param   ...         additional data, by-passed from 'transfer' arguments

function tokensReceived(operator, from, value, ...)
  -- add & implement this function to a token handler contract
end
