-- 删除外键约束（如果存在）
ALTER TABLE SP DROP FOREIGN KEY IF EXISTS sp_ibfk_1;
ALTER TABLE SP DROP FOREIGN KEY IF EXISTS sp_ibfk_2;

-- 创建最优复合索引
CREATE INDEX IF NOT EXISTS idx_s_city_snum_sname ON S(City, Snum, Sname);
CREATE INDEX IF NOT EXISTS idx_p_pname_pnum ON P(Pname, Pnum);
CREATE INDEX IF NOT EXISTS idx_sp_composite ON SP(Pnum, Snum, Quan);

-- 创建分区表优化
DROP TABLE IF EXISTS SP_PARTITIONED;
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

-- 将数据导入分区表
INSERT INTO SP_PARTITIONED SELECT * FROM SP;

-- 为分区表添加外键约束
ALTER TABLE SP_PARTITIONED 
ADD CONSTRAINT sp_part_fk1 FOREIGN KEY (Snum) REFERENCES S(Snum),
ADD CONSTRAINT sp_part_fk2 FOREIGN KEY (Pnum) REFERENCES P(Pnum);

-- 创建物化视图（在MySQL中通过表实现）
DROP TABLE IF EXISTS MV_BOLT_SUPPLIERS;
CREATE TABLE MV_BOLT_SUPPLIERS (
    Snum VARCHAR(10),
    Sname VARCHAR(50),
    City VARCHAR(50),
    PRIMARY KEY (Snum),
    INDEX idx_mv_city (City)
) AS
SELECT DISTINCT S.Snum, S.Sname, S.City
FROM S 
INNER JOIN SP_PARTITIONED SP ON S.Snum = SP.Snum
INNER JOIN P ON SP.Pnum = P.Pnum
WHERE P.Pname = 'Bolt' AND SP.Quan > 1000;

-- 创建触发器以保持物化视图同步
DELIMITER //

DROP TRIGGER IF EXISTS trg_sp_insert //
CREATE TRIGGER trg_sp_insert AFTER INSERT ON SP_PARTITIONED
FOR EACH ROW
BEGIN
    IF NEW.Quan > 1000 THEN
        INSERT IGNORE INTO MV_BOLT_SUPPLIERS
        SELECT DISTINCT S.Snum, S.Sname, S.City
        FROM S 
        INNER JOIN P ON NEW.Pnum = P.Pnum
        WHERE S.Snum = NEW.Snum 
        AND P.Pname = 'Bolt';
    END IF;
END //

DROP TRIGGER IF EXISTS trg_sp_delete //
CREATE TRIGGER trg_sp_delete AFTER DELETE ON SP_PARTITIONED
FOR EACH ROW
BEGIN
    IF OLD.Quan > 1000 THEN
        DELETE FROM MV_BOLT_SUPPLIERS
        WHERE Snum = OLD.Snum
        AND NOT EXISTS (
            SELECT 1 FROM SP_PARTITIONED SP
            INNER JOIN P ON SP.Pnum = P.Pnum
            WHERE SP.Snum = OLD.Snum
            AND P.Pname = 'Bolt'
            AND SP.Quan > 1000
        );
    END IF;
END //

DELIMITER ;

-- 性能测试
SET profiling = 1;

-- 测试物化视图查询
SELECT Sname
FROM MV_BOLT_SUPPLIERS
WHERE City = 'NANJING';

-- 测试备选优化查询
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

-- 查看执行计划
EXPLAIN FORMAT=JSON
SELECT Sname
FROM MV_BOLT_SUPPLIERS
WHERE City = 'NANJING';

-- 获取性能分析结果
SHOW PROFILES; 