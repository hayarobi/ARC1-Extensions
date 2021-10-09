import "ARC1-Core"
import "ARC1-MintBurnable"

function constructor()
  _init("mintableToken", "MINT", 18)
  _cap:set(bignum.number(500000000))  -- default : boundless minting
end
