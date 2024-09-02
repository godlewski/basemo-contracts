// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract YouOwe {
    uint256 private debtCounter;

    struct Debt {
        uint256 id; // the unique identifier for the debt
        address creditor; // the person who is owed money
        address debtor; // the person who owes money
        uint256 amount; // the amount owed in wei
    }

    mapping(uint256 => Debt) public debts;
    mapping(address => uint256[]) private debtsOwedTo;
    mapping(address => uint256[]) private debtsOwedBy;

    event DebtCreated(
        uint256 id,
        address indexed creditor,
        address indexed debtor,
        uint256 amount
    );
    event DebtSettled(
        uint256 id,
        address indexed creditor,
        address indexed debtor,
        uint256 amount
    );
    event DebtCancelled(
        uint256 id,
        address indexed creditor,
        address indexed debtor,
        uint256 amount
    );

    // Custom errors
    error DebtDoesNotExist();
    error OnlyDebtorCanSettle();
    error OnlyCreditorCanCancel();
    error IncorrectAmountSent();
    error InsufficientBalance(uint256 required, uint256 available);

    // Modifiers
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
        if (msg.sender.balance < debts[_debtId].amount) {
            revert InsufficientBalance(
                debts[_debtId].amount,
                msg.sender.balance
            );
        }
        _;
    }

    function createDebt(
        address _creditor,
        address _debtor,
        uint256 _amount
    ) external {
        debtCounter++;
        debts[debtCounter] = Debt(debtCounter, _creditor, _debtor, _amount);

        emit DebtCreated(debtCounter, _creditor, _debtor, _amount);
    }

    function settleDebt(
        uint256 _debtId
    )
        external
        payable
        debtExists(_debtId)
        onlyDebtor(_debtId)
        sufficientBalance(_debtId)
    {
        Debt storage debt = debts[_debtId];

        // Check if the sent amount matches the debt amount
        if (msg.value != debt.amount) {
            revert IncorrectAmountSent();
        }

        // Transfer the amount to the creditor
        payable(debt.creditor).transfer(msg.value);

        // Remove the debt ID from the debtsOwedTo and debtsOwedBy mappings
        removeDebtFromArray(debtsOwedTo[debt.creditor], _debtId);
        removeDebtFromArray(debtsOwedBy[debt.debtor], _debtId);

        // Delete the debt from the debts mapping
        delete debts[_debtId];

        // Emit the DebtSettled event
        emit DebtSettled(_debtId, debt.creditor, debt.debtor, debt.amount);
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
        emit DebtCancelled(_debtId, debt.creditor, debt.debtor, debt.amount);
    }

    function removeDebtFromArray(
        uint256[] storage array,
        uint256 debtId
    ) internal {
        // This is apparently more gas efficient
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == debtId) {
                // Replace the found element with the last element
                array[i] = array[array.length - 1];
                // Remove the last element
                array.pop();
                break;
            }
        }
    }

    function getDebtsOwedTo(
        address _address
    ) external view returns (Debt[] memory) {
        uint256[] storage debtIds = debtsOwedTo[_address];
        Debt[] memory debtsOwedToMemory = new Debt[](debtIds.length);

        for (uint256 i = 0; i < debtIds.length; i++) {
            debtsOwedToMemory[i] = debts[debtIds[i]];
        }

        return debtsOwedToMemory;
    }

    function getDebtsOwedBy(
        address _address
    ) external view returns (Debt[] memory) {
        uint256[] storage debtIds = debtsOwedBy[_address];
        Debt[] memory debtsOwedByMemory = new Debt[](debtIds.length);

        for (uint256 i = 0; i < debtIds.length; i++) {
            debtsOwedByMemory[i] = debts[debtIds[i]];
        }

        return debtsOwedByMemory;
    }
}
