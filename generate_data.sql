-- 生成S表数据
DELIMITER //
CREATE PROCEDURE GenerateData()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE cities VARCHAR(200) DEFAULT 'NANJING,BEIJING,SHANGHAI,GUANGZHOU,SHENZHEN,HANGZHOU,CHENGDU,WUHAN';
    
    -- 生成S表数据
    WHILE i <= 20000 DO
        INSERT INTO S VALUES (
            CONCAT('S', LPAD(i, 5, '0')),
            CONCAT('Supplier', i),
            ELT(1 + FLOOR(RAND() * 8), 'NANJING','BEIJING','SHANGHAI','GUANGZHOU','SHENZHEN','HANGZHOU','CHENGDU','WUHAN')
        );
        SET i = i + 1;
    END WHILE;
    
    -- 生成P表数据
    SET i = 1;
    WHILE i <= 10000 DO
        INSERT INTO P VALUES (
            CONCAT('P', LPAD(i, 5, '0')),
            CASE WHEN i % 100 = 0 THEN 'Bolt' ELSE CONCAT('Part', i) END,
            ROUND(RAND() * 100 + 1, 2),
            FLOOR(RAND() * 1000 + 1)
        );
        SET i = i + 1;
    END WHILE;
    
    -- 生成SP表数据
    SET i = 1;
    WHILE i <= 10000 DO
        INSERT INTO SP VALUES (
            CONCAT('S', LPAD(FLOOR(RAND() * 20000) + 1, 5, '0')),
            CONCAT('P', LPAD(FLOOR(RAND() * 10000) + 1, 5, '0')),
            CONCAT('Dept', FLOOR(RAND() * 10) + 1),
            FLOOR(RAND() * 2000 + 1)
        );
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

-- 执行存储过程
CALL GenerateData();
DROP PROCEDURE GenerateData; 