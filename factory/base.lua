arc1_core = [[
%core%
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
state.var {
  _creator = state.value()
}

function constructor(name, symbol, decimals, initial_supply, max_supply, owner)
  _init(name, symbol, decimals)
  _creator:set(owner)
  initial_supply = bignum.number(initial_supply)
  if initial_supply > bignum.number(0) then
    local decimal_str = "1" .. string.rep("0", decimals)
    _mint(owner, initial_supply * bignum.number(decimal_str))
  end
  if max_supply then
    max_supply = bignum.number(max_supply)
    assert(max_supply > bignum.number(0), "invalid max supply")
    _setMaxSupply(max_supply)
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

  local contract_code = arc1_core .. arc1_constructor

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

  local address = contract.deploy(contract_code, name, symbol, decimals, initial_supply, options["max_supply"], owner)

  contract.event("new_token", address)

  return address
end

abi.register(new_token)
