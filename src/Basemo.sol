// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Basemo is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    IERC20Upgradeable public usdcToken;
    uint256 private debtCounter;

    struct Debt {
        uint256 id;
        address creditor;
        address debtor;
        uint256 amount;
        string description;
    }

    mapping(uint256 => Debt) public debts;
    mapping(address => uint256[]) private debtsOwedTo;
    mapping(address => uint256[]) private debtsOwedBy;

    event DebtCreated(
        uint256 id,
        address indexed creditor,
        address indexed debtor,
        uint256 amount,
        string debtDescription
    );
    event DebtSettled(
        uint256 id,
        address indexed creditor,
        address indexed debtor,
        uint256 amount,
        string debtDescription
    );
    event DebtCancelled(
        uint256 id,
        address indexed creditor,
        address indexed debtor,
        uint256 amount,
        string debtDescription
    );

    // Custom errors
    error DebtDoesNotExist();
    error OnlyDebtorCanSettle();
    error OnlyCreditorCanCancel();
    error IncorrectAmountSent();
    error InsufficientBalance(uint256 required, uint256 available);
    error TransferFailed();
    error YouCannotOweYourself();
    error InsufficientUSDC(uint256 required, uint256 available);

    // Keep all the same modifiers
    modifier debtExists(uint256 _debtId) {
        if (debts[_debtId].id == 0) {
            revert DebtDoesNotExist();
        }
        _;
    }

    modifier onlyDebtor(uint256 _debtId) {
        if (debts[_debtId].debtor != msg.sender) {
            revert OnlyDebtorCanSettle();
        }
        _;
    }

    modifier onlyCreditor(uint256 _debtId) {
        if (debts[_debtId].creditor != msg.sender) {
            revert OnlyCreditorCanCancel();
        }
        _;
    }

    modifier sufficientBalance(uint256 _debtId) {
        uint256 debtorBalance = usdcToken.balanceOf(msg.sender);
        if (debtorBalance < debts[_debtId].amount) {
            revert InsufficientUSDC(debts[_debtId].amount, debtorBalance);
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _usdcTokenAddress) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        usdcToken = IERC20Upgradeable(_usdcTokenAddress);
    }

    // Required by UUPSUpgradeable
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // Keep all the original functions with their modifiers
    function createDebt(
        address _debtor,
        uint256 _amount,
        string memory _description
    ) external {
        if (_debtor == msg.sender) {
            revert YouCannotOweYourself();
        }

        debtCounter++;
        debts[debtCounter] = Debt(
            debtCounter,
            msg.sender,
            _debtor,
            _amount,
            _description
        );
        debtsOwedTo[msg.sender].push(debtCounter);
        debtsOwedBy[_debtor].push(debtCounter);

        emit DebtCreated(
            debtCounter,
            msg.sender,
            _debtor,
            _amount,
            _description
        );
    }

    function settleDebt(
        uint256 _debtId
    )
        external
        debtExists(_debtId)
        onlyDebtor(_debtId)
        sufficientBalance(_debtId)
    {
        Debt storage debt = debts[_debtId];

        // Check if the debtor has enough USDC tokens
        uint256 debtorBalance = usdcToken.balanceOf(msg.sender);
        if (debtorBalance < debt.amount) {
            revert InsufficientUSDC(debt.amount, debtorBalance);
        }

        // Transfer USDC tokens from the debtor to the creditor
        bool success = usdcToken.transferFrom(
            msg.sender,
            debt.creditor,
            debt.amount
        );

        if (!success) {
            revert TransferFailed();
        }

        // Remove the debt ID from the debtsOwedTo and debtsOwedBy mappings
        removeDebtFromArray(debtsOwedTo[debt.creditor], _debtId);
        removeDebtFromArray(debtsOwedBy[debt.debtor], _debtId);

        // Delete the debt from the debts mapping
        delete debts[_debtId];

        // Emit the DebtSettled event
        emit DebtSettled(
            _debtId,
            debt.creditor,
            debt.debtor,
            debt.amount,
            debt.description
        );
    }

    function cancelDebt(
        uint256 _debtId
    ) external debtExists(_debtId) onlyCreditor(_debtId) {
        Debt storage debt = debts[_debtId];

        // Remove the debt ID from the debtsOwedTo and debtsOwedBy mappings
        removeDebtFromArray(debtsOwedTo[debt.creditor], _debtId);
        removeDebtFromArray(debtsOwedBy[debt.debtor], _debtId);

        // Delete the debt from the debts mapping
        delete debts[_debtId];

        // Emit the DebtCancelled event
        emit DebtCancelled(
            _debtId,
            debt.creditor,
            debt.debtor,
            debt.amount,
            debt.description
        );
    }

    function removeDebtFromArray(
        uint256[] storage array,
        uint256 debtId
    ) internal {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == debtId) {
                array[i] = array[array.length - 1];
                array.pop();
                break;
            }
        }
    }

    function getDebtsOwedTo(
        address _address
    ) external view returns (Debt[] memory) {
        uint256[] storage debtIds = debtsOwedTo[_address];
        Debt[] memory result = new Debt[](debtIds.length);
        for (uint256 i = 0; i < debtIds.length; i++) {
            result[i] = debts[debtIds[i]];
        }
        return result;
    }

    function getDebtsOwedBy(
        address _address
    ) external view returns (Debt[] memory) {
        uint256[] storage debtIds = debtsOwedBy[_address];
        Debt[] memory result = new Debt[](debtIds.length);
        for (uint256 i = 0; i < debtIds.length; i++) {
            result[i] = debts[debtIds[i]];
        }
        return result;
    }
}
