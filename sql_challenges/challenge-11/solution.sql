-- ============================================================
-- Lesson 03: SQLAlchemy ORM + Alembic Migrations
-- File: 01_setup_schema.sql
-- Purpose: V1 Schema — teams, users, tasks
--
-- Run this in your FreeSQL worksheet to create the base tables.
-- ============================================================

-- Drop tables if they exist (clean start)
DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS teams;

-- ============================================================
-- TEAMS
-- ============================================================
CREATE TABLE teams (
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR2(50)  NOT NULL UNIQUE,
    description VARCHAR2(200),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- USERS
-- ============================================================
CREATE TABLE users (
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username    VARCHAR2(50)  NOT NULL UNIQUE,
    email       VARCHAR2(100) NOT NULL,
    full_name   VARCHAR2(100),
    team_id     NUMBER,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_team
        FOREIGN KEY (team_id) REFERENCES teams(id)
);

-- ============================================================
-- TASKS
-- ============================================================
CREATE TABLE tasks (
    id           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title        VARCHAR2(200) NOT NULL,
    description  VARCHAR2(1000),
    status       VARCHAR2(20)  DEFAULT 'open',
    assigned_to  NUMBER,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP,
    CONSTRAINT fk_tasks_user
        FOREIGN KEY (assigned_to) REFERENCES users(id)
);

-- ============================================================
-- SEED DATA
-- ============================================================

-- Teams
INSERT INTO teams (name, description) VALUES ('Engineering', 'Software development team');
INSERT INTO teams (name, description) VALUES ('Product', 'Product management team');

-- Users
INSERT INTO users (username, email, full_name, team_id)
    VALUES ('alice_dev', 'alice@example.com', 'Alice Smith', 1);
INSERT INTO users (username, email, full_name, team_id)
    VALUES ('bob_dev', 'bob@example.com', 'Bob Jones', 1);
INSERT INTO users (username, email, full_name, team_id)
    VALUES ('carol_pm', 'carol@example.com', 'Carol White', 2);

-- Tasks
INSERT INTO tasks (title, description, status, assigned_to)
    VALUES ('Fix login bug', 'Users cannot log in with SSO', 'open', 1);
INSERT INTO tasks (title, description, status, assigned_to)
    VALUES ('Design new dashboard', 'Create mockups for analytics page', 'in_progress', 3);
INSERT INTO tasks (title, description, status, assigned_to)
    VALUES ('Update dependencies', 'Upgrade numpy and pandas', 'open', 2);

COMMIT;

-- ============================================================
-- VERIFY
-- ============================================================
SELECT 'Teams:' AS section, name FROM teams
UNION ALL
SELECT 'Users:' AS section, username FROM users
UNION ALL
SELECT 'Tasks:' AS section, title FROM tasks;


-- Lesson Exercises

-- # Exercise 1 — Model Design (10 min)
-- ## Questions

-- 1. What relationships should `Comment` have?
-- It should have two reltions, one to task and one to user

-- 2. Should `Task` have a `comments` relationship?
-- Yes

-- 3. What should happen to comments when a task is deleted?
-- They should be deleted on cascade automatically

---

-- # Exercise 2 — Migration Creation (10 min)

-- ## Questions
 
-- 1. What does `upgrade()` do?
-- upgrade() applies to schema changes, like when it create tables or add columns

-- 2. What does `downgrade()` do?
-- downgrade() reverses the migration

-- 3. What happens if you downgrade this migration?
-- Downgrading this migration deletes the comments table and all its data.


-- # Exercise 3 — CRUD Challenge (10 min)

-- # Exercise 4 — Migration Rollback (5 min)

-- ## Questions

-- 1. What happens to the column?
-- The estimated_hours column is removed from the database schema.

-- 2. What happens to the data?
-- All data stored in that column is lost after rollback.

---

-- # Exercise 5 — Concept Check (5 min)

-- Answer briefly:
 
-- 1. Why use ORM instead of raw SQL?
-- ORM is for a more easier portability of SQL into Pyhton objects

-- 2. Why use migrations?
-- To track and version database schema changes safely.

-- 3. When would you rollback?
-- Failed Deployment, bad schema changes, broken migrations, etc

-- 4. Difference between `add()` and `commit()`?
--  add() places objects into session and commit() permanently saves changes

-- 5. Why are relationships useful?
-- Easier navigations between tables

---