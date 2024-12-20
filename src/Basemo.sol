// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

contract Basemo is
    Initializable,
    ERC1155Upgradeable,
    EIP712Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    IERC20 public usdcToken;
    uint256 private debtCounter;

    struct Debt {
        uint256 id;
        address creditor;
        address debtor;
        uint256 amount;
        string description;
        uint256[50] __gap; // Adding a large gap for now, this will allow us to add more fields in upgraded versions of the contract
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

    function initialize(
        address _usdcTokenAddress,
        string memory _uri
    ) public initializer {
        __ERC1155_init(_uri);
        __EIP712_init("Basemo", "1");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        usdcToken = IERC20(_usdcTokenAddress);
    }

    // Required by UUPSUpgradeable
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

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

        _mint(_debtor, debtCounter, 1, "");

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

        uint256 debtorBalance = usdcToken.balanceOf(msg.sender);
        if (debtorBalance < debt.amount) {
            revert InsufficientUSDC(debt.amount, debtorBalance);
        }

        bool success = usdcToken.transferFrom(
            msg.sender,
            debt.creditor,
            debt.amount
        );

        if (!success) {
            revert TransferFailed();
        }

        _burn(debt.debtor, _debtId, 1);

        removeDebtFromArray(debtsOwedTo[debt.creditor], _debtId);
        removeDebtFromArray(debtsOwedBy[debt.debtor], _debtId);

        delete debts[_debtId];

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

        _burn(debt.debtor, _debtId, 1);

        removeDebtFromArray(debtsOwedTo[debt.creditor], _debtId);
        removeDebtFromArray(debtsOwedBy[debt.debtor], _debtId);

        delete debts[_debtId];

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

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // Only allow minting and burning, no transfers
        if (from != address(0) && to != address(0)) {
            revert("Soulbound: tokens are non-transferable");
        }
    }
}
