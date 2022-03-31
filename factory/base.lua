arc1_core = [[
%core%
]]

arc1_burnable = [[
%burnable%
]]

arc1_mintable = [[
%mintable%
]]

arc1_pausable = [[
%pausable%
]]

arc1_blacklist = [[
%blacklist%
]]

arc1_all_approval = [[
%all_approval%
]]

arc1_limited_approval = [[
%limited_approval%
]]

arc1_constructor = [[
function constructor(name, symbol, decimals, initial_supply, max_supply, owner)
  _init(name, symbol, decimals, owner)
  local decimal_str = "1" .. string.rep("0", decimals)
  if initial_supply > bignum.number(0) then
    _mint(owner, initial_supply * bignum.number(decimal_str))
  end
  if max_supply then
    _setMaxSupply(max_supply * bignum.number(decimal_str))
  end
end
]]

function new_token(name, symbol, decimals, initial_supply, options, owner)

  if options == nil or options == '' then
    options = {}
  end

  if owner == nil or owner == '' then
    owner = system.getSender()
  end

  local contract_code = arc1_core

  if options["burnable"] then
    contract_code = contract_code .. arc1_burnable
  end
  if options["mintable"] then
    contract_code = contract_code .. arc1_mintable
  end
  if options["pausable"] then
    contract_code = contract_code .. arc1_pausable
  end
  if options["blacklist"] then
    contract_code = contract_code .. arc1_blacklist
  end
  if options["all_approval"] then
    contract_code = contract_code .. arc1_all_approval
  end
  if options["limited_approval"] then
    contract_code = contract_code .. arc1_limited_approval
  end

  contract_code = contract_code .. arc1_constructor

  if not bignum.isbignum(initial_supply) then
    initial_supply = bignum.number(initial_supply)
  end
  assert(initial_supply >= bignum.number(0), "invalid initial supply")
  local max_supply = options["max_supply"]
  if max_supply then
    assert(options["mintable"], "max_supply is only available with the mintable extension")
    max_supply = bignum.number(max_supply)
    assert(max_supply >= initial_supply, "invalid max supply")
  end

  local address = contract.deploy(contract_code, name, symbol, decimals, initial_supply, max_supply, owner)

  contract.event("new_arc1_token", address)

  return address
end

abi.register(new_token)
