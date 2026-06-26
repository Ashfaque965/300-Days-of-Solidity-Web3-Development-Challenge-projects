// Chainlink Price Aggregator Feed: Read external live cryptocurrency conversions using decentralized oracles.


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Explicit definition of the Chainlink V3 Aggregator Interface.
 * This can also be imported directly via: 
 * import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
 */
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract PriceConsumer {
    
    AggregatorV3Interface internal immutable dataFeed;

    // Custom errors for defensive engineering
    error StalePriceData();
    error NegativePriceEncountered();

    /**
     * @dev Network: Ethereum Sepolia Testnet
     * Aggregator: ETH / USD
     * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     */
    constructor() {
        dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    /**
     * @dev Returns the latest live price conversion metric.
     * Includes vital sanity checks to guarantee data freshness and safety.
     */
    function getLatestPrice() external view returns (int256) {
        (
            uint80 roundId,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = dataFeed.latestRoundData();

        // 1. Sanity Check: Ensure the price index is positive
        if (price <= 0) revert NegativePriceEncountered();

        // 2. Freshness Check: Mitigate stale data if oracle node networks go offline
        // 3600 seconds = 1 hour heartbeat parameter threshold
        if (block.timestamp - updatedAt > 3600) revert StalePriceData();

        // 3. Round Check: Verify completion completeness
        if (answeredInRound < roundId) revert StalePriceData();

        return price;
    }

    /**
     * @dev Helper to view the decimal scaling factor configured for this specific feed.
     * ETH/USD typically returns 8 decimals.
     */
    function getPriceDecimals() external view returns (uint8) {
        return dataFeed.decimals();
    }
}