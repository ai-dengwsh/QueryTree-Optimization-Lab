-- 创建基础表
DROP TABLE IF EXISTS MV_BOLT_SUPPLIERS;
DROP TABLE IF EXISTS SP_PARTITIONED;
DROP TABLE IF EXISTS SP;
DROP TABLE IF EXISTS P;
DROP TABLE IF EXISTS S;

CREATE TABLE S (
    Snum VARCHAR(10) PRIMARY KEY,
    Sname VARCHAR(50),
    City VARCHAR(50)
);

CREATE TABLE P (
    Pnum VARCHAR(10) PRIMARY KEY,
    Pname VARCHAR(50),
    Weight DECIMAL(10,2),
    Size INT
);

CREATE TABLE SP (
    Snum VARCHAR(10),
    Pnum VARCHAR(10),
    Dept VARCHAR(50),
    Quan INT,
    PRIMARY KEY (Snum, Pnum)
);

-- 创建最优复合索引
CREATE INDEX idx_s_city_snum_sname ON S(City, Snum, Sname);
CREATE INDEX idx_p_pname_pnum ON P(Pname, Pnum);
CREATE INDEX idx_sp_composite ON SP(Pnum, Snum, Quan);

-- 创建分区表
CREATE TABLE SP_PARTITIONED (
    Snum VARCHAR(10),
    Pnum VARCHAR(10),
    Dept VARCHAR(50),
    Quan INT,
    PRIMARY KEY (Snum, Pnum, Quan)
) PARTITION BY RANGE(Quan) (
    PARTITION p0 VALUES LESS THAN (500),
    PARTITION p1 VALUES LESS THAN (1000),
    PARTITION p2 VALUES LESS THAN (1500),
    PARTITION p3 VALUES LESS THAN (2000),
    PARTITION p4 VALUES LESS THAN MAXVALUE
);

-- 创建物化视图表
CREATE TABLE MV_BOLT_SUPPLIERS (
    Snum VARCHAR(10),
    Sname VARCHAR(50),
    City VARCHAR(50),
    PRIMARY KEY (Snum),
    INDEX idx_mv_city (City)
);

-- 设置性能相关参数
SET SESSION bulk_insert_buffer_size = 536870912; -- 512MB
SET SESSION unique_checks = 0;
SET SESSION foreign_key_checks = 0;
SET SESSION autocommit = 0;

-- 创建存储过程生成数据
DELIMITER //

CREATE PROCEDURE GenerateSuppliers()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE city_val VARCHAR(50);
    
    WHILE i <= 2000000 DO
        SET city_val = CASE MOD(i, 8)
            WHEN 0 THEN 'NANJING'
            WHEN 1 THEN 'BEIJING'
            WHEN 2 THEN 'SHANGHAI'
            WHEN 3 THEN 'GUANGZHOU'
            WHEN 4 THEN 'SHENZHEN'
            WHEN 5 THEN 'HANGZHOU'
            WHEN 6 THEN 'CHENGDU'
            ELSE 'WUHAN'
        END;
        
        INSERT INTO S VALUES (
            CONCAT('S', LPAD(i, 7, '0')),
            CONCAT('Supplier', i),
            city_val
        );
        
        IF MOD(i, 10000) = 0 THEN
            COMMIT;
            SELECT CONCAT('已生成 ', i, ' 条供应商数据') AS Progress;
        END IF;
        SET i = i + 1;
    END WHILE;
    COMMIT;
END //

CREATE PROCEDURE GenerateParts()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE pname_val VARCHAR(50);
    
    WHILE i <= 1000000 DO
        IF MOD(i, 100) = 0 THEN
            SET pname_val = 'Bolt';
        ELSE
            SET pname_val = CONCAT('Part', i);
        END IF;
        
        INSERT INTO P VALUES (
            CONCAT('P', LPAD(i, 7, '0')),
            pname_val,
            MOD(i, 100) + 1,
            MOD(i, 1000) + 1
        );
        
        IF MOD(i, 10000) = 0 THEN
            COMMIT;
            SELECT CONCAT('已生成 ', i, ' 条零件数据') AS Progress;
        END IF;
        SET i = i + 1;
    END WHILE;
    COMMIT;
END //

CREATE PROCEDURE GenerateSupplyRelations()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE snum_val, pnum_val VARCHAR(10);
    DECLARE dept_val VARCHAR(50);
    DECLARE quan_val INT;
    
    WHILE i <= 20000000 DO
        SET snum_val = CONCAT('S', LPAD(MOD(i, 2000000) + 1, 7, '0'));
        SET pnum_val = CONCAT('P', LPAD(MOD(i, 1000000) + 1, 7, '0'));
        SET dept_val = CONCAT('Dept', MOD(i, 20) + 1);
        SET quan_val = MOD(i, 3000) + 1;
        
        INSERT INTO SP VALUES (snum_val, pnum_val, dept_val, quan_val);
        
        IF MOD(i, 10000) = 0 THEN
            COMMIT;
            SELECT CONCAT('已生成 ', i, ' 条供应关系数据') AS Progress;
        END IF;
        SET i = i + 1;
    END WHILE;
    COMMIT;
END //

DELIMITER ;

-- 执行数据生成
CALL GenerateSuppliers();
CALL GenerateParts();
CALL GenerateSupplyRelations();

-- 清理存储过程
DROP PROCEDURE GenerateSuppliers;
DROP PROCEDURE GenerateParts;
DROP PROCEDURE GenerateSupplyRelations;

-- 将数据导入分区表
INSERT INTO SP_PARTITIONED SELECT * FROM SP;
COMMIT;
SELECT '分区表数据导入完成' AS Progress;

-- 重建物化视图
INSERT INTO MV_BOLT_SUPPLIERS
SELECT DISTINCT S.Snum, S.Sname, S.City
FROM S 
INNER JOIN SP_PARTITIONED SP ON S.Snum = SP.Snum
INNER JOIN P ON SP.Pnum = P.Pnum
WHERE P.Pname = 'Bolt' AND SP.Quan > 1000;

COMMIT;
SELECT '物化视图重建完成' AS Progress;

-- 恢复性能相关参数
SET SESSION unique_checks = 1;
SET SESSION foreign_key_checks = 1;
SET SESSION autocommit = 1;

-- 性能测试
SET profiling = 1;

-- 测试原始查询
SELECT Sname
FROM S, SP, P
WHERE S.Snum = SP.Snum
AND SP.Pnum = P.Pnum
AND S.City = 'NANJING'
AND P.Pname = 'Bolt'
AND SP.Quan > 1000;

-- 测试物化视图查询
SELECT Sname
FROM MV_BOLT_SUPPLIERS
WHERE City = 'NANJING';

-- 测试优化查询（不使用物化视图）
SELECT /*+ NO_MERGE(filtered_sp) */ DISTINCT S.Sname
FROM S FORCE INDEX (idx_s_city_snum_sname)
INNER JOIN (
    SELECT SP.Snum
    FROM SP_PARTITIONED PARTITION (p2,p3,p4) SP
    INNER JOIN P FORCE INDEX (idx_p_pname_pnum)
        ON SP.Pnum = P.Pnum
    WHERE P.Pname = 'Bolt'
) filtered_sp ON S.Snum = filtered_sp.Snum
WHERE S.City = 'NANJING';

-- 查看性能分析结果
SHOW PROFILES;

-- 显示数据量统计
SELECT 'S表记录数' as metric, COUNT(*) as value FROM S
UNION ALL
SELECT 'P表记录数', COUNT(*) FROM P
UNION ALL
SELECT 'SP表记录数', COUNT(*) FROM SP
UNION ALL
SELECT 'SP分区表记录数', COUNT(*) FROM SP_PARTITIONED
UNION ALL
SELECT 'MV_BOLT_SUPPLIERS记录数', COUNT(*) FROM MV_BOLT_SUPPLIERS; 