-- 创建复合索引
CREATE INDEX idx_city_snum ON S(City, Snum);
CREATE INDEX idx_pname_pnum ON P(Pname, Pnum);
CREATE INDEX idx_sp_all ON SP(Snum, Pnum, Quan);

-- 优化后的查询（子查询方式）
SELECT DISTINCT S.Sname
FROM S 
INNER JOIN (
    SELECT SP.Snum
    FROM SP 
    INNER JOIN P ON SP.Pnum = P.Pnum
    WHERE P.Pname = 'Bolt' AND SP.Quan > 1000
) filtered_sp ON S.Snum = filtered_sp.Snum
WHERE S.City = 'NANJING';

-- 性能测试
SET profiling = 1;

-- 执行优化后的查询
SELECT DISTINCT S.Sname
FROM S 
INNER JOIN (
    SELECT SP.Snum
    FROM SP 
    INNER JOIN P ON SP.Pnum = P.Pnum
    WHERE P.Pname = 'Bolt' AND SP.Quan > 1000
) filtered_sp ON S.Snum = filtered_sp.Snum
WHERE S.City = 'NANJING';

-- 查看执行计划
EXPLAIN FORMAT=JSON
SELECT DISTINCT S.Sname
FROM S 
INNER JOIN (
    SELECT SP.Snum
    FROM SP 
    INNER JOIN P ON SP.Pnum = P.Pnum
    WHERE P.Pname = 'Bolt' AND SP.Quan > 1000
) filtered_sp ON S.Snum = filtered_sp.Snum
WHERE S.City = 'NANJING';

-- 获取性能分析结果
SHOW PROFILES; 