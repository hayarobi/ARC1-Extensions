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

function constructor(name, symbol, decimals, initial_supply, owner)
  local decimal_str = "1" .. string.rep("0", decimals)
  _init(name, symbol, decimals)
  _creator:set(owner)
  _mint(owner, bignum.number(initial_supply) * bignum.number(decimal_str))
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

  return contract.deploy(contract_code, name, symbol, decimals, initial_supply, owner)

end

abi.register(new_token)
