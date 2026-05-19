-- ============================================================
-- Lesson 07: KPI Dashboards — Class Exercises
-- File: 06_exercises.sql
-- Purpose: Practice defining KPIs, writing queries, and handling edge cases
--
-- Instructions: Open this file in your FreeSQL worksheet.
-- For each exercise, write your query below the prompt, then run it.
-- There is no "autograder" — correctness is determined by whether
-- the query matches the KPI contract YOU defined.
-- ============================================================

-- ============================================================
-- EXERCISE 1: Define "Team Velocity"
-- ============================================================

-- KPI CONTRACT:
-- Business question:
-- Which teams complete work the fastest relative to team size?
--
-- Definition:
-- Velocity = completed tasks per team member over the measured period.
-- Only tasks with status = 'completed' are counted.
-- Team member count comes from users assigned to each team.
--
-- Edge cases:
-- - Teams with zero completed tasks should still appear.
-- - Teams with zero users must avoid division by zero.
-- - Cancelled tasks are excluded because they were never delivered.
--
-- Unit:
-- Completed tasks per team member.
--
-- Limitation:
-- This metric ignores task complexity. Completing 10 small tasks
-- may appear better than completing 2 critical tasks.

WITH team_metrics AS (
    SELECT
        t.id,
        t.name AS team_name,
        COUNT(DISTINCT u.id) AS member_count,
        COUNT(CASE WHEN ts.status = 'completed' THEN ts.id END) AS completed_tasks,
        ROUND(
            COUNT(CASE WHEN ts.status = 'completed' THEN ts.id END)
            / NULLIF(COUNT(DISTINCT u.id), 0),
            2
        ) AS velocity
    FROM teams t
    LEFT JOIN users u
        ON u.team_id = t.id
    LEFT JOIN tasks ts
        ON ts.assigned_to = u.id
    GROUP BY t.id, t.name
)
SELECT
    team_name,
    member_count,
    completed_tasks,
    velocity,
    CASE
        WHEN velocity <
             AVG(velocity) OVER ()
        THEN 'Below Average'
        ELSE 'Above Average'
    END AS velocity_flag
FROM team_metrics
ORDER BY velocity DESC;



-- ============================================================
-- EXERCISE 2: Define "On-Time Delivery Rate"
-- ============================================================

-- KPI CONTRACT:
-- Business question:
-- How consistently are completed tasks delivered on or before deadline?
--
-- Definition:
-- A task is considered on-time if completed_at <= due_date + 1 day.
-- This treats the due date as ending at 23:59:59.
-- Only completed tasks with non-null due_date are included.
--
-- Edge cases:
-- - Tasks without due_date are excluded.
-- - Cancelled tasks are excluded.
-- - Tasks completed one minute after midnight are considered late.
--
-- Unit:
-- Percentage of completed tasks delivered on time.
--
-- Limitation:
-- Tasks with unrealistic deadlines can distort results.

SELECT
    priority,
    COUNT(*) AS completed_tasks,
    SUM(
        CASE
            WHEN completed_at <= due_date + 1
            THEN 1
            ELSE 0
        END
    ) AS on_time_tasks,
    ROUND(
        SUM(
            CASE
                WHEN completed_at <= due_date + 1
                THEN 1
                ELSE 0
            END
        ) * 100 / COUNT(*),
        2
    ) AS on_time_delivery_rate,
    ROUND(
        AVG(
            CASE
                WHEN completed_at > due_date + 1
                THEN
                    (
                        EXTRACT(DAY FROM (completed_at - CAST(due_date AS TIMESTAMP))) * 24
                    ) +
                    EXTRACT(HOUR FROM (completed_at - CAST(due_date AS TIMESTAMP))) +
                    EXTRACT(MINUTE FROM (completed_at - CAST(due_date AS TIMESTAMP))) / 60
            END
        ),
        2
    ) AS avg_late_hours
FROM tasks
WHERE status = 'completed'
  AND due_date IS NOT NULL
  AND completed_at IS NOT NULL
GROUP BY priority
ORDER BY
    CASE priority
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
    END;



-- ============================================================
-- EXERCISE 3: Improve "Tasks per Team"
-- ============================================================

SELECT
    t.name AS team_name,

    COUNT(ts.id) AS total_tasks,

    COUNT(
        CASE
            WHEN ts.status IN ('open', 'in_progress', 'blocked')
            THEN 1
        END
    ) AS active_tasks,

    ROUND(
        COUNT(
            CASE
                WHEN ts.status = 'completed'
                THEN 1
            END
        ) * 100
        /
        NULLIF(
            COUNT(
                CASE
                    WHEN ts.status <> 'cancelled'
                    THEN 1
                END
            ),
            0
        ),
        2
    ) AS completion_rate,

    CASE
        WHEN COUNT(
            CASE
                WHEN ts.status IN ('open', 'in_progress', 'blocked')
                THEN 1
            END
        ) > 10
        THEN 'Overloaded'

        WHEN COUNT(
            CASE
                WHEN ts.status IN ('open', 'in_progress', 'blocked')
                THEN 1
            END
        ) BETWEEN 5 AND 10
        THEN 'Healthy'

        ELSE 'Underutilized'
    END AS health_score

FROM teams t
LEFT JOIN users u
    ON u.team_id = t.id
LEFT JOIN tasks ts
    ON ts.assigned_to = u.id

GROUP BY t.id, t.name

ORDER BY active_tasks DESC;



-- ============================================================
-- EXERCISE 4: Improve "Average Resolution Time"
-- ============================================================

WITH resolution_data AS (
    SELECT
        priority,

        (
            EXTRACT(DAY FROM (completed_at - created_at)) * 24
            +
            EXTRACT(HOUR FROM (completed_at - created_at))
            +
            EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
        ) AS resolution_hours

    FROM tasks
    WHERE status = 'completed'
      AND completed_at IS NOT NULL
)

SELECT
    priority,

    ROUND(AVG(resolution_hours), 2) AS avg_resolution_hours,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY resolution_hours),
        2
    ) AS median_resolution_hours,

    ROUND(MIN(resolution_hours), 2) AS fastest_resolution_hours,

    ROUND(MAX(resolution_hours), 2) AS slowest_resolution_hours,

    COUNT(*) AS completed_task_count,

    CASE
        WHEN priority = 'critical'
             AND AVG(resolution_hours) <= 24
        THEN 'YES'

        WHEN priority = 'high'
             AND AVG(resolution_hours) <= 72
        THEN 'YES'

        WHEN priority = 'medium'
             AND AVG(resolution_hours) <= 168
        THEN 'YES'

        WHEN priority = 'low'
             AND AVG(resolution_hours) <= 336
        THEN 'YES'

        ELSE 'NO'
    END AS target_met

FROM resolution_data

GROUP BY priority

ORDER BY
    CASE priority
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
    END;



-- ============================================================
-- EXERCISE 5: Improve "Overdue Tasks"
-- ============================================================

WITH overdue_tasks AS (
    SELECT
        ts.title,
        u.full_name AS assignee,
        t.name AS team_name,
        ts.priority,
        ts.due_date,
        TRUNC(SYSDATE) - ts.due_date AS days_overdue,

        CASE
            WHEN ts.priority = 'critical'
                 AND (TRUNC(SYSDATE) - ts.due_date) > 0
            THEN 'CRITICAL'

            WHEN ts.priority = 'high'
                 AND (TRUNC(SYSDATE) - ts.due_date) > 2
            THEN 'HIGH'

            WHEN ts.priority = 'medium'
                 AND (TRUNC(SYSDATE) - ts.due_date) > 5
            THEN 'MEDIUM'

            ELSE 'LOW'
        END AS severity

    FROM tasks ts
    LEFT JOIN users u
        ON ts.assigned_to = u.id
    LEFT JOIN teams t
        ON u.team_id = t.id

    WHERE ts.status NOT IN ('completed', 'cancelled')
      AND ts.due_date < TRUNC(SYSDATE)
)

SELECT
    title,
    assignee,
    team_name,
    priority,
    due_date,
    days_overdue,
    severity
FROM overdue_tasks

UNION ALL

SELECT
    'SUMMARY',
    NULL,
    NULL,
    NULL,
    NULL,
    ROUND(AVG(days_overdue), 2),
    severity || ' TOTAL: ' || COUNT(*)
FROM overdue_tasks
GROUP BY severity

ORDER BY
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        WHEN 'LOW' THEN 4
        ELSE 5
    END,
    days_overdue DESC;



-- ============================================================
-- EXERCISE 6: Fix the "Productivity Score"
-- ============================================================

-- PROBLEM:
-- The original query counts all assigned tasks, regardless of whether
-- they were completed. It measures workload, not productivity.
-- It also ignores task difficulty and priority.

WITH weighted_tasks AS (
    SELECT
        u.full_name,

        CASE ts.priority
            WHEN 'critical' THEN 4
            WHEN 'high' THEN 3
            WHEN 'medium' THEN 2
            WHEN 'low' THEN 1
        END AS weight

    FROM users u
    JOIN tasks ts
        ON ts.assigned_to = u.id

    WHERE ts.status = 'completed'
)

SELECT
    full_name,

    COUNT(*) AS completed_tasks,

    SUM(weight) AS weighted_score,

    ROUND(
        SUM(weight) / 14,
        2
    ) AS weighted_tasks_per_day

FROM weighted_tasks

GROUP BY full_name

ORDER BY weighted_tasks_per_day DESC;



-- ============================================================
-- EXERCISE 7: Fix the "Team Efficiency"
-- ============================================================

-- PROBLEM:
-- AVG(task_id) is mathematically meaningless because task IDs are
-- surrogate keys, not measurable business values.

SELECT
    t.name AS team_name,

    COUNT(ts.id) AS total_tasks,

    COUNT(
        CASE
            WHEN ts.status = 'completed'
            THEN 1
        END
    ) AS completed_tasks,

    ROUND(
        COUNT(
            CASE
                WHEN ts.status = 'completed'
                THEN 1
            END
        ) * 100
        /
        NULLIF(COUNT(ts.id), 0),
        2
    ) AS efficiency_rate

FROM teams t
JOIN users u
    ON u.team_id = t.id
JOIN tasks ts
    ON ts.assigned_to = u.id

GROUP BY t.id, t.name

ORDER BY efficiency_rate DESC;



-- ============================================================
-- EXERCISE 8: Fix the "Urgency Index"
-- ============================================================

-- PROBLEM:
-- The original query attempts arithmetic with VARCHAR values and DATEs.
-- Priority must first be converted into a numeric weight.

SELECT
    title,
    priority,
    due_date,

    CASE priority
        WHEN 'critical' THEN 4
        WHEN 'high' THEN 3
        WHEN 'medium' THEN 2
        WHEN 'low' THEN 1
    END AS priority_weight,

    due_date - TRUNC(SYSDATE) AS days_until_due,

    (
        CASE priority
            WHEN 'critical' THEN 40
            WHEN 'high' THEN 30
            WHEN 'medium' THEN 20
            WHEN 'low' THEN 10
        END
        -
        (due_date - TRUNC(SYSDATE))
    ) AS urgency_score

FROM tasks

WHERE status NOT IN ('completed', 'cancelled')
  AND due_date IS NOT NULL

ORDER BY urgency_score DESC;