// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract SwapContract is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    enum SwapStatus { Pending, Cancelled, Accepted }

    struct SwapRequest {
        address requester;
        address recipient;
        uint256 amount;
        uint256 recipientAmount;
        SwapStatus status;
    }

    event SwapRequestCreated(uint256 indexed requestId, address indexed requester, address indexed recipient, uint256 amount);
    event SwapRequestStatusChanged(uint256 indexed requestId, SwapStatus status);

    mapping(uint256 =>  mapping(address => SwapRequest)) public swapRequests;
    mapping(address => uint256) public currentSwapRequestId;


    address public treasury;
    uint256 public systemFeePercentage;
    uint256 public nextRequestId;

    function initialize(address _treasury, uint256 _systemFeePercentage) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        treasury = _treasury;
        systemFeePercentage = _systemFeePercentage;
    }

    function createSwapRequest(address _recipient, uint256 _amount, uint256 _recipientAmount) external nonReentrant {
        uint currentRequestID = currentSwapRequestId[msg.sender];

        SwapRequest storage swapRequest = swapRequests[currentRequestID][msg.sender];

        require(swapRequest.status == SwapStatus.Pending, "Swap Request still pending");
        require(swapRequest.status == SwapStatus.Cancelled, "Swap Request is cancelled");

        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Invalid amount");

        currentSwapRequestId[msg.sender] = nextRequestId;
        currentSwapRequestId[_recipient] = nextRequestId;

        swapRequests[nextRequestId][msg.sender] = SwapRequest(msg.sender, _recipient, _amount, _recipientAmount, SwapStatus.Pending);
        swapRequests[nextRequestId][_recipient] = SwapRequest(msg.sender, _recipient, _amount, _recipientAmount, SwapStatus.Pending);

        nextRequestId++;

        emit SwapRequestCreated(currentRequestID, msg.sender, _recipient, _amount);
    }

    function changeSwapRequest(SwapStatus status) external nonReentrant {
        uint currentRequestID = currentSwapRequestId[msg.sender];
        SwapRequest storage swapRequest = swapRequests[currentRequestID][msg.sender];

        if(msg.sender != swapRequest.recipient) {
            revert('You have no permission to do this');
        }

        if(status == SwapStatus.Cancelled) {
            swapRequest.status = SwapStatus.Cancelled;
            payable(swapRequest.requester).transfer(swapRequest.amount);  
            return;
        }

        if(status == SwapStatus.Pending) {
            revert("Status must be 'Cancelled' or 'Accepted'");
        }

        require(currentRequestID != 0, "Invalid request ID");
        require(swapRequest.recipient == msg.sender, "Only recipient can approve the swap request");
        require(swapRequest.status == SwapStatus.Pending, "Swap request already processed");

        uint256 amountToTransfer = swapRequest.amount * 95 / 100;
        uint256 systemFee = swapRequest.amount - amountToTransfer;
        payable(swapRequest.recipient).transfer(amountToTransfer);
        payable(treasury).transfer(systemFee);

        uint256 recipentAmountToTransfer = swapRequest.recipientAmount * 95 / 100;
        uint256 recipentSystemFee = swapRequest.recipientAmount - amountToTransfer;
        payable(swapRequest.requester).transfer(recipentAmountToTransfer);
        payable(treasury).transfer(recipentSystemFee);

        swapRequest.status = SwapStatus.Accepted;

        emit SwapRequestStatusChanged(currentRequestID, SwapStatus.Accepted);
    }
}
