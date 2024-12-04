-- 开启查询性能分析
SET profiling = 1;

-- 原始查询
SELECT Sname
FROM S, SP, P
WHERE S.Snum = SP.Snum
AND SP.Pnum = P.Pnum
AND S.City = 'NANJING'
AND P.Pname = 'Bolt'
AND SP.Quan > 1000;

-- 优化后的查询（使用JOIN语法）
SELECT DISTINCT S.Sname
FROM S 
INNER JOIN SP ON S.Snum = SP.Snum
INNER JOIN P ON SP.Pnum = P.Pnum
WHERE S.City = 'NANJING'
AND P.Pname = 'Bolt'
AND SP.Quan > 1000;

-- 查看执行计划
EXPLAIN FORMAT=JSON
SELECT DISTINCT S.Sname
FROM S 
INNER JOIN SP ON S.Snum = SP.Snum
INNER JOIN P ON SP.Pnum = P.Pnum
WHERE S.City = 'NANJING'
AND P.Pname = 'Bolt'
AND SP.Quan > 1000;

-- 获取性能分析结果
SHOW PROFILES;

-- 查询各表的数据分布情况
SELECT 'S表中南京供应商数量' as metric, COUNT(*) as value
FROM S WHERE City = 'NANJING'
UNION ALL
SELECT 'P表中Bolt零件数量', COUNT(*)
FROM P WHERE Pname = 'Bolt'
UNION ALL
SELECT 'SP表中数量大于1000的记录数', COUNT(*)
FROM SP WHERE Quan > 1000; 