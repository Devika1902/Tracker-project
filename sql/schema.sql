-- Portable starter schema for the fictional implementation tracker.
CREATE TABLE project_tasks (
    task_id VARCHAR(10) PRIMARY KEY,
    task_name VARCHAR(200) NOT NULL,
    team VARCHAR(60) NOT NULL,
    owner_name VARCHAR(100) NOT NULL,
    due_date DATE NOT NULL,
    status VARCHAR(30) NOT NULL,
    progress_percent INTEGER NOT NULL CHECK (progress_percent BETWEEN 0 AND 100),
    dependency_id VARCHAR(10),
    priority VARCHAR(20) NOT NULL,
    FOREIGN KEY (dependency_id) REFERENCES project_tasks(task_id)
);

CREATE TABLE dependencies (
    task_id VARCHAR(10) NOT NULL,
    depends_on_task_id VARCHAR(10) NOT NULL,
    dependency_status VARCHAR(30) NOT NULL,
    PRIMARY KEY (task_id, depends_on_task_id),
    FOREIGN KEY (task_id) REFERENCES project_tasks(task_id),
    FOREIGN KEY (depends_on_task_id) REFERENCES project_tasks(task_id)
);

CREATE TABLE issues (
    issue_id VARCHAR(10) PRIMARY KEY,
    title VARCHAR(240) NOT NULL,
    description VARCHAR(500),
    severity VARCHAR(20) NOT NULL,
    owner_name VARCHAR(100) NOT NULL,
    team VARCHAR(60) NOT NULL,
    status VARCHAR(30) NOT NULL,
    target_date DATE,
    business_impact VARCHAR(240)
);

CREATE TABLE milestones (
    milestone_id VARCHAR(10) PRIMARY KEY,
    milestone_name VARCHAR(200) NOT NULL,
    planned_date DATE NOT NULL,
    actual_date DATE,
    status VARCHAR(30) NOT NULL,
    owner_team VARCHAR(60) NOT NULL
);
