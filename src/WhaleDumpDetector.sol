// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Trap} from "drosera-contracts/Trap.sol";

/**
 * @title WhaleDumpDetector
 * @notice Monitors whale addresses for large DRO token dumps on Hoodi testnet
 * @dev Triggers when any whale sells more than THRESHOLD_PCT of their balance
 */
contract WhaleDumpDetector is Trap {
    // DRO Token on Hoodi testnet - HARDCODED
    address public constant TOKEN = 0x499b095Ed02f76E56444c242EC43A05F9c2A3ac8;
    
    // TODO: Replace these with real top DRO holder addresses from block explorer
    address public constant WHALE_1 = 0x780521b58Ff8fFB7df09195E79810580279a4d9d;
    address public constant WHALE_2 = 0x4d1c87EC4Fc08391E8b7A09BC988e87cA54bec0b;
    address public constant WHALE_3 = 0x431C17416a4e497ff01C2cFE4c1dc9e5691Ad17c;
    
    // Threshold: 20% = 0.2e18
    uint256 public constant THRESHOLD_PCT = 200000000000000000;
    
    struct CollectOutput {
        address whale1;
        address whale2;
        address whale3;
        uint256 balance1;
        uint256 balance2;
        uint256 balance3;
        uint256 blockNumber;
    }
    
    /**
     * @notice Collect current whale balances every block
     * @return Encoded CollectOutput struct
     */
    function collect() external view override returns (bytes memory) {
        return abi.encode(
            CollectOutput({
                whale1: WHALE_1,
                whale2: WHALE_2,
                whale3: WHALE_3,
                balance1: IERC20(TOKEN).balanceOf(WHALE_1),
                balance2: IERC20(TOKEN).balanceOf(WHALE_2),
                balance3: IERC20(TOKEN).balanceOf(WHALE_3),
                blockNumber: block.number
            })
        );
    }
    
    /**
     * @notice Check if a whale dump occurred
     * @param data Array of collected data from previous blocks
     * @return shouldTrigger Whether the trap should trigger
     * @return responseData Encoded response with dump details
     */
    function shouldRespond(bytes[] calldata data) 
        external 
        pure
        override 
        returns (bool shouldTrigger, bytes memory responseData) 
    {
        // Need at least 2 data points to detect a dump
        if (data.length < 2) {
            return (false, "");
        }
        
        // Decode current and previous block data
        CollectOutput memory current = abi.decode(data[0], (CollectOutput));
        CollectOutput memory previous = abi.decode(data[1], (CollectOutput));
        
        // Check each whale for dumps
        shouldTrigger = _checkWhaleDump(WHALE_1, previous.balance1, current.balance1);
        if (shouldTrigger) {
            responseData = _createResponse(WHALE_1, previous.balance1, current.balance1);
            return (true, responseData);
        }
        
        shouldTrigger = _checkWhaleDump(WHALE_2, previous.balance2, current.balance2);
        if (shouldTrigger) {
            responseData = _createResponse(WHALE_2, previous.balance2, current.balance2);
            return (true, responseData);
        }
        
        shouldTrigger = _checkWhaleDump(WHALE_3, previous.balance3, current.balance3);
        if (shouldTrigger) {
            responseData = _createResponse(WHALE_3, previous.balance3, current.balance3);
            return (true, responseData);
        }
        
        return (false, "");
    }
    
    /**
     * @notice Check if a whale's balance drop exceeds threshold
     */
    function _checkWhaleDump(
        address whale,
        uint256 oldBalance,
        uint256 newBalance
    ) internal pure returns (bool) {
        // Skip if no previous balance or balance increased
        if (oldBalance == 0 || newBalance >= oldBalance) {
            return false;
        }
        
        // Calculate amount dumped
        uint256 amountDumped = oldBalance - newBalance;
        
        // Calculate percentage dumped
        uint256 pct = (amountDumped * 1e18) / oldBalance;
        
        // Check if threshold exceeded
        return pct >= THRESHOLD_PCT;
    }
    
    /**
     * @notice Create response data for a whale dump
     */
    function _createResponse(
        address whale,
        uint256 oldBalance,
        uint256 newBalance
    ) internal pure returns (bytes memory) {
        uint256 amountDumped = oldBalance - newBalance;
        uint256 pct = (amountDumped * 1e18) / oldBalance;
        
        return abi.encode(
            TOKEN,
            whale,
            amountDumped,
            pct,
            oldBalance,
            newBalance
        );
    }
}
