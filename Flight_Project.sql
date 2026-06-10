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

SET FOREIGN_KEY_CHECKS = 1; -- 다시 켜기

-- 스케줄 정보  대량데이터여서 wizard 기능 사용?? Table Data Import Wizard 에러 -> LOAD DATA INFILE사용 
USE Flight_Project;
select * from Bookings;
--  Table data import wizard 사용하여 대용량 데이터 넣음

-- booking table 데이터 잘 들어갔는지 체크
SELECT COUNT(*) AS total_rows FROM Bookings;
SELECT * FROM Bookings LIMIT 10;

-- Analysis 1
-- 좌석 등급 분포 확인
-- 이코노미, 프레스티지 등 좌석 등급별로 승객이 어떻게 분포되어 있는지 확인하여 매출액을 추정할 때 핵심 데이터가 될 수 있다. 
-- 분석 포인트: 프레스티지나 비즈니스석 비중이 높다면 해당 노선은 '수익성이 높은 알짜 노선'임을 증명할 수 있다
SELECT Seat_Class, COUNT(*) AS count, 
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Bookings), 1) AS percentage
FROM Bookings
GROUP BY Seat_Class;

-- Analysis 1+
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

-- Analysis 2
-- 요일별 예약 현황 분석
-- 어느 요일에 승객이 가장 많이 몰리는지 알아본 후 항공사 입장에서 증편을 하거나 이벤트를 준비할 수 있도록 준비 
USE Flight_Project;
SELECT Day, COUNT(*) AS passenger_count
FROM Bookings
GROUP BY Day
ORDER BY FIELD(Day,'월','화','수','목','금','토','일');


-- 인기 항공기 모델 (및 노선 파악)
-- ppt자료에는 없는 쿼리문임. 
SELECT Aircraft_Model, COUNT(*) AS total_passengers
FROM Bookings
GROUP BY Aircraft_Model
ORDER BY total_passengers DESC;

-- Analysis 3
-- 어떤 승객이 몇 시에 출발하여 몇 시에 도착하는 스케줄을 이용하며, 그 비행기 기종의 스펙은 무엇인가?
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

-- Analysis 3+
-- 두 테이블을 합치는 JOIN 쿼리. 편명과 요일 join
-- Flight_Number와 Day가 두 테이블에 공통으로 들어있으므로, 이 두 가지를 기준으로 연결하면 정확한 매칭이 됩니다.
-- 최종 탑승객 리스트 도출
-- 요일순, 같은 요일 안에서는 시간순으로 정렬
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

-- ppt에는 없지만 따로 분석해본 쿼리문
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

-- Analysis 4
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


-- Analysis 5
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



-- Analysis 6
-- 도착 시간대별 승객 밀집도 (공항 인력 배치용)
-- 홍콩 공항에 승객이 몰리는 시간대를 분석하여 현지 인력(체크인 카운터, 수하물팀) 배치를 제안하는 데이터
-- 야간 도착 승객이 많다면 공항 연계 셔틀버스를 증편하거나 심야 카운터 운영이 필요하다는 근거가 됩니다
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



USE Flight_Project 
-- Analysis 7
-- 스토어드 프로시저 사용
-- 가설: 항공사는 특정 노선이나 기종의 실적을 단발성 쿼리가 아닌, 정기적인 '수익성 리포트' 형태로 임원진에게 보고해야 합니다. 매번 긴 join 쿼리를 입력하는 대신, 기종 이름을 입력하면 해당 기종의 총 승객 수, 총 매출, 평균 탑승률의 한눈에 뽑아주는 자동화 프로시저 필요.
DROP PROCEDURE IF EXISTS GetAircraftPerformanceReport;
DELIMITER //
-- 외부에서 받아올 기종 이름 -> 입력 매개변수
CREATE PROCEDURE GetAircraftPerformanceReport(
    IN p_model_name VARCHAR(20)
)
BEGIN
    SELECT 
        A.model_name AS aircraft_model,
        COUNT(B.booking_id) AS total_passengers,
        -- 프레스티지와 이코노미의 단가 계산 -> 실시간 총 매출액 집계
        SUM(CASE WHEN B.Seat_Class = 'Prestige' THEN A.price_prestige ELSE A.price_economy END) AS total_revenue_krw,
        -- 탑승률 계산: 총 승객 수 /. 비행기 좌석 수 * 운항 횟수)
        ROUND((COUNT(B.booking_id) / (A.total_seats * COUNT(DISTINCT S.flight_number, S.day_of_week))) * 100, 1) AS avg_load_factor_percent
    FROM Aircraft A
    JOIN Schedules S ON A.model_name = S.model_name
    JOIN Bookings B ON S.flight_number = B.Flight_Number AND S.day_of_week = B.Day
    WHERE A.model_name = p_model_name -- 입력받은 기종 데이터만 필터링
    GROUP BY A.model_name, A.total_seats;
END //

DELIMITER ;
-- CALL은 결과 리포트를 보고 싶을때 사용
CALL GetAircraftPerformanceReport('A350-900');
CALL GetAircraftPerformanceReport('A330-300');
CALL GetAircraftPerformanceReport('A321-neo');
-- show create procefure은 짠 코드를 다시 확인할때 사용
SHOW create procedure GetAircraftPerfformanceReport;

-- Analysis 8
-- 스토어드 함수
-- 항공사 정산 시스템에서는 승객이 예약한 좌석 등급(Prestige 또는 Economy)에 따라 티켓 가격을 다르게 부과해야 합니다. 매번 SELECT문을 쓸 때마다 CASE WHEN으로 가격을 일일이 지정하는 것은 비효율적이며 계산 실수가 날 수 있습니다.
-- 승객의 좌석 등급과 투입된 기종 이름을 입력하면, Aircraft 테이블의 단가 정보를 자동으로 조회하여 최종 결제 금액을 원화(KRW)로 딱 반환해 주는 함수
DROP FUNCTION IF EXISTS CalculateTicketPrice;
DELIMITER //

CREATE FUNCTION CalculateTicketPrice(
    p_aircraft_model VARCHAR(20),
    p_seat_class VARCHAR(15)
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_final_price INT DEFAULT 0;
    
    -- 입력받은 기종과 좌석 등급에 따라 Aircraft 테이블에서 알맞은 단가를 가져옴
    IF p_seat_class = 'Prestige' THEN
        SELECT price_prestige INTO v_final_price
        FROM Aircraft
        WHERE model_name = p_aircraft_model;
    ELSE
        SELECT price_economy INTO v_final_price
        FROM Aircraft
        WHERE model_name = p_aircraft_model;
    END IF;
    
    -- 최종 계산된 금액을 반환
    RETURN v_final_price;
END //
DELIMITER ;

-- 스토어드 함수 출력
SELECT 
    booking_id AS 예약번호,
    Passenger_Name AS 승객명,
    Aircraft_Model AS 운항기종,
    Seat_Class AS 좌석등급,
    -- 우리가 만든 함수 호출 (기종과 좌석등급을 던져주면 금액을 계산해 줌)
    CalculateTicketPrice(Aircraft_Model, Seat_Class) AS 결제금액_KRW
FROM Bookings;





-- 트리거 : 특정 테이블에 데이터가 추가, 수정, 삭제되는 이벤트 발생시, 데이터베이스가 스스로 감지하여 자동으로 실행하는 감시 프로그램
-- 가설(데이터 무결성 및 시스템 제어): 항공기 기종마다 제한된 총 좌석수(total_seats)가 있습니다. 만약 Python Faker 프로그램이나 예약 시스템의 오류로 인해 기종의 남은 좌석을 초과하여 예약을 시도하는 경우, 이를 원천 차단하는 실시간 트리거가 필요
-- 오버부킹(좌석 수 초과 예약) 방지. 좌석이 182석인데 183번째 예약이 들어온다면 차단함.
DROP TRIGGER IF EXISTS Before_Booking_Insert;

DELIMITER //

CREATE TRIGGER Before_Booking_Insert
BEFORE INSERT ON Bookings -- Bookings 테이블에 새로운 예약이 들어가기 직전에 막음
FOR EACH ROW -- 새로운 데이터가 들어오는 모든 행에 대해 각각 실행

BEGIN
    DECLARE v_current_bookings INT;
    DECLARE v_max_seats INT;
    
    -- 1. 해당 편명/요일의 현재 예약 완료된 좌석 수 계산
    SELECT COUNT(*) INTO v_current_bookings
    FROM Bookings
    WHERE Flight_Number = NEW.Flight_Number AND Day = NEW.Day;
    
    -- 2. 스케줄 테이블을 join하여 해당 비행기의 최대 허용 좌석 수 조회
    SELECT A.total_seats INTO v_max_seats
    FROM Aircraft A
    JOIN Schedules S ON A.model_name = S.model_name
    WHERE S.flight_number = NEW.Flight_Number AND S.day_of_week = NEW.Day
    LIMIT 1;
    
    -- 3. 만약 현재 예약자 수가 최대 좌석수보다 같거나 많다면 승인 차단
    IF v_current_bookings >= v_max_seats THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Cannot exceed maximum aircraft seat capacity for this flight.';
    END IF;
END //

DELIMITER ;

-- Analysis 9
-- 커서 
-- 요일별 기종 효율성 배치 가설
DROP PROCEDURE IF EXISTS AnalyzeRouteOverbookingRisk;

DELIMITER //

CREATE PROCEDURE AnalyzeRouteOverbookingRisk()
BEGIN
    -- 커서에서 한 줄씩 읽어와서 임시로 담을 변수 선언
    DECLARE v_day VARCHAR(10);
    DECLARE v_model_name VARCHAR(20);
    DECLARE v_passengers INT;
    DECLARE v_total_seats INT;
    DECLARE v_load_factor DECIMAL(5,1);
    DECLARE v_risk_status VARCHAR(20);
    
    -- 커서가 데이터의 끝(마지막 행)에 도달했을 때 제어
    DECLARE v_done INT DEFAULT 0;
    
    -- 커서 선언 (요일별, 기종별 탑승률을 계산하는 쿼리)
    DECLARE flight_cursor CURSOR FOR
        SELECT 
            B.Day, 
            A.model_name,
            COUNT(B.booking_id) AS total_passengers,
            A.total_seats,
            ROUND((COUNT(B.booking_id) / A.total_seats) * 100, 1) AS load_factor
        FROM Bookings B
        JOIN Aircraft A ON B.Aircraft_Model = A.model_name
        GROUP BY B.Day, A.model_name, A.total_seats;
        
    -- 커서가 더 이상 읽을 데이터가 없음 -> v_done을 1로 변경
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    
    -- 분석 결과를 저장할 테이블 생성 (없으면 만들고 있으면 비우기)
    CREATE TABLE IF NOT EXISTS Risk_Analysis_Report (
        flight_day VARCHAR(10),
        aircraft_model VARCHAR(20),
        pax_count INT,
        seats_capacity INT,
        load_factor_percent DECIMAL(5,1),
        risk_level VARCHAR(20)
    );
    TRUNCATE TABLE Risk_Analysis_Report;
    
    -- 커서 오픈 (쿼리 실행, 결과셋 메모리 로드)
    OPEN flight_cursor;
    
    -- 반복문
    read_loop: LOOP
        -- 커서가 가리키는 현재 행의 데이터를 변수에 하나씩 대입
        FETCH flight_cursor INTO v_day, v_model_name, v_passengers, v_total_seats, v_load_factor;
        
        -- 더 이상 읽을 데이터가 x -> 루프 탈출
        IF v_done = 1 THEN
            LEAVE read_loop;
        END IF;
        
        -- 커서로 가져온 데이터를 바탕으로 조건 처리 (IF-ELSE )
        IF v_load_factor >= 95.0 THEN
            SET v_risk_status = 'Critical Warning';
        ELSEIF v_load_factor >= 80.0 THEN
            SET v_risk_status = 'Stable';
        ELSE
            SET v_risk_status = 'Underbooked';
        END IF;
        
        --  데이터를 결과 리포트 테이블에 삽입
        INSERT INTO Risk_Analysis_Report (flight_day, aircraft_model, pax_count, seats_capacity, load_factor_percent, risk_level)
        VALUES (v_day, v_model_name, v_passengers, v_total_seats, v_load_factor, v_risk_status);
        
    END LOOP; -- 루프 종료
    
    -- 커서 클로즈, 메모리 해제
    CLOSE flight_cursor;
    
    -- 최종 결과 출력
    SELECT * FROM Risk_Analysis_Report
    ORDER BY FIELD(flight_day, '월', '화', '수', '목', '금', '토', '일'), load_factor_percent DESC;

END //

DELIMITER ;

-- 커서 출력 
CALL AnalyzeRouteOverbookingRisk();


-- Analysis 5+
-- 제약조건 추가 

-- 1. Aircraft 테이블 제약조건 추가
-- 항공기 좌석 스펙 정합성 체크 (총 좌석수 = 프레스티지 + 이코노미)
ALTER TABLE Aircraft
ADD CONSTRAINT chk_seats_match 
CHECK (total_seats = Prestige + Economy);

-- 2. Schedules 테이블 제약조건 추가
-- 복합 기본키가 이미 설정되어 있지 않다면 설정하고, Aircraft 테이블과의 외래키(FK) 연결
-- (Schedules의 model_name은 Aircraft의 model_name에 존재하는 것만 입력 가능하도록 제한)
ALTER TABLE Schedules
ADD CONSTRAINT fk_schedules_aircraft
FOREIGN KEY (model_name) REFERENCES Aircraft(model_name)
ON UPDATE CASCADE ON DELETE RESTRICT;

-- 3. Bookings 테이블 제약조건 추가
-- 좌석 등급 입력 실수 방지 (오직 'Prestige'와 'Economy'만 입력 허용)
ALTER TABLE Bookings
ADD CONSTRAINT chk_valid_seat_class
CHECK (Seat_Class IN ('Prestige', 'Economy'));

-- 예약 테이블이 Schedules 테이블의 실제 존재하는 [편명 + 요일] 조합만 참조하도록 외래키 설정
-- ALTER TABLE Bookings
-- ADD CONSTRAINT fk_bookings_schedules
-- FOREIGN KEY (Flight_Number, Day) REFERENCES Schedules(flight_number, day_of_week)
-- ON UPDATE CASCADE ON DELETE RESTRICT;

-- Analysis 5+
-- 뷰 1. 종합 운항 실적 및 탑승률(Load Factor) 분석 뷰
-- 목적: 각 비행편이 몇 퍼센트나 채워져서 가고 있는지, 실시간 총매출과 연료 효율성을 한눈에 모니터링
CREATE OR REPLACE VIEW v_flight_performance_summary AS
SELECT 
    S.flight_number AS 편명,
    S.day_of_week AS 운항요일,
    A.model_name AS 투입기종,
    COUNT(B.booking_id) AS 현재승객수,
    A.total_seats AS 총좌석수,
    -- 탑승률(Load Factor) 계산
    ROUND((COUNT(B.booking_id) / A.total_seats) * 100, 1) AS 탑승률_퍼센트,
    -- 프레스티지/이코노미 가격을 적용한 비행편별 총 매출 계산
    SUM(CASE WHEN B.Seat_Class = 'Prestige' THEN A.price_prestige ELSE A.price_economy END) AS 총매출_KRW,
    -- 기종별 연료 소모량을 승객 수로 나눈 1인당 연료 소모량 (효율성 지표)
    ROUND(A.fuel / COUNT(B.booking_id), 2) AS 승객1인당_연료소모량
FROM Schedules S
JOIN Aircraft A ON S.model_name = A.model_name
LEFT JOIN Bookings B ON S.flight_number = B.Flight_Number AND S.day_of_week = B.Day
GROUP BY S.flight_number, S.day_of_week, A.model_name, A.total_seats, A.fuel;

SELECT * FROM v_flight_performance_summary;


