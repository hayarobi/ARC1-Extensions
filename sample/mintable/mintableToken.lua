import "ARC1-Core"
import "ARC1-Mintable"

function constructor()
  _init("mintableToken", "MINT", 18)
  _setMaxSupply(bignum.number(500000000) * bignum.number("1000000000000000000"))  -- default : boundless minting
end
