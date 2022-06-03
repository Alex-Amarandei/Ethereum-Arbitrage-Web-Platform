// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

/// @title The Platform's Funds Manager Contract
/// @author Amarandei Matei Alexandru (@Alex-Amarandei)
/**
 * @notice The contract is responsible with managing the in/outflow of funds
 * Its functions are called in several scripts in order to:
 * - pay the initial fee of placing an order
 * - refund users if they cancel their orders
 * - simulate using the users' "accounts" for paying the gas fees
 */
/// @dev Provides a low-level alternative to meta-transactions with relayers
contract FundsManager {
    address payable private owner;
    uint256 public fee;
    mapping(address => uint256) public userGasAmounts;

    /// @param _fee The fee to be paid when an order is placed by a user
    /// @dev The owner address for the later funding of the platform's wallet
    constructor(uint256 _fee) {
        owner = payable(msg.sender);
        fee = _fee;
    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function fundWithGas() public payable {
        require(msg.value == fee, "You need to send exactly the fee in ETH!");

        userGasAmounts[msg.sender] += msg.value;
    }

    /// @param _all Specifies if a user wants to cancel all their existing orders
    /// @notice Refunds the fees accumulated partially or fully
    function refundGas(bool _all) public {
        require(
            userGasAmounts[msg.sender] > 0,
            "You do not have any remaining funds to withdraw"
        );

        address payable user = payable(msg.sender);

        if (_all || userGasAmounts[msg.sender] < fee) {
            user.transfer(userGasAmounts[msg.sender]);
            userGasAmounts[msg.sender] = 0;
        } else {
            user.transfer(fee);
            userGasAmounts[msg.sender] -= fee;
        }
    }

    /// @param _userAddress The user "account" which is to be debited
    /// @notice The fee is debited in order to simulate using user funds for gas
    function useGas(address _userAddress) external ownerOnly {
        require(
            userGasAmounts[_userAddress] > 0,
            "User does not have any funds left to pay the gas!"
        );

        if (userGasAmounts[_userAddress] >= fee) {
            owner.transfer(fee);
            userGasAmounts[_userAddress] -= fee;
        } else {
            owner.transfer(userGasAmounts[_userAddress]);
            userGasAmounts[_userAddress] = 0;
        }
    }

    /// @param _newFee The new fee of placing an order
    /// @notice Updates the fee charged by the platform
    function updateFee(uint256 _newFee) external ownerOnly {
        fee = _newFee;
    }
}
