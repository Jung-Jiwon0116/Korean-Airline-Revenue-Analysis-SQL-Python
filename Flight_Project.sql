-- 프로젝트 만들기 
CREATE DATABASE Flight_Project;

Use Flight_Project;

SET FOREIGN_KEY_CHECKS = 0; -- 만약의 경우를 대비해 잠시 체크 해제

-- 기존 테이블이 있다면 삭제 (Error 1050 방지)
DROP TABLE IF EXISTS Bookings;
DROP TABLE IF EXISTS Schedules;
DROP TABLE IF EXISTS Aircraft;



-- 비행기 종류, 총좌석수, 프레스티지 좌석, 이코노미 좌석, 연료
CREATE TABLE Aircraft( model_name VARCHAR(20) PRIMARY KEY, total_seats INT, Prestige INT, Economy INT, fuel INT);

TRUNCATE TABLE Aircraft;

INSERT INTO Aircraft(model_name, total_seats, Prestige, Economy, fuel) VALUES
('A330-300', 276, 24, 252, 13900),
('A321-neo', 182, 8, 174, 18100),
('A350-900', 311, 28, 283, 15000);

-- 1. 가격 컬럼 추가
ALTER TABLE Aircraft ADD COLUMN price_prestige INT;
ALTER TABLE Aircraft ADD COLUMN price_economy INT;

-- 2. 이미지의 가격 데이터 업데이트
UPDATE Aircraft SET price_prestige = 1350000, price_economy = 450000 WHERE model_name = 'A330-300';
UPDATE Aircraft SET price_prestige = 1100000, price_economy = 380000 WHERE model_name = 'A321-neo';
UPDATE Aircraft SET price_prestige = 1550000, price_economy = 550000 WHERE model_name = 'A350-900';


-- 운항 스케줄 테이블 
CREATE TABLE Schedules(schedule_id INT AUTO_INCREMENT PRIMARY KEY, day_of_week varchar(5), flight_number varchar(10), 
departure_time TIME, arrival_time TIME, model_name varchar(20), FOREIGN KEY(model_name) REFERENCES Aircraft(model_name) );


-- 1. 일단 테이블 비우기 (중복 방지)
TRUNCATE TABLE Schedules;


-- 2. 1번부터 21번까지 한꺼번에 밀어넣기
INSERT INTO Schedules (schedule_id, day_of_week, flight_number, departure_time, arrival_time, model_name) VALUES
(1,'월','KE2001','08:05','10:50','A330-300'),
(2,'월','KE2005','13:25','16:20','A321-neo'),
(3,'월','KE2011','19:45','22:30','A350-900'),
(4,'화','KE2001','08:05','10:50','A330-300'),
(5,'화','KE2005','13:25','16:20','A321-neo'),
(6,'화','KE2011','19:45','22:30','A350-900'),
(7,'수','KE2001','08:05','10:50','A330-300'),
(8,'수','KE2005','13:25','16:20','A321-neo'),
(9,'수','KE2011','19:45','22:30','A350-900'),
(10,'목','KE2001','08:05','10:50','A330-300'),
(11,'목','KE2005','13:25','16:20','A321-neo'),
(12,'목','KE2011','19:45','22:30','A350-900'),
(13,'금','KE2001','08:05','10:50','A330-300'),
(14,'금','KE2005','13:25','16:20','A321-neo'),
(15,'금','KE2011','19:45','22:30','A350-900'),
(16,'토','KE2001','08:05','10:50','A330-300'),
(17,'토','KE2005','13:25','16:20','A321-neo'),
(18,'토','KE2011','19:45','22:30','A350-900'),
(19,'일','KE2001','08:05','10:50','A330-300'),
(20,'일','KE2005','13:25','16:20','A321-neo'),
(21,'일','KE2011','19:45','22:30','A350-900');

-- 예약 테이블 
CREATE TABLE Bookings(booking_id INT PRIMARY KEY, Day varchar(10), Flight_Number varchar(10), Departure_Time varchar(10), Aircraft_Model varchar(20), Passenger_Name varchar(50), Seat_Class varchar(20), Seat_Number varchar(10) );

-- 비행기 종류 
-- INSERT INTO Aircraft VALUES('A330-300', 276, 24, 252, 6000);
-- INSERT INTO Aircraft VALUES('A321-neo', 182, 8, 174, 3000);
-- INSERT INTO Aircraft VALUES('A350-900', 311, 28, 283, 6800);

SET FOREIGN_KEY_CHECKS = 1; -- 다시 켜기

-- 스케줄 정보  대량데이터여서 wizard 기능 사용?? Table Data Import Wizard 에러 -> LOAD DATA INFILE사용 
USE Flight_Project;
select * from Bookings;
-- SET GLOBAL local_infile = 1;

-- 기존 데이터 비우기 
-- TRUNCATE TABLE Bookings;

-- 데이터 로드 실행 
-- LOAD DATA LOCAL INFILE '/Users/jiwon/Desktop/Yonsei/3-1/database/Flight_Project/Flight_Project.sql'
-- INTO TABLE Bookings
-- CHARACTER SET utf8mb4
-- FIELDS TERMINATED BY ','
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS; 

--  Table data import wizard 사용

SELECT COUNT(*) AS total_rows FROM Bookings;
SELECT * FROM Bookings LIMIT 10;

-- 요일별 예약 현황 분석
-- 어느 요일에 승객이 가장 많이 몰리는지 알아본 후 항공사 입장에서 증편을 하거나 이벤트를 준비할 수 있도록 준비 
USE Flight_Project;
SELECT Day, COUNT(*) AS passenger_count
FROM Bookings
GROUP BY Day
ORDER BY FIELD(Day,'월','화','수','목','금','토','일');

-- 좌석 등급 분포 확인
-- 이코노미, 프레스티지 등 좌석 등급별로 승객이 어떻게 분포되어 있는지 확인하여 매출액을 추정할 때 핵심 데이터가 될 수 있다. 
-- 분석 포인트: 프레스티지나 비즈니스석 비중이 높다면 해당 노선은 '수익성이 높은 알짜 노선'임을 증명할 수 있다
SELECT Seat_Class, COUNT(*) AS count, 
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Bookings), 1) AS percentage
FROM Bookings
GROUP BY Seat_Class;


-- 요일별 그룹화 
SELECT 
    B.Day AS 요일,
    B.Seat_Class AS 좌석등급,
    COUNT(*) AS 예약인원,
    -- 요일별 전체 인원 대비 비중 (%)
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY B.Day), 1) AS 요일내_비중,
    -- 실제 기종별 가격을 적용한 총 매출 계산
    SUM(CASE 
        WHEN B.Seat_Class = 'Prestige' THEN A.price_prestige 
        ELSE A.price_economy 
    END) AS 총매출
FROM Bookings B
JOIN Aircraft A ON B.Aircraft_Model = A.model_name
GROUP BY B.Day, B.Seat_Class
ORDER BY 
    FIELD(B.Day, '월', '화', '수', '목', '금', '토', '일'), 
    총매출 DESC;






-- 인기 항공기 모델 (및 노선 파악)
SELECT Aircraft_Model, COUNT(*) AS total_passengers
FROM Bookings
GROUP BY Aircraft_Model
ORDER BY total_passengers DESC;


SELEct * from Schedules;
SELECT 
    B.Passenger_Name, 
    B.Flight_Number, 
    S.departure_time, 
    S.arrival_time, 
    A.model_name, 
    A.total_seats, 
    A.fuel
FROM Bookings B
JOIN Schedules S ON B.Flight_Number = S.flight_number AND B.Day = S.day_of_week
JOIN Aircraft A ON S.model_name = A.model_name;

-- 두 테이블을 합치는 JOIN 쿼리
-- Flight_Number와 Day가 두 테이블에 공통으로 들어있으므로, 이 두 가지를 기준으로 연결하면 정확한 매칭이 됩니다.
SELECT 
    B.Passenger_Name, 
    B.Flight_Number, 
    B.Day, 
    S.departure_time, 
    S.arrival_time, 
    B.Seat_Number,
    B.Seat_Class
FROM Bookings B
JOIN Schedules S 
    ON B.Flight_Number = S.flight_number 
    AND B.Day = S.day_of_week
ORDER BY B.Day, S.departure_time;

-- 좌석 등급별 도착 시간대 분포 -> 이를 통해, "프레스티지석 승객들은 주로 오전 비행기를 선호하는가?" 가설 검증 가능 
-- 프레스티지석 승객들의 시간대별 분포 확인
SELECT 
    S.departure_time, 
    COUNT(*) AS prestige_passenger_count
FROM Bookings B
JOIN Schedules S 
    ON B.Flight_Number = S.flight_number AND B.Day = S.day_of_week
WHERE B.Seat_Class = 'Prestige'
GROUP BY S.departure_time
ORDER BY S.departure_time;

-- 요일별 '황금 시간대' 및 탑승률(Load Factor) 분석
-- 가장 중요한 '비행기를 얼마나 채워서 장사했나'를 확인하는 쿼리입니다.
-- 탑승률이 90%가 넘으면 '황금 노선', 70% 미만이면 마케팅 대책이 필요한 노선으로 분류합니다.
SELECT 
    S.day_of_week AS 요일,
    S.flight_number AS 편명,
    S.departure_time AS 출발시간,
    COUNT(B.booking_id) AS 예약인원,
    A.total_seats AS 총좌석수,
    ROUND((COUNT(B.booking_id) / A.total_seats) * 100, 1) AS 탑승률
FROM Schedules S
LEFT JOIN Bookings B ON S.flight_number = B.Flight_Number AND S.day_of_week = B.Day
JOIN Aircraft A ON S.model_name = A.model_name
GROUP BY S.day_of_week, S.flight_number, S.departure_time, A.total_seats
ORDER BY FIELD(요일, '월', '화', '수', '목', '금', '토', '일'), 출발시간;

-- 좌석 등급별 수익 분석 쿼리
-- 이 가격 데이터를 사용해서, 각 비행 편당 실제 매출이 얼마인지 정확하게 계산할 수 있습니다.
SELECT 
    B.Flight_Number AS 편명,
    B.Day AS 요일,
    A.model_name AS 기종,
    -- 프레스티지 수익 계산
    SUM(CASE WHEN B.Seat_Class = 'Prestige' THEN A.price_prestige ELSE 0 END) AS prestige_revenue,
    -- 일반석 수익 계산
    SUM(CASE WHEN B.Seat_Class = 'Economy' THEN A.price_economy ELSE 0 END) AS economy_revenue,
    -- 총 수익
    SUM(CASE 
        WHEN B.Seat_Class = 'Prestige' THEN A.price_prestige 
        ELSE A.price_economy 
    END) AS total_revenue
FROM Bookings B
JOIN Aircraft A ON B.Aircraft_Model = A.model_name
GROUP BY B.Flight_Number, B.Day, A.model_name
ORDER BY total_revenue DESC;

-- 기종별 연료 효율성(연료비 vs 승객) 분석
-- 비행기 기종별로 승객 1명을 실어 나를 때 드는 연료량을 계산
-- 값이 낮을수록 연료 효율이 좋은 비행기입니다. 경영학적으로 '비용 절감' 리포트의 핵심 데이터가 됩니다.
SELECT 
    A.model_name AS 기종,
    COUNT(B.booking_id) AS 총승객수,
    A.fuel AS 총연료소모량,
    ROUND(A.fuel / COUNT(B.booking_id), 2) AS 승객1인당_연료량
FROM Aircraft A
JOIN Schedules S ON A.model_name = S.model_name
JOIN Bookings B ON S.flight_number = B.Flight_Number AND S.day_of_week = B.Day
GROUP BY A.model_name, A.fuel
ORDER BY 승객1인당_연료량 ASC;


-- 도착 시간대별 승객 밀집도 (공항 인력 배치용)
-- 홍콩 공항에 승객이 몰리는 시간대를 분석하여 현지 인력(체크인 카운터, 수하물팀) 배치를 제안하는 데이터
-- 야간 도착 승객이 많다면 공항 연계 셔틀버스를 증편하거나 심야 카운터 운영이 필요하다는 근거가 됩니다.
SELECT 
    S.arrival_time AS 도착시간,
    COUNT(B.booking_id) AS 도착예정_승객수,
    CASE 
        WHEN S.arrival_time < '12:00:00' THEN '오전'
        WHEN S.arrival_time < '18:00:00' THEN '오후'
        ELSE '야간'
    END AS 시간대구분
FROM Schedules S
JOIN Bookings B ON S.flight_number = B.Flight_Number AND S.day_of_week = B.Day
GROUP BY S.arrival_time
ORDER BY S.arrival_time;






