// Capped Token Supply: An ERC-20 token that stops minting permanently once a hard ceiling is hit.


// 


    // SPDX-License-Identifier: MIT
    
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CappedToken is ERC20, Ownable {
    
    // The permanent maximum cap for the token supply
    uint256 private immutable _cap;

    // Custom errors for gas efficiency
    error ERC20ExceededCap(uint256 increasedSupply, uint256 cap);
    error CapMustBeGreaterThanZero();

    /**
     * @dev Sets the token name, symbol, and the immutable hard cap.
     * @param name_ The name of the token.
     * @param symbol_ The ticker symbol.
     * @param cap_ The maximum number of tokens that can ever exist (in raw units, factoring in decimals).
     */
    constructor(
        string memory name_, 
        string memory symbol_, 
        uint256 cap_,
        address initialOwner
    ) 
        ERC20(name_, symbol_) 
        Ownable(initialOwner) 
    {
        if (cap_ == 0) {
            revert CapMustBeGreaterThanZero();
        }
        _cap = cap_;
    }

    /**
     * @dev Returns the maximum cap on the token's total supply.
     */
    function cap() external view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Mints new tokens to a specified address. Only the owner can mint.
     * Enforces the hard ceiling limit before executing the core mint logic.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        // Enforce the hard ceiling constraint
        if (totalSupply() + amount > _cap) {
            revert ERC20ExceededCap(totalSupply() + amount, _cap);
        }
        
        _mint(to, amount);
    }
}




// 🧠 Architectural Insights1. Why immutable matters for TokenomicsThe _cap variable is declared as immutable. This means its value is compiled directly into the contract's bytecode at deployment time.Trust & Auditing: Investors and users can verify the contract on etherscan and visually confirm that there are no functions capable of rewriting or increasing the _cap. It guarantees a mathematically fixed scarcity.Gas Efficiency: Reading an immutable variable bypasses standard storage reads (SLOAD), saving roughly 2,100 gas every time mint() or cap() is evaluated.2. Factoring in DecimalsWhen deploying this contract, remember that ERC-20 tokens calculate amounts using raw integers to mimic decimals. If your token uses the standard 18 decimals, and you want a hard cap of exactly 1,000,000 tokens, your constructor argument for cap_ must look like this:$$\text{cap\_} = 1,000,000 \times 10^{18} = 1000000000000000000000000$$3. OpenZeppelin NoteIf you are already using OpenZeppelin's standard extension suite extensively in your workflow, they provide a pre-built contract called ERC20Capped.sol that handles this exact setup internally via an internal hook override (_update). The custom pattern shown above yields identical results with explicit visibility over the constraint logic.