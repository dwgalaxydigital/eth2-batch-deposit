// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// Import the required libraries for token manipulation, math, and access control
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Define the BatchDeposit contract, which inherits from Ownable
contract BatchDeposit is Ownable {

    using SafeMath for uint256;

    // Define the token interface for interacting with the ERC20 token (ETH)
    IERC20 public immutable token;

    // Define constants for the deposit amount and the batch size
    uint256 public constant DEPOSIT_AMOUNT = 32 ether;
    uint256 public constant BATCH_SIZE = 100;

    // Define events to be emitted when deposits are received and batches are deposited
    event DepositReceived(address indexed from, uint256 amount);
    event BatchDeposited(uint256 indexed batchId, uint256 amount);

    // Define private variables for counting deposits and tracking the current batch ID
    uint256 private _depositCount = 0;
    uint256 private _batchId = 0;

    // Constructor for the contract, initializing the token interface
    constructor(IERC20 _token) public {
        token = _token;
    }

    // The deposit function, allowing users to deposit the specified number of deposits
    function deposit(uint256 numDeposits) external {
        // Ensure the number of deposits is greater than 0
        require(numDeposits > 0, "BatchDeposit: numDeposits must be greater than 0");

        // Calculate the total deposit value
        uint256 depositValue = DEPOSIT_AMOUNT.mul(numDeposits);

        // Transfer the deposit value from the sender to the contract
        require(token.transferFrom(msg.sender, address(this), depositValue), "BatchDeposit: transferFrom failed");

        // Increment the deposit count and emit the DepositReceived event
        _depositCount = _depositCount.add(numDeposits);
        emit DepositReceived(msg.sender, depositValue);

        // If the deposit count reaches the batch size, transfer the batch value to the contract owner
        if (_depositCount >= BATCH_SIZE) {
            uint256 batchValue = DEPOSIT_AMOUNT.mul(BATCH_SIZE);
            require(token.transfer(owner(), batchValue), "BatchDeposit: transfer failed");

            // Update the deposit count, emit the BatchDeposited event, and increment the batch ID
            _depositCount = _depositCount.sub(BATCH_SIZE);
            emit BatchDeposited(_batchId, batchValue);
            _batchId = _batchId.add(1);
        }
    }

    // Allow the contract owner to withdraw excess funds (funds not part of a batch)
    function withdrawExcess() external onlyOwner {
        uint256 excess = token.balanceOf(address(this)).sub(_depositCount.mul(DEPOSIT_AMOUNT));
        require(token.transfer(owner(), excess), "BatchDeposit: transfer failed");
    }

    // View function to return the current deposit count
    function depositCount() external view returns (uint256) {
        return _depositCount;
    }

    // View function to return the current batch ID
    function batchId() external view returns (uint256) {
        return _batchId;
    }
}
