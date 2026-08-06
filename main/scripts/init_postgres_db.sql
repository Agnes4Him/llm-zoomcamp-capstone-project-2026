-- ============================================================
-- 1. POSTGRES SCHEMA CREATION
-- ============================================================

DROP TABLE IF EXISTS feedbacks;
DROP TABLE IF EXISTS conversations;
DROP TABLE IF EXISTS claims;
DROP TABLE IF EXISTS members;

-- Table: conversations
CREATE TABLE conversations (
    id SERIAL PRIMARY KEY,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    model TEXT NOT NULL,
    instructions TEXT NOT NULL,
    prompt TEXT NOT NULL,
    prompt_tokens INTEGER NOT NULL,
    completion_tokens INTEGER NOT NULL,
    total_tokens INTEGER NOT NULL,
    response_time FLOAT NOT NULL,
    cost FLOAT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Table: feedbacks
CREATE TABLE feedbacks (
    id SERIAL PRIMARY KEY,
    conversation_id INTEGER REFERENCES conversations(id),
    source TEXT NOT NULL,
    relevance TEXT,
    explanation TEXT,
    score INTEGER,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Table: members
CREATE TABLE members (
    member_id INT GENERATED ALWAYS AS IDENTITY (START WITH 1001 INCREMENT BY 1) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    plan VARCHAR(20) NOT NULL,
    member_since DATE NOT NULL,
    deductible NUMERIC(10, 2) NOT NULL,
    remaining_deductible NUMERIC(10, 2) NOT NULL,
    copay_gp NUMERIC(10, 2) NOT NULL,
    copay_specialist NUMERIC(10, 2) NOT NULL,
    out_of_pocket_max NUMERIC(10, 2) NOT NULL,
    out_of_pocket_used NUMERIC(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Active'
);

-- Table: claims
CREATE TABLE claims (
    claim_id VARCHAR(20) PRIMARY KEY,
    member_id INT NOT NULL,
    procedure_name VARCHAR(100) NOT NULL,
    provider_name VARCHAR(100) NOT NULL,
    service_date DATE NOT NULL,
    amount_claimed NUMERIC(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    denial_reason TEXT,
    CONSTRAINT fk_member
        FOREIGN KEY (member_id) 
        REFERENCES members(member_id) 
        ON DELETE CASCADE
);

-- ============================================================
-- 2. MEMBERS DATA (20 Records)
-- ============================================================

INSERT INTO members (
    first_name, last_name, email, phone, plan, member_since,
    deductible, remaining_deductible, copay_gp, copay_specialist,
    out_of_pocket_max, out_of_pocket_used, status
) VALUES
-- Gold Plan Tier ($500 Deductible | $10 GP / $25 Specialist Copay | $3,000 OOP Max)
('Alice', 'Johnson', 'alice.johnson@example.com', '555-0101', 'Gold', '2021-03-15', 500.00, 150.00, 10.00, 25.00, 3000.00, 1200.00, 'Active'),
('Robert', 'Smith', 'robert.smith@example.com', '555-0104', 'Gold', '2020-11-05', 500.00, 0.00, 10.00, 25.00, 3000.00, 3000.00, 'Active'),
('David', 'Miller', 'david.miller@example.com', '555-0106', 'Gold', '2022-01-12', 500.00, 500.00, 10.00, 25.00, 3000.00, 0.00, 'Active'),
('Hannah', 'White', 'hannah.white@example.com', '555-0109', 'Gold', '2019-05-24', 500.00, 200.00, 10.00, 25.00, 3000.00, 850.00, 'Active'),
('Karen', 'Taylor', 'karen.taylor@example.com', '555-0112', 'Gold', '2021-08-30', 500.00, 0.00, 10.00, 25.00, 3000.00, 1950.00, 'Active'),
('Megan', 'Adams', 'megan.adams@example.com', '555-0115', 'Gold', '2023-04-18', 500.00, 350.00, 10.00, 25.00, 3000.00, 400.00, 'Active'),
('Rachel', 'Evans', 'rachel.evans@example.com', '555-0119', 'Gold', '2020-03-11', 500.00, 100.00, 10.00, 25.00, 3000.00, 1100.00, 'Active'),

-- Silver Plan Tier ($1,000 Deductible | $25 GP / $45 Specialist Copay | $5,000 OOP Max)
('James', 'Brown', 'james.brown@example.com', '555-0102', 'Silver', '2022-07-20', 1000.00, 600.00, 25.00, 45.00, 5000.00, 2100.00, 'Active'),
('Emily', 'Davis', 'emily.davis@example.com', '555-0105', 'Silver', '2021-09-18', 1000.00, 1000.00, 25.00, 45.00, 5000.00, 0.00, 'Suspended'),
('Michael', 'Wilson', 'michael.wilson@example.com', '555-0107', 'Silver', '2023-03-01', 1000.00, 450.00, 25.00, 45.00, 5000.00, 1300.00, 'Active'),
('Ian', 'Harris', 'ian.harris@example.com', '555-0110', 'Silver', '2022-10-14', 1000.00, 850.00, 25.00, 45.00, 5000.00, 600.00, 'Active'),
('Laura', 'Clark', 'laura.clark@example.com', '555-0113', 'Silver', '2020-02-19', 1000.00, 0.00, 25.00, 45.00, 5000.00, 2800.00, 'Active'),
('Nathan', 'Baker', 'nathan.baker@example.com', '555-0116', 'Silver', '2021-12-05', 1000.00, 750.00, 25.00, 45.00, 5000.00, 950.00, 'Cancelled'),
('Samuel', 'Stone', 'samuel.stone@example.com', '555-0120', 'Silver', '2022-06-30', 1000.00, 200.00, 25.00, 45.00, 5000.00, 1850.00, 'Active'),

-- Bronze Plan Tier ($2,000 Deductible | $40 GP / $60 Specialist Copay | $7,500 OOP Max)
('Maria', 'Garcia', 'maria.garcia@example.com', '555-0103', 'Bronze', '2023-01-10', 2000.00, 1800.00, 40.00, 60.00, 7500.00, 450.00, 'Active'),
('Sophia', 'Anderson', 'sophia.anderson@example.com', '555-0108', 'Bronze', '2023-06-15', 2000.00, 2000.00, 40.00, 60.00, 7500.00, 0.00, 'Active'),
('Jack', 'Martin', 'jack.martin@example.com', '555-0111', 'Bronze', '2021-04-03', 2000.00, 1200.00, 40.00, 60.00, 7500.00, 1500.00, 'Active'),
('Oliver', 'Lewis', 'oliver.lewis@example.com', '555-0114', 'Bronze', '2022-11-22', 2000.00, 1900.00, 40.00, 60.00, 7500.00, 200.00, 'Active'),
('Paul', 'Nelson', 'paul.nelson@example.com', '555-0117', 'Bronze', '2023-09-01', 2000.00, 1600.00, 40.00, 60.00, 7500.00, 800.00, 'Active'),
('Quinn', 'Roberts', 'quinn.roberts@example.com', '555-0118', 'Bronze', '2020-07-14', 2000.00, 500.00, 40.00, 60.00, 7500.00, 3100.00, 'Active');


-- ============================================================
-- 3. CLAIMS DATA (30 Records)
-- ============================================================

INSERT INTO claims (
    claim_id, member_id, procedure_name, provider_name, service_date,
    amount_claimed, status, denial_reason
) VALUES
('CLM1001', 1001, 'MRI Scan', 'Metro General Hospital', '2024-02-10', 1800.00, 'Approved', NULL),
('CLM1002', 1001, 'Physiotherapy Session', 'Apex Health Clinic', '2024-03-01', 150.00, 'Approved', NULL),
('CLM1003', 1002, 'Knee Surgery', 'St. Jude Medical Center', '2024-01-15', 8500.00, 'Pending', NULL),
('CLM1004', 1003, 'MRI Scan', 'City Diagnostics', '2024-02-22', 2100.00, 'Denied', 'Prior authorization required'),
('CLM1005', 1003, 'Specialist Visit', 'Valley Specialist Center', '2024-03-05', 350.00, 'Denied', 'Out-of-network provider'),
('CLM1006', 1004, 'Blood Test Panel', 'QuickLabs Inc', '2024-03-12', 250.00, 'Approved', NULL),
('CLM1007', 1005, 'GP Consultation', 'Downtown Health Partnership', '2024-01-30', 180.00, 'Denied', 'Service not covered under active plan'),
('CLM1008', 1006, 'CT Scan', 'Metro General Hospital', '2024-02-05', 1450.00, 'Approved', NULL),
('CLM1009', 1007, 'Emergency Room Visit', 'St. Jude Medical Center', '2024-01-08', 3200.00, 'Approved', NULL),
('CLM1010', 1008, 'Physiotherapy Session', 'Motion Care Rehab', '2024-03-18', 120.00, 'Pending', NULL),
('CLM1011', 1009, 'Specialist Visit', 'Cardiology Associates', '2024-02-14', 450.00, 'Approved', NULL),
('CLM1012', 1010, 'MRI Scan', 'Imaging First Center', '2024-01-22', 1950.00, 'Denied', 'Prior authorization required'),
('CLM1013', 1011, 'GP Consultation', 'Family Practice Care', '2024-03-02', 110.00, 'Approved', NULL),
('CLM1014', 1012, 'Knee Surgery', 'Ortho Specialty Hospital', '2024-02-28', 11200.00, 'Approved', NULL),
('CLM1015', 1013, 'Blood Test Panel', 'QuickLabs Inc', '2024-03-10', 310.00, 'Approved', NULL),
('CLM1016', 1014, 'Specialist Visit', 'Dermatology & Skin Center', '2024-01-19', 280.00, 'Denied', 'Out-of-network provider'),
('CLM1017', 1015, 'CT Scan', 'City Diagnostics', '2024-02-17', 1600.00, 'Pending', NULL),
('CLM1018', 1016, 'Physiotherapy Session', 'Motion Care Rehab', '2024-03-11', 140.00, 'Approved', NULL),
('CLM1019', 1017, 'Emergency Room Visit', 'Metro General Hospital', '2024-02-25', 4100.00, 'Approved', NULL),
('CLM1020', 1018, 'GP Consultation', 'Downtown Health Partnership', '2024-03-04', 130.00, 'Approved', NULL),
('CLM1021', 1019, 'MRI Scan', 'Metro General Hospital', '2024-01-29', 2250.00, 'Denied', 'Missing medical documentation'),
('CLM1022', 1020, 'Blood Test Panel', 'QuickLabs Inc', '2024-02-08', 290.00, 'Approved', NULL),
('CLM1023', 1001, 'CT Scan', 'Metro General Hospital', '2024-03-15', 1350.00, 'Approved', NULL),
('CLM1024', 1002, 'Physiotherapy Session', 'Apex Health Clinic', '2024-02-18', 150.00, 'Approved', NULL),
('CLM1025', 1004, 'Specialist Visit', 'Neurology Care Center', '2024-03-09', 520.00, 'Pending', NULL),
('CLM1026', 1006, 'Emergency Room Visit', 'St. Jude Medical Center', '2024-03-14', 2800.00, 'Approved', NULL),
('CLM1027', 1008, 'GP Consultation', 'Family Practice Care', '2024-02-11', 110.00, 'Approved', NULL),
('CLM1028', 1010, 'Physiotherapy Session', 'Motion Care Rehab', '2024-03-20', 140.00, 'Denied', 'Duplicate claim submission'),
('CLM1029', 1012, 'Blood Test Panel', 'QuickLabs Inc', '2024-01-05', 210.00, 'Approved', NULL),
('CLM1030', 1014, 'MRI Scan', 'Imaging First Center', '2024-03-01', 1890.00, 'Approved', NULL);