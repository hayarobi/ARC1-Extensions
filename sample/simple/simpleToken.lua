import "ARC1-Core"
import "ARC1-Pausable"

function constructor()
 _init("simpleToken", "SYM", 18)
 _mint(system.getContractID(), bignum.number(500000000) * bignum.number("1000000000000000000"))
end
