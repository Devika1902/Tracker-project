-- Use a fixed reporting date so results can be reconciled to the weekly update.
-- 1. Late tasks still requiring work.
SELECT task_id, task_name, team, owner_name, due_date, status
FROM project_tasks
WHERE due_date < DATE '2026-11-25'
  AND status <> 'Complete'
ORDER BY due_date;

-- 2. Task completion and average progress by team.
SELECT team,
       COUNT(*) AS task_count,
       SUM(CASE WHEN status = 'Complete' THEN 1 ELSE 0 END) AS completed_tasks,
       ROUND(AVG(progress_percent), 0) AS average_progress_percent
FROM project_tasks
GROUP BY team
ORDER BY team;

-- 3. Open issues, prioritised by severity and target date.
SELECT issue_id, title, severity, team, owner_name, target_date, business_impact
FROM issues
WHERE status = 'Open'
ORDER BY CASE severity WHEN 'High' THEN 1 WHEN 'Medium' THEN 2 ELSE 3 END,
         target_date;

-- 4. Work whose prerequisite task is not yet complete.
SELECT t.task_id, t.task_name, t.team, prerequisite.task_id AS prerequisite_id,
       prerequisite.task_name AS prerequisite_name, prerequisite.status AS prerequisite_status
FROM project_tasks t
JOIN project_tasks prerequisite ON prerequisite.task_id = t.dependency_id
WHERE prerequisite.status <> 'Complete'
ORDER BY t.due_date;

-- 5. Milestones planned but not achieved by the reporting date.
SELECT milestone_id, milestone_name, owner_team, planned_date, status
FROM milestones
WHERE planned_date < DATE '2026-11-25'
  AND actual_date IS NULL
ORDER BY planned_date;
