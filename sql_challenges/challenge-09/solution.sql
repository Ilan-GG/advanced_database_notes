-- Lesson 04: SETUP

DROP TABLE accounts PURGE;

CREATE TABLE accounts (
    account_id   NUMBER PRIMARY KEY,
    owner_name   VARCHAR2(50) NOT NULL,
    balance      NUMBER(10,2) NOT NULL CHECK (balance >= 0)
);

INSERT INTO accounts VALUES (1, 'Alice',  1000.00);
INSERT INTO accounts VALUES (2, 'Bob',     500.00);
INSERT INTO accounts VALUES (3, 'Charlie', 250.00);
COMMIT;

-- ============================================================
-- EXERCISE 1: Manual transaction (warm-up)
-- ============================================================
-- Transfer $50 from Charlie (3) to Alice (1) using BEGIN / COMMIT manually.
-- Before: verify balances. After COMMIT: verify again.

-- Your SQL here:

BEGIN
    UPDATE accounts
    SET balance = balance - 50
    WHERE account_id = 3;

    UPDATE accounts
    SET balance = balance + 50
    WHERE account_id = 1;

COMMIT;
END;
/

-- Verify after
SELECT * FROM accounts ORDER BY account_id;
 

-- ============================================================
-- EXERCISE 2: Catch yourself with ROLLBACK
-- ============================================================
-- Start a transfer of $10,000 from Bob (2) to Charlie (3).
-- Before committing, check the balances. Does Bob have enough?
-- Use ROLLBACK to undo. Verify balances restored.

-- Your SQL here:

BEGIN
    UPDATE accounts
    SET balance = balance - 10000
    WHERE account_id = 2;

    UPDATE accounts
    SET balance = balance + 10000
    WHERE account_id = 3;
END;
/

ROLLBACK;

-- ============================================================
-- EXERCISE 3: SAVEPOINT checkpoint
-- ============================================================
-- You need to:
-- 1. Add $25 to Alice's balance
-- 2. Set a savepoint
-- 3. Deduct $25 from Charlie's balance (wrong account — you meant Bob)
-- 4. Rollback to savepoint
-- 5. Deduct $25 from Bob's balance instead
-- 6. Commit

-- Your SQL here:
BEGIN

    -- Step 1
    UPDATE accounts
    SET balance = balance + 25
    WHERE account_id = 1;

    -- Step 2
    SAVEPOINT after_alice_credit;

    -- Step 3 (mistake)
    UPDATE accounts
    SET balance = balance - 25
    WHERE account_id = 3;

    -- Step 4
    ROLLBACK TO after_alice_credit;

    -- Step 5 (correct)
    UPDATE accounts
    SET balance = balance - 25
    WHERE account_id = 2;

    -- Step 6
    COMMIT;

END;
/
 

-- ============================================================
-- EXERCISE 4: Write your own stored procedure
-- ============================================================
-- Create a procedure called deposit_funds(p_account_id, p_amount)
-- It should:
-- 1. Validate that p_amount > 0 (raise error if not)
-- 2. Add p_amount to the account balance
-- 3. COMMIT on success
-- 4. ROLLBACK + re-raise on any error
-- Test it with: EXEC deposit_funds(3, 75);

-- Your SQL here:
CREATE OR REPLACE PROCEDURE deposit_funds(
    p_account_id IN NUMBER,
    p_amount     IN NUMBER
)
IS
BEGIN

    -- Validation
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Deposit amount must be greater than zero'
        );
    END IF;

    -- Deposit
    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_account_id;

    -- Validate account exists
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Account not found'
        );
    END IF;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- ============================================================
-- EXERCISE 5: Discussion
-- ============================================================
-- Answer these in words (no SQL needed):

-- Q1: You're building a patient appointment booking system.
-- A booking requires:
--   a) Reserve the time slot
--   b) Create the appointment record
--   c) Send a confirmation notification
-- Which of these should be inside the transaction? Which should be outside? Why?

-- Send Confirmation Notification, this would be after a commit. because the
-- appointment or the time slot are slow options

-- Q2: Your stored procedure calls COMMIT at the end.
-- A developer calls your procedure from inside their own larger transaction.
-- What problem does this create?

-- The transaction is broken into pieces, so the caller's expectation of controlling
-- the commit/rollback.

-- Q3: You have a function called calculate_copay() and a procedure called post_payment().
-- A colleague wants to use calculate_copay() inside a SELECT statement.
-- Can they? Can they do the same with post_payment()? Why or why not?

-- Yes, they can be used in SELECT.
-- No , it doesnt return a value while exec computes and returns.

