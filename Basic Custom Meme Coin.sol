// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MemeCoin is IERC20 {
    // Token Metadata
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    // Internal State Data
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Custom errors for gas efficiency
    error InvalidAddress();
    error InsufficientBalance();
    error InsufficientAllowance();

    /**
     * @dev Mint the initial custom supply entirely to the deployer.
     * @param _name The name of your meme coin (e.g., "MoonCat")
     * @param _symbol The ticker symbol (e.g., "MCAT")
     * @param initialSupplyInTokens The total supply you want (e.g., 1000000)
     */
    constructor(string memory _name, string memory _symbol, uint256 initialSupplyInTokens) {
        name = _name;
        symbol = _symbol;
        
        // 1 token = 1 * 10^18 internal units due to 18 decimal places
        uint256 totalRawSupply = initialSupplyInTokens * (10 ** uint256(decimals));
        
        _totalSupply = totalRawSupply;
        _balances[msg.sender] = totalRawSupply;

        // ERC-20 standard requires emitting a Transfer event from the zero address for minting
        emit Transfer(address(0), msg.sender, totalRawSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Move tokens from the caller's account to another account.
     */
    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Grant permission to `spender` to spend a specific amount of your tokens via transferFrom.
     */
    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Move tokens from a sender to a recipient using an allowance mechanism.
     */
    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        
        if (currentAllowance != type(uint256).max) { // standard check to skip unlimited allowance
            if (currentAllowance < value) revert InsufficientAllowance();
            unchecked {
                _approve(from, msg.sender, currentAllowance - value);
            }
        }

        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Internal helper containing the core transfer logic.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0) || to == address(0)) revert InvalidAddress();
        if (_balances[from] < value) revert InsufficientBalance();

        unchecked {
            _balances[from] -= value;
            _balances[to] += value;
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal helper containing the core approval logic.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        if (owner == address(0) || spender == address(0)) revert InvalidAddress();

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}



// Basic Custom Meme Coin: Build a custom supply ERC-20 standard compliant token from scratch.