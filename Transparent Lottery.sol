// Transparent Lottery: Randomly select a ticket winner (using safe, simple pseudo-random block numbers).


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleLottery {
    
    address public immutable owner;
    uint256 public immutable ticketPrice;
    
    // Dynamic array tracking ticket holders (1 entry = 1 ticket)
    address[] private _players;
    
    // Lottery tracking status
    uint256 public lotteryId;
    address public lastWinner;
    uint256 public lastJackpot;

    // Events
    event TicketPurchased(address indexed player, uint256 indexed lotteryId);
    event LotteryDrawn(uint256 indexed lotteryId, address indexed winner, uint256 jackpotAmount);

    // Custom Errors
    error OnlyOwnerAllowed();
    error NoPlayersInLottery();
    error TransferFailed();

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwnerAllowed();
        _;
    }

    constructor(uint256 ticketPriceInWei) {
        owner = msg.sender;
        ticketPrice = ticketPriceInWei;
    }

    /**
     * @dev Purchase a lottery ticket by sending the exact ticket price in ETH.
     */
    function buyTicket() external payable {
        require(msg.value == ticketPrice, "Incorrect ETH amount sent");
        
        _players.push(msg.sender);
        emit TicketPurchased(msg.sender, lotteryId);
    }

    /**
     * @dev Select a winner using pseudo-random block data and distribute the jackpot.
     */
    function drawWinner() external onlyOwner {
        uint256 totalPlayers = _players.length;
        if (totalPlayers == 0) revert NoPlayersInLottery();

        // 1. Generate the pseudo-random index number
        uint256 winnerIndex = _generateRandomNumber() % totalPlayers;
        address winner = _players[winnerIndex];

        uint256 jackpot = address(this).balance;
        
        // 2. Update historical state tracking variables
        lastWinner = winner;
        lastJackpot = jackpot;
        
        emit LotteryDrawn(lotteryId, winner, jackpot);

        // 3. Reset the lottery pool state for the next round
        delete _players; 
        lotteryId++;

        // 4. Send the jackpot winnings to the chosen address
        (bool success, ) = payable(winner).call{value: jackpot}("");
        if (!success) revert TransferFailed();
    }

    /**
     * @dev Internal source of pseudo-randomness using the block details.
     */
    function _generateRandomNumber() internal view returns (uint256) {
        // block.prevrandao replaces block.difficulty in post-Merge Proof of Stake networks
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.prevrandao,
                    block.timestamp,
                    _players.length
                )
            )
        );
    }

    /**
     * @dev Helper view function to inspect active ticket entries.
     */
    function getPlayers() external view returns (address[] memory) {
        return _players;
    }
}