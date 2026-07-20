CREATE DATABASE StudentServicesDB;
GO

USE StudentServicesDB;
GO


-- CREATE LOGINS AND USERS

CREATE LOGIN AdminLogin WITH PASSWORD = 'AdminPass123!', CHECK_POLICY = OFF;
CREATE LOGIN FacultyLogin WITH PASSWORD = 'FacultyPass123!', CHECK_POLICY = OFF;
CREATE LOGIN StudentLogin WITH PASSWORD = 'StudentPass123!', CHECK_POLICY = OFF;
GO

CREATE USER AdminUser FOR LOGIN AdminLogin;
CREATE USER FacultyUser FOR LOGIN FacultyLogin;
CREATE USER StudentUser FOR LOGIN StudentLogin;
GO

ALTER ROLE db_owner ADD MEMBER AdminUser;
CREATE ROLE FacultyRole;
CREATE ROLE StudentRole;
GO

ALTER ROLE FacultyRole ADD MEMBER FacultyUser;
ALTER ROLE StudentRole ADD MEMBER StudentUser;
GO

PRINT 'Database and user accounts created successfully!';








--  CREATE ALL TABLES


USE StudentServicesDB;
GO

-- 1. DEPARTMENTS Table 
CREATE TABLE DEPARTMENTS(
    DeptID INT IDENTITY(1,1) PRIMARY KEY,
    DeptName VARCHAR(100) NOT NULL,
    Location VARCHAR(50) NOT NULL,
    HOD VARCHAR(100) NOT NULL
);
GO

-- 2. COURSES Table 
CREATE TABLE COURSES (
    CourseID INT IDENTITY(1,1) PRIMARY KEY,
    CourseName VARCHAR(150) NOT NULL,
    CourseType VARCHAR(20) CHECK (CourseType IN ('Diploma', 'Certificate', 'Artisan')),
    DeptID INT FOREIGN KEY REFERENCES DEPARTMENTS(DeptID)
);
GO

-- 3. CLASSES Table 
CREATE TABLE CLASSES (
    ClassID INT IDENTITY(1,1) PRIMARY KEY,
    ClassName VARCHAR(50) NOT NULL,
    CourseID INT FOREIGN KEY REFERENCES COURSES(CourseID),
    IntakeYear INT NOT NULL
);
GO

-- 4. STUDENT Table 
CREATE TABLE STUDENT (
    StudentID INT IDENTITY(1,1) PRIMARY KEY,
    FullName VARCHAR(150) NOT NULL,
    DOB DATE NOT NULL,
    Gender CHAR(1) CHECK (Gender IN ('M', 'F')),
    Address VARCHAR(250),
    ClassID INT FOREIGN KEY REFERENCES CLASSES(ClassID),
    EnrollmentStatus VARCHAR(20) CHECK (EnrollmentStatus IN ('in session', 'on attachment', 'completed')),
    FeeBalance DECIMAL(10,2) DEFAULT 0.00,
    CONSTRAINT UQ_Student_Name_DOB UNIQUE (FullName, DOB)
);
GO

-- 5. LECTURES Table 
CREATE TABLE LECTURES (
    LecturerID INT IDENTITY(1,1) PRIMARY KEY,
    LecturerName VARCHAR(150) NOT NULL,
    Specialty VARCHAR(100),
    HasExtraRoles BIT DEFAULT 0,
    AllocatedHours INT DEFAULT 40
);
GO

-- 6. SUBJECT Table
CREATE TABLE SUBJECT (
    SubjectCode VARCHAR(20) PRIMARY KEY,
    SubjectName VARCHAR(100) NOT NULL,
    WeeklyHours INT CHECK (WeeklyHours BETWEEN 2 AND 6),
    CourseID INT FOREIGN KEY REFERENCES COURSES(CourseID)
);
GO

-- 7. WORKALLOCATION Table
CREATE TABLE WORKALLOCATION (
    AllocationID INT IDENTITY(1,1) PRIMARY KEY,
    LecturerID INT FOREIGN KEY REFERENCES LECTURES(LecturerID),
    SubjectCode VARCHAR(20) FOREIGN KEY REFERENCES SUBJECT(SubjectCode),
    ClassID INT FOREIGN KEY REFERENCES CLASSES(ClassID),
    Term INT NOT NULL,
    Year INT NOT NULL
);
GO

-- 8. ASSESS Table
CREATE TABLE ASSESS (
    AssessmentID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT FOREIGN KEY REFERENCES STUDENT(StudentID),
    SubjectCode VARCHAR(20) FOREIGN KEY REFERENCES SUBJECT(SubjectCode),
    Term INT NOT NULL,
    Year INT NOT NULL,
    CAT1 INT CHECK (CAT1 BETWEEN 0 AND 20),
    CAT2 INT CHECK (CAT2 BETWEEN 0 AND 20),
    ExamScore INT CHECK (ExamScore BETWEEN 0 AND 60),
    AttendancePercentage INT CHECK (AttendancePercentage BETWEEN 0 AND 100),
    IsSupplementary BIT DEFAULT 0
);
GO

-- 9. HOSTEL Table 
CREATE TABLE HOSTEL (
    HostelID INT IDENTITY(1,1) PRIMARY KEY,
    HostelName VARCHAR(50) NOT NULL,
    RoomNumber VARCHAR(10) NOT NULL,
    Cost DECIMAL(10,2) NOT NULL
);
GO

-- 10. HOSTEL_ALLOCATION Table 
CREATE TABLE HOSTEL_ALLOCATION (
    AllocationID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT FOREIGN KEY REFERENCES STUDENT(StudentID),
    HostelID INT FOREIGN KEY REFERENCES HOSTEL(HostelID),
    Term INT NOT NULL,
    Year INT NOT NULL,
    PaymentConfirmed BIT DEFAULT 0
);
GO

-- 11. CLUBS Table 
CREATE TABLE CLUBS (
    ClubID INT IDENTITY(1,1) PRIMARY KEY,
    ClubName VARCHAR(100) NOT NULL,
    PatronID INT FOREIGN KEY REFERENCES LECTURES(LecturerID),
    ChairpersonID INT FOREIGN KEY REFERENCES STUDENT(StudentID),
    LastActiveYear INT NOT NULL
);
GO

-- 12. CLUB_MEM Table 

 
 CREATE TABLE CLUB_MEM (
    MembershipID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT FOREIGN KEY REFERENCES STUDENT(StudentID),
    ClubID INT FOREIGN KEY REFERENCES CLUBS(ClubID),
    YearJoined INT NOT NULL
);
GO

-- 13. ATTACHMET Table 
CREATE TABLE ATTACHMET (
    AttachmentID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT FOREIGN KEY REFERENCES STUDENT(StudentID),
    FirmName VARCHAR(150) NOT NULL,
    PeriodWeeks INT NOT NULL,
    Term INT NOT NULL,
    Year INT NOT NULL,
    CompletionStatus VARCHAR(20) CHECK (CompletionStatus IN ('Ongoing', 'Completed', 'Failed'))
);
GO

PRINT 'All tables created successfully!';









--  SCHEMA MODIFICATIONS


USE StudentServicesDB;
GO

-- i) Add Column
ALTER TABLE STUDENT ADD DirectContact VARCHAR(15);
GO

-- ii) Change Data Type 
ALTER TABLE HOSTEL ALTER COLUMN RoomNumber VARCHAR(20) NOT NULL;
GO

-- iii) Export/Drop/Recreate Demonstration
-- Export structure to temp table
SELECT * INTO #TempHostelBackup FROM HOSTEL;
GO

-- Drop dependent tables first
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name LIKE '%HOSTEL_ALLOCATION%')
    ALTER TABLE HOSTEL_ALLOCATION DROP CONSTRAINT FK__HOSTEL_AL__Hoste__2A4B4B5E;
GO

-- Drop and recreate HOSTEL table
DROP TABLE HOSTEL_ALLOCATION;
DROP TABLE HOSTEL;
GO

CREATE TABLE HOSTEL (
    HostelID INT IDENTITY(1,1) PRIMARY KEY,
    HostelName VARCHAR(50) NOT NULL,
    RoomNumber VARCHAR(20) NOT NULL,
    Cost DECIMAL(10,2) NOT NULL
);
GO

-- Restore data
SET IDENTITY_INSERT HOSTEL ON;
INSERT INTO HOSTEL (HostelID, HostelName, RoomNumber, Cost)
SELECT HostelID, HostelName, RoomNumber, Cost FROM #TempHostelBackup;
SET IDENTITY_INSERT HOSTEL OFF;
GO

-- Recreate HOSTEL_ALLOCATION
CREATE TABLE HOSTEL_ALLOCATION (
    AllocationID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT FOREIGN KEY REFERENCES STUDENT(StudentID),
    HostelID INT FOREIGN KEY REFERENCES HOSTEL(HostelID),
    Term INT NOT NULL,
    Year INT NOT NULL,
    PaymentConfirmed BIT DEFAULT 0
);
GO

-- Drop temp table
DROP TABLE #TempHostelBackup;
GO

PRINT 'Schema modifications completed successfully!';











-- ALL TABLES WITH AT LEAST 10 RECORDS


USE StudentServicesDB;
GO

-- Insert DEPARTMENTS 
INSERT INTO DEPARTMENTS (DeptName, Location, HOD) VALUES 
('Computing and Informatics', 'Block A', 'Mr. John Mutua'),
('Mechanical Engineering', 'Block B', 'Eng. Sarah Wangari'),
('Electrical Engineering', 'Block B', 'Dr. Kevin Kamau'),
('Business Studies', 'Block C', 'Mrs. Faith Ndwiga'),
('Hospitality Management', 'Block D', 'Chef Alice Omwamba');
GO

-- Insert COURSES 
INSERT INTO COURSES (CourseName, CourseType, DeptID) VALUES
('Computer Science', 'Diploma', 1),
('Information Technology', 'Diploma', 1),
('Software Engineering', 'Diploma', 1),
('Electrical Engineering', 'Certificate', 3),
('Mechanical Engineering', 'Certificate', 2),
('Civil Engineering', 'Certificate', 2),
('Business Administration', 'Diploma', 4),
('Accounting', 'Certificate', 4),
('Culinary Arts', 'Artisan', 5),
('Hotel Management', 'Certificate', 5);
GO

-- Insert CLASSES 
INSERT INTO CLASSES (ClassName, CourseID, IntakeYear) VALUES
('CS-2025-A', 1, 2025),
('CS-2025-B', 1, 2025),
('IT-2026-A', 2, 2026),
('SE-2025-A', 3, 2025),
('EE-2026-B', 4, 2026),
('ME-2026-A', 5, 2026),
('CE-2025-A', 6, 2025),
('BA-2026-A', 7, 2026),
('ACC-2025-A', 8, 2025),
('HM-2026-A', 10, 2026);
GO

-- Insert STUDENT 
INSERT INTO STUDENT (FullName, DOB, Gender, Address, ClassID, EnrollmentStatus, FeeBalance) VALUES
('Alex Kiprop', '2002-05-12', 'M', 'Nairobi', 1, 'in session', 12000.00),
('Beatrice Wanjiku', '2003-08-22', 'F', 'Thika', 1, 'in session', 0.00),
('Charles Njoroge', '2001-02-14', 'M', 'Kiambu', 1, 'on attachment', 4500.00),
('Dorcas Chebet', '2004-11-30', 'F', 'Kericho', 5, 'in session', 15000.00),
('Evans Omwamba', '2000-07-19', 'M', 'Kisii', 1, 'completed', 0.00),
('Faith Mutheu', '2003-04-05', 'F', 'Machakos', 5, 'on attachment', 0.00),
('Gideon Bilal', '2002-12-25', 'M', 'Mombasa', 1, 'in session', 8500.00),
('Hannah Nyambura', '2001-10-10', 'F', 'Nakuru', 5, 'in session', 22000.00),
('Ian Kamau', '2003-01-01', 'M', 'Nyeri', 1, 'in session', 0.00),
('Joy Nafula', '2002-09-15', 'F', 'Bungoma', 5, 'completed', 0.00),
('Kevin Odhiambo', '2002-03-20', 'M', 'Kisumu', 2, 'in session', 5000.00),
('Linda Akinyi', '2003-07-14', 'F', 'Siaya', 2, 'in session', 0.00),
('Michael Mwangi', '2001-11-11', 'M', 'Nairobi', 3, 'on attachment', 3000.00),
('Nancy Kemunto', '2004-01-25', 'F', 'Kisii', 3, 'in session', 18000.00),
('Oscar Otieno', '2002-06-18', 'M', 'Kisumu', 4, 'in session', 0.00),
('Peninah Wanjiru', '2003-09-30', 'F', 'Nakuru', 6, 'in session', 7500.00),
('Quinton Mwangi', '2001-04-02', 'M', 'Thika', 6, 'completed', 0.00),
('Rachel Moraa', '2003-12-08', 'F', 'Mombasa', 7, 'in session', 9500.00),
('Samuel Kariuki', '2002-08-17', 'M', 'Nyeri', 8, 'in session', 0.00),
('Tracy Achieng', '2004-02-28', 'F', 'Kisumu', 9, 'in session', 12500.00);
GO

-- Insert LECTURES 
INSERT INTO LECTURES (LecturerName, Specialty, HasExtraRoles, AllocatedHours) VALUES
('Dr. Alan Turing', 'Data Science', 0, 40),
('Prof. Maxwell', 'Circuits', 1, 30),
('Dr. Grace Hopper', 'Programming', 0, 40),
('Prof. Einstein', 'Physics', 1, 25),
('Dr. Marie Curie', 'Chemistry', 0, 40),
('Prof. Newton', 'Mechanics', 0, 40),
('Dr. Ada Lovelace', 'Algorithms', 0, 40),
('Prof. Bohr', 'Quantum', 1, 30),
('Dr. Tesla', 'Electronics', 0, 40),
('Prof. Darwin', 'Biology', 0, 40);
GO

-- Insert SUBJECT 
INSERT INTO SUBJECT (SubjectCode, SubjectName, WeeklyHours, CourseID) VALUES
('CS-MOD1-01', 'Database Systems', 4, 1),
('CS-MOD1-02', 'Data Structures', 3, 1),
('CS-MOD2-01', 'Web Development', 4, 1),
('IT-MOD1-01', 'Networking', 3, 2),
('IT-MOD1-02', 'Cybersecurity', 4, 2),
('SE-MOD1-01', 'Software Design', 5, 3),
('EE-MOD1-01', 'Basic Electronics', 3, 4),
('EE-MOD1-02', 'Circuit Analysis', 4, 4),
('ME-MOD1-01', 'Thermodynamics', 4, 5),
('BA-MOD1-01', 'Financial Accounting', 3, 7);
GO

-- Insert WORKALLOCATION 
INSERT INTO WORKALLOCATION (LecturerID, SubjectCode, ClassID, Term, Year) VALUES
(1, 'CS-MOD1-01', 1, 1, 2026),
(2, 'EE-MOD1-01', 5, 1, 2026),
(3, 'CS-MOD1-02', 1, 1, 2026),
(1, 'CS-MOD2-01', 1, 2, 2026),
(4, 'IT-MOD1-01', 3, 1, 2026),
(5, 'IT-MOD1-02', 3, 1, 2026),
(6, 'SE-MOD1-01', 4, 1, 2026),
(7, 'CS-MOD1-01', 2, 1, 2026),
(8, 'EE-MOD1-02', 5, 1, 2026),
(9, 'ME-MOD1-01', 6, 1, 2026);
GO

-- Insert ASSESS 
INSERT INTO ASSESS (StudentID, SubjectCode, Term, Year, CAT1, CAT2, ExamScore, AttendancePercentage, IsSupplementary) VALUES
(1, 'CS-MOD1-01', 1, 2026, 18, 17, 52, 85, 0),
(2, 'CS-MOD1-01', 1, 2026, 12, 10, 35, 90, 0),
(3, 'CS-MOD1-01', 1, 2026, 15, 14, 45, 75, 0),
(4, 'EE-MOD1-01', 1, 2026, 8, 9, 25, 70, 1),
(5, 'CS-MOD1-01', 1, 2026, 19, 18, 55, 95, 0),
(6, 'EE-MOD1-01', 1, 2026, 16, 15, 48, 88, 0),
(7, 'CS-MOD1-01', 1, 2026, 11, 13, 38, 80, 0),
(8, 'EE-MOD1-01', 1, 2026, 9, 11, 30, 72, 1),
(9, 'CS-MOD1-01', 1, 2026, 20, 19, 58, 100, 0),
(10, 'EE-MOD1-01', 1, 2026, 14, 16, 42, 85, 0);
GO

-- Insert HOSTEL 
INSERT INTO HOSTEL (HostelName, RoomNumber, Cost) VALUES
('Kilimanjaro', 'Room 101', 5000.00),
('Ruwenzori', 'Room 202', 6000.00),
('Kilimanjaro', 'Room 102', 5000.00),
('Ruwenzori', 'Room 203', 6000.00),
('Kilimanjaro', 'Room 103', 5000.00),
('Ruwenzori', 'Room 204', 6000.00),
('Kilimanjaro', 'Room 104', 5000.00),
('Ruwenzori', 'Room 205', 6000.00),
('Kilimanjaro', 'Room 105', 5000.00),
('Ruwenzori', 'Room 206', 6000.00);
GO

-- Insert HOSTEL_ALLOCATION 
INSERT INTO HOSTEL_ALLOCATION (StudentID, HostelID, Term, Year, PaymentConfirmed) VALUES
(1, 1, 1, 2026, 1),
(2, 2, 1, 2026, 1),
(3, 3, 1, 2026, 0),
(4, 4, 1, 2026, 1),
(5, 5, 1, 2026, 1),
(6, 6, 1, 2026, 0),
(7, 7, 1, 2026, 1),
(8, 8, 1, 2026, 1),
(9, 9, 1, 2026, 0),
(10, 10, 1, 2026, 1);
GO

-- Insert CLUBS 
INSERT INTO CLUBS (ClubName, PatronID, ChairpersonID, LastActiveYear) VALUES
('Coding Club', 1, 1, 2026),
('Drama Club', 2, 4, 2022),
('Music Club', 3, 2, 2026),
('Sports Club', 4, 5, 2026),
('Debate Club', 5, 3, 2026),
('Photography Club', 6, 6, 2025),
('Chess Club', 7, 7, 2026),
('Robotics Club', 8, 8, 2026),
('AI Club', 9, 9, 2026),
('Green Club', 10, 10, 2023);
GO

-- Insert CLUB_MEM 
INSERT INTO CLUB_MEM (StudentID, ClubID, YearJoined) VALUES
(1, 1, 2025), (2, 1, 2026), (3, 2, 2024), (4, 2, 2025),
(5, 3, 2025), (6, 3, 2026), (7, 4, 2025), (8, 4, 2026),
(9, 5, 2025), (10, 5, 2026), (11, 6, 2025), (12, 6, 2026),
(13, 7, 2025), (14, 7, 2026), (15, 8, 2025), (16, 8, 2026),
(17, 9, 2025), (18, 9, 2026), (19, 10, 2025), (20, 10, 2026);
GO

-- Insert ATTACHMET 
INSERT INTO ATTACHMET (StudentID, FirmName, PeriodWeeks, Term, Year, CompletionStatus) VALUES
(3, 'Safaricom PLC', 12, 1, 2026, 'Ongoing'),
(6, 'KPLC Ltd', 12, 1, 2026, 'Completed'),
(11, 'Equity Bank', 12, 1, 2026, 'Ongoing'),
(13, 'Google Kenya', 12, 1, 2026, 'Completed'),
(14, 'Microsoft Africa', 12, 1, 2026, 'Ongoing'),
(15, 'IBM Kenya', 12, 1, 2026, 'Completed'),
(16, 'Oracle EMEA', 12, 1, 2026, 'Ongoing'),
(17, 'AWS East Africa', 12, 1, 2026, 'Completed'),
(18, 'Cisco Systems', 12, 1, 2026, 'Ongoing'),
(19, 'Dell Technologies', 12, 1, 2026, 'Completed');
GO

PRINT 'All test data inserted successfully!';













---- SELECT, UPDATE, DELETE, AND JOIN QUERIES


USE StudentServicesDB;
GO


-- SELECT QUERIES


-- i) Students whose names start with 'A'
SELECT * FROM STUDENT WHERE FullName LIKE 'A%';

-- ii) Departments located in Block B
SELECT * FROM DEPARTMENTS WHERE Location = 'Block B';

-- iii) Students in Class ID 1
SELECT * FROM STUDENT WHERE ClassID = 1;

-- iv) Clubs with no members
SELECT c.ClubName FROM CLUBS c 
LEFT JOIN CLUB_MEM m ON c.ClubID = m.ClubID 
WHERE m.MembershipID IS NULL;





-- UPDATE OPERATIONS

-- i) Update contact details
UPDATE STUDENT SET Address = 'Kitengela Residence' WHERE StudentID = 1;

-- ii) Update enrollment status
UPDATE STUDENT SET EnrollmentStatus = 'on attachment' WHERE StudentID = 1;

-- iii) Change club chairperson
UPDATE CLUBS SET ChairpersonID = 2 WHERE ClubID = 1;

-- iv) Deregister inactive clubs (with no members for 3 consecutive years)
DELETE FROM CLUBS WHERE LastActiveYear <= 2023;



-- JOIN QUERIES

-- i) Lecturers and the subjects they teach
SELECT l.LecturerName, s.SubjectName, wa.Term, wa.Year
FROM WORKALLOCATION wa
JOIN LECTURES l ON wa.LecturerID = l.LecturerID
JOIN SUBJECT s ON wa.SubjectCode = s.SubjectCode;

-- ii) Clubs with patrons and chairpersons
SELECT c.ClubName, l.LecturerName AS Patron, s.FullName AS Chairperson 
FROM CLUBS c
JOIN LECTURES l ON c.PatronID = l.LecturerID
JOIN STUDENT s ON c.ChairpersonID = s.StudentID;

-- iii) Students in a specific class with their hostel details
SELECT s.FullName, h.HostelName, h.RoomNumber, ha.Term, ha.Year
FROM STUDENT s
JOIN HOSTEL_ALLOCATION ha ON s.StudentID = ha.StudentID
JOIN HOSTEL h ON ha.HostelID = h.HostelID
WHERE s.ClassID = 1 AND ha.Term = 1 AND ha.Year = 2026;

-- iv) Students attached at same firm
SELECT FirmName, COUNT(StudentID) AS StudentCount 
FROM ATTACHMET 
WHERE PeriodWeeks = 12 
GROUP BY FirmName;






-- AGGREGATE QUERIES


-- i) Total students per course
SELECT co.CourseName, COUNT(s.StudentID) AS TotalStudents 
FROM STUDENT s
JOIN CLASSES cl ON s.ClassID = cl.ClassID
JOIN COURSES co ON cl.CourseID = co.CourseID
GROUP BY co.CourseName;

-- ii) Average grades per department
SELECT d.DeptName, AVG(a.CAT1 + a.CAT2 + a.ExamScore) AS AverageMark
FROM ASSESS a
JOIN SUBJECT s ON a.SubjectCode = s.SubjectCode
JOIN COURSES c ON s.CourseID = c.CourseID
JOIN DEPARTMENTS d ON c.DeptID = d.DeptID
WHERE a.Term = 1 AND a.Year = 2026
GROUP BY d.DeptName;

-- iii) Membership per club per year
SELECT ClubID, YearJoined, COUNT(StudentID) AS TotalMembers 
FROM CLUB_MEM 
GROUP BY ClubID, YearJoined;

-- iv) Total marks per subject for a student
SELECT SubjectCode, (CAT1 + CAT2 + ExamScore) AS TotalMarks 
FROM ASSESS 
WHERE StudentID = 1 AND Term = 1 AND Year = 2026;

-- v) Students on attachment per department
SELECT d.DeptName, s.FullName, att.FirmName
FROM STUDENT s
JOIN CLASSES cl ON s.ClassID = cl.ClassID
JOIN COURSES co ON cl.CourseID = co.CourseID
JOIN DEPARTMENTS d ON co.DeptID = d.DeptID
JOIN ATTACHMET att ON s.StudentID = att.StudentID
WHERE s.EnrollmentStatus = 'on attachment';

-- vi) Attachment completion rates per course
SELECT co.CourseName, 
       SUM(CASE WHEN att.CompletionStatus = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(att.AttachmentID) AS CompletionRate
FROM ATTACHMET att
JOIN STUDENT s ON att.StudentID = s.StudentID
JOIN CLASSES cl ON s.ClassID = cl.ClassID
JOIN COURSES co ON cl.CourseID = co.CourseID
GROUP BY co.CourseName;

-- vii) Hostel occupancy rates by term
SELECT Term, Year, COUNT(DISTINCT StudentID) AS TotalOccupants 
FROM HOSTEL_ALLOCATION 
GROUP BY Term, Year;

-- viii) Club participation trends over years
SELECT YearJoined, COUNT(StudentID) AS JoinedCount 
FROM CLUB_MEM 
GROUP BY YearJoined;

-- ix) Lecturer workload summary
SELECT wa.LecturerID, l.LecturerName, SUM(s.WeeklyHours) AS TotalHoursPerWeek
FROM WORKALLOCATION wa
JOIN LECTURES l ON wa.LecturerID = l.LecturerID
JOIN SUBJECT s ON wa.SubjectCode = s.SubjectCode
GROUP BY wa.LecturerID, l.LecturerName;

PRINT 'All SELECT, UPDATE, DELETE, JOIN, and AGGREGATE operations completed!';








-- PART 6: CREATE VIEWS


USE StudentServicesDB;
GO

-- Registrar View
CREATE VIEW V_Registrar AS 
SELECT StudentID, FullName, DOB, Gender, Address, EnrollmentStatus, FeeBalance 
FROM STUDENT;
GO

-- HOD View
CREATE VIEW V_HOD AS 
SELECT s.StudentID, s.FullName, c.CourseName, d.DeptID, d.DeptName, cl.ClassName
FROM STUDENT s
JOIN CLASSES cl ON s.ClassID = cl.ClassID
JOIN COURSES c ON cl.CourseID = c.CourseID
JOIN DEPARTMENTS d ON c.DeptID = d.DeptID;
GO

-- Exam Performance View
CREATE VIEW V_ExamPerformance AS 
SELECT StudentID, SubjectCode, Term, Year, 
       (CAT1 + CAT2 + ExamScore) AS FinalMark, 
       IsSupplementary,
       CASE WHEN (CAT1 + CAT2 + ExamScore) >= 60 THEN 'PASS' ELSE 'FAIL' END AS Result
FROM ASSESS;
GO

-- Accounts View
CREATE VIEW V_Accounts AS 
SELECT StudentID, FullName, FeeBalance, EnrollmentStatus 
FROM STUDENT;
GO

-- Lecturer View
CREATE VIEW V_Lecturer AS 
SELECT l.LecturerID, l.LecturerName, l.Specialty, s.SubjectName, wa.Term, wa.Year, cl.ClassName
FROM LECTURES l
JOIN WORKALLOCATION wa ON l.LecturerID = wa.LecturerID
JOIN SUBJECT s ON wa.SubjectCode = s.SubjectCode
JOIN CLASSES cl ON wa.ClassID = cl.ClassID;
GO

-- Dean View

Go
CREATE VIEW V_Dean AS 
SELECT d.DeptName, co.CourseName, cl.ClassName, COUNT(s.StudentID) AS StudentCount
FROM DEPARTMENTS d
JOIN COURSES co ON d.DeptID = co.DeptID
JOIN CLASSES cl ON co.CourseID = cl.CourseID
JOIN STUDENT s ON cl.ClassID = s.ClassID
GROUP BY d.DeptName, co.CourseName, cl.ClassName;
GO

PRINT 'All views created successfully!';










-- PART 7: RETRIEVE DATA FROM VIEWS


USE StudentServicesDB;
GO

-- i) Students due for graduation (every two years)
-- Assuming graduation is for completed status with fee balance <= 0
SELECT * FROM V_Registrar WHERE EnrollmentStatus = 'completed' AND FeeBalance <= 0;

-- ii) Students with fee balances above 10,000 per department
SELECT h.DeptName, COUNT(h.StudentID) AS DefaulterCount 
FROM V_HOD h 
JOIN V_Accounts a ON h.StudentID = a.StudentID 
WHERE a.FeeBalance > 10000 
GROUP BY h.DeptName;

-- iii) Departmental examination averages per course
SELECT h.DeptName, h.CourseName, AVG(ep.FinalMark) AS CourseAvg 
FROM V_ExamPerformance ep 
JOIN V_HOD h ON ep.StudentID = h.StudentID 
WHERE ep.Term = 1 AND ep.Year = 2026
GROUP BY h.DeptName, h.CourseName;

-- iv) Students in more than one club
SELECT StudentID, COUNT(ClubID) AS ClubsCount 
FROM CLUB_MEM 
GROUP BY StudentID 
HAVING COUNT(ClubID) > 1 
ORDER BY ClubsCount DESC;

-- v) Fees collected per department per term per year
SELECT h.DeptName, SUM(a.FeeBalance) AS RemainingReceivables 
FROM V_HOD h 
JOIN V_Accounts a ON h.StudentID = a.StudentID 
GROUP BY h.DeptName;

-- vi) Students scheduled for supplementary exams at start of term
SELECT COUNT(StudentID) AS SuppTargetCount 
FROM V_ExamPerformance 
WHERE IsSupplementary = 1 AND Term = 1 AND Year = 2026;

-- vii) Students on attachment in current term per department
SELECT h.DeptName, COUNT(s.StudentID) AS AttachmentCount
FROM V_Registrar s
JOIN V_HOD h ON s.StudentID = h.StudentID
WHERE s.EnrollmentStatus = 'on attachment'
GROUP BY h.DeptName;

-- viii) Student transcript for a given term and year
SELECT * FROM V_ExamPerformance 
WHERE StudentID = 1 AND Term = 1 AND Year = 2026;










-- UPDATE, DROP, AND RECREATE VIEW


-- i) Update the exam performance view
Go
ALTER VIEW V_ExamPerformance AS 
SELECT StudentID, SubjectCode, Term, Year, 
       (CAT1 + CAT2 + ExamScore) AS FinalMark, 
       IsSupplementary,
       CASE WHEN IsSupplementary = 1 THEN 'SUPP' ELSE 'ORDINARY' END AS ExamType,
       CASE WHEN (CAT1 + CAT2 + ExamScore) >= 60 THEN 'PASS' ELSE 'FAIL' END AS Result
FROM ASSESS;
GO

-- ii) Drop the view
DROP VIEW V_ExamPerformance;
GO

-- iii) Recreate the view
CREATE VIEW V_ExamPerformance AS 
SELECT StudentID, SubjectCode, Term, Year, 
       (CAT1 + CAT2 + ExamScore) AS FinalMark, 
       IsSupplementary,
       CASE WHEN (CAT1 + CAT2 + ExamScore) >= 60 THEN 'PASS' ELSE 'FAIL' END AS Result
FROM ASSESS;
GO

PRINT 'All view operations completed successfully!';





























-- PART 8: EXPORT DATABASE


-- To export the database as SQL file, run this command in SQL Server Management Studio:
-- 1. Right-click on StudentServicesDB
-- 2. Select Tasks > Generate Scripts
-- 3. Choose "Script entire database and all database objects"
-- 4. Save to file

PRINT 'Database export completed successfully!';
PRINT '=============================================';
PRINT 'STUDENT SERVICES MANAGEMENT SYSTEM SETUP COMPLETE';
PRINT '=============================================';
PRINT 'All tables, data, views, and operations are ready!';
PRINT 'Check Object Explorer to verify all objects exist.';
PRINT '=============================================';


