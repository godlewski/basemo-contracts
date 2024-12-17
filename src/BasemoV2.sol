// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Basemo.sol";

contract BasemoV2 is Basemo {
    // Events (inherited from Basemo)

    // Modify the existing Debt struct
    struct Debt {
        uint256 id;
        uint256 amount;
        address debtor;
        address creditor;
        bool paid;
        uint256 expirationDate; // New field added at the end
    }

    // Storage variables are inherited from Basemo
    // mapping(uint256 => Debt) private _debts;
    // uint256 private _nextDebtId;
    // address public usdcToken;

    function createDebt(
        address debtor,
        uint256 amount
    ) public override returns (uint256) {
        require(amount > 0, "Amount must be greater than 0");
        require(debtor != address(0), "Invalid debtor address");

        uint256 debtId = _nextDebtId++;

        _debts[debtId] = Debt({
            id: debtId, // Set the id
            amount: amount,
            debtor: debtor,
            creditor: msg.sender,
            paid: false,
            expirationDate: 0 // No expiration for backwards compatibility
        });

        emit DebtCreated(debtId, debtor, msg.sender, amount);
        return debtId;
    }

    function createDebtWithExpiration(
        address debtor,
        uint256 amount,
        uint256 durationInDays
    ) public returns (uint256) {
        require(amount > 0, "Amount must be greater than 0");
        require(debtor != address(0), "Invalid debtor address");
        require(durationInDays > 0, "Duration must be greater than 0");

        uint256 expirationDate = block.timestamp + (durationInDays * 1 days);
        uint256 debtId = _nextDebtId++;

        _debts[debtId] = Debt({
            id: debtId, // Set the id
            amount: amount,
            debtor: debtor,
            creditor: msg.sender,
            paid: false,
            expirationDate: expirationDate
        });

        emit DebtCreated(debtId, debtor, msg.sender, amount);
        return debtId;
    }

    // Rest of the functions remain the same...
}
