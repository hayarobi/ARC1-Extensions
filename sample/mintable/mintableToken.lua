import "ARC1-Core"
import "ARC1-MintBurnable"

function constructor()
  _init("mintableToken", "MINT", 18)
  _setCAP(bignum.number(500000000) * bignum.number("1000000000000000000"))  -- default : boundless minting
end
