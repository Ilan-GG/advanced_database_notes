-- Lesson 08: Exercise — Assignment History

-- A support ticketing system. Tickets get reassigned between agents. You need
-- to track who was assigned when the ticket was created vs when it was resolved.

---

-- ## Step 1 — Source Tables (OLTP)

-- Create two tables:

-- **`tickets`** — current state of each ticket. Needs:
-- ticket_id, title, status, priority, created_at, resolved_at, assigned_to

-- **`ticket_assignments`** — history of who was assigned when. Needs:
-- assignment_id, ticket_id, assigned_to, assigned_by, valid_from, valid_to

CREATE TABLE tickets (
    ticket_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title        VARCHAR2(200) NOT NULL,
    status       VARCHAR2(20) NOT NULL,
    priority     VARCHAR2(10) NOT NULL,
    created_at   TIMESTAMP DEFAULT SYSTIMESTAMP,
    resolved_at  TIMESTAMP,
    assigned_to  NUMBER NOT NULL
);

CREATE TABLE ticket_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id     NUMBER NOT NULL REFERENCES tickets(ticket_id),
    assigned_to   NUMBER NOT NULL,
    assigned_by   NUMBER,
    valid_from    TIMESTAMP NOT NULL,
    valid_to      TIMESTAMP
);

-- ## Step 2 — Sample Data

-- Insert at least 5 tickets. Make sure at least one gets reassigned (different
-- person in `ticket_assignments` than the current `assigned_to` in `tickets`).

INSERT INTO tickets
(title, status, priority, created_at, resolved_at, assigned_to)
VALUES
('Login issue', 'resolved', 'high',
 TIMESTAMP '2026-06-01 09:00:00',
 TIMESTAMP '2026-06-02 10:00:00',
 1);

INSERT INTO tickets
(title, status, priority, created_at, assigned_to)
VALUES
('Database timeout', 'open', 'critical',
 TIMESTAMP '2026-06-02 11:00:00',
 2);

INSERT INTO tickets
(title, status, priority, created_at, assigned_to)
VALUES
('Email delivery failure', 'in_progress', 'medium',
 TIMESTAMP '2026-06-03 08:00:00',
 3);

INSERT INTO tickets
(title, status, priority, created_at, assigned_to)
VALUES
('API latency spike', 'open', 'high',
 TIMESTAMP '2026-06-04 10:00:00',
 1);

INSERT INTO tickets
(title, status, priority, created_at, assigned_to)
VALUES
('UI rendering bug', 'open', 'low',
 TIMESTAMP '2026-06-05 14:00:00',
 2);

COMMIT;

---

-- ## Step 3 — Trigger

-- Write a trigger on `tickets` that:
-- On INSERT or UPDATE of `assigned_to`, logs the change to `ticket_assignments`
-- Closes the previous active assignment (sets its `valid_to`)
-- Inserts a new row with `valid_from = now()` and `valid_to = NULL`

CREATE OR REPLACE TRIGGER trg_ticket_assignment_log
AFTER INSERT OR UPDATE OF assigned_to
ON tickets
FOR EACH ROW
BEGIN

    IF INSERTING THEN

        INSERT INTO ticket_assignments
        (
            ticket_id,
            assigned_to,
            assigned_by,
            valid_from
        )
        VALUES
        (
            :NEW.ticket_id,
            :NEW.assigned_to,
            NULL,
            :NEW.created_at
        );

    ELSIF UPDATING THEN

        UPDATE ticket_assignments
           SET valid_to = SYSTIMESTAMP
         WHERE ticket_id = :OLD.ticket_id
           AND valid_to IS NULL;

        INSERT INTO ticket_assignments
        (
            ticket_id,
            assigned_to,
            assigned_by,
            valid_from
        )
        VALUES
        (
            :NEW.ticket_id,
            :NEW.assigned_to,
            NULL,
            SYSTIMESTAMP
        );

    END IF;

END;
/

-- ## Step 4 — Data Warehouse Tables (Star Schema)
-- 
-- Create two tables:
-- 
-- **`dim_agent`** — agent details. Needs: agent_key, agent_name, team
-- 
-- **`fact_ticket_daily`** — daily counts per agent/status/priority. Needs:
-- date_key, agent_key, status, priority, tickets_created, tickets_resolved

CREATE TABLE dim_agent (
    agent_key   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_id    NUMBER NOT NULL,
    agent_name  VARCHAR2(100) NOT NULL,
    team        VARCHAR2(50) NOT NULL
);

CREATE TABLE fact_ticket_daily (
    fact_key          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key          NUMBER NOT NULL,
    agent_key         NUMBER NOT NULL REFERENCES dim_agent(agent_key),
    status            VARCHAR2(20) NOT NULL,
    priority          VARCHAR2(10) NOT NULL,
    tickets_created   NUMBER DEFAULT 0,
    tickets_resolved  NUMBER DEFAULT 0
);

-- ## Step 5 — Populate dim_agent

-- Insert 3-4 agents with their teams.

INSERT INTO dim_agent (agent_id, agent_name, team)
VALUES (1, 'Alice', 'Support');

INSERT INTO dim_agent (agent_id, agent_name, team)
VALUES (2, 'Bob', 'Support');

INSERT INTO dim_agent (agent_id, agent_name, team)
VALUES (3, 'Carol', 'Escalations');

INSERT INTO dim_agent (agent_id, agent_name, team)
VALUES (4, 'Dave', 'Escalations');

COMMIT;

-- ## Step 6 — ETL Logic (Colab)

-- In your Colab notebook, write pandas code that:
-- 1. Extracts `tickets` and `ticket_assignments` from FreeSQL
-- 2. For each ticket, finds who was assigned at `created_at` using:
--    `valid_from <= created_at AND (valid_to IS NULL OR valid_to > created_at)`
-- 3. Same for `resolved_at`
-- 4. Groups by date, agent, status, priority and counts
-- 5. Inserts into `fact_ticket_daily`

-- Codigo del Python
import pandas as pd

tickets = pd.read_sql("SELECT * FROM tickets", conn)
assignments = pd.read_sql("SELECT * FROM ticket_assignments", conn)

def find_agent(ticket_id, moment):

    rows = assignments[
        (assignments["ticket_id"] == ticket_id) &
        (assignments["valid_from"] <= moment) &
        (
            assignments["valid_to"].isna() |
            (assignments["valid_to"] > moment)
        )
    ]

    if len(rows) == 0:
        return None

    return rows.iloc[0]["assigned_to"]


created_rows = []

for _, t in tickets.iterrows():

    creator_agent = find_agent(
        t["ticket_id"],
        t["created_at"]
    )

    created_rows.append({
        "date_key": int(pd.to_datetime(t["created_at"]).strftime("%Y%m%d")),
        "agent_id": creator_agent,
        "status": t["status"],
        "priority": t["priority"],
        "tickets_created": 1,
        "tickets_resolved": 0
    })

    if pd.notnull(t["resolved_at"]):

        resolver_agent = find_agent(
            t["ticket_id"],
            t["resolved_at"]
        )

        created_rows.append({
            "date_key": int(pd.to_datetime(t["resolved_at"]).strftime("%Y%m%d")),
            "agent_id": resolver_agent,
            "status": t["status"],
            "priority": t["priority"],
            "tickets_created": 0,
            "tickets_resolved": 1
        })

fact_df = pd.DataFrame(created_rows)

fact_df = (
    fact_df
    .groupby(
        ["date_key", "agent_id", "status", "priority"],
        as_index=False
    )
    .sum()
)

-- ## Step 7 — Verify

-- Write a query joining `fact_ticket_daily` and `dim_agent` to show tickets
-- created and resolved per agent per day. The reassigned ticket should show
-- the original agent for creation and the new agent for resolution.

SELECT
    f.date_key,
    a.agent_name,
    a.team,
    f.status,
    f.priority,
    f.tickets_created,
    f.tickets_resolved
FROM fact_ticket_daily f
JOIN dim_agent a
    ON f.agent_key = a.agent_key
ORDER BY
    f.date_key,
    a.agent_name;
