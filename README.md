# 查询树的启发式优化算法实践 🚀

## 项目介绍 📝

本项目实现了一个关于供应商-零件-供应关系的数据库查询优化案例。通过多阶段优化，展示了如何从基础优化到高级优化，最终实现查询性能的极致提升。

## 数据库结构 📊

- S(Snum, Sname, City) - 供应商表 (20000条记录)
- P(Pnum, Pname, Weight, Size) - 零件表 (10000条记录)
- SP(Snum, Pnum, Dept, Quan) - 供应关系表 (10000条记录)

## 查询优化进化史 🔄

### 1. 原始查询
```sql
SELECT Sname
FROM S, SP, P
WHERE S.Snum = SP.Snum
AND SP.Pnum = P.Pnum
AND S.City = 'NANJING'
AND P.Pname = 'Bolt'
AND SP.Quan > 1000;
```
执行时间：0.01275350秒

### 2. 第一阶段优化（基础优化）
```sql
SELECT DISTINCT S.Sname
FROM S 
INNER JOIN SP ON S.Snum = SP.Snum
INNER JOIN P ON SP.Pnum = P.Pnum
WHERE S.City = 'NANJING'
AND P.Pname = 'Bolt'
AND SP.Quan > 1000;
```
执行时间：0.00454500秒 (提升64.4%)

### 3. 第二阶段优化（进阶优化）
```sql
SELECT DISTINCT S.Sname
FROM S 
INNER JOIN (
    SELECT SP.Snum
    FROM SP 
    INNER JOIN P ON SP.Pnum = P.Pnum
    WHERE P.Pname = 'Bolt' AND SP.Quan > 1000
) filtered_sp ON S.Snum = filtered_sp.Snum
WHERE S.City = 'NANJING';
```
执行时间：0.00095275秒 (比原始查询提升92.5%)

### 4. 终极优化（企业级优化）
1. 分区表优化
```sql
CREATE TABLE SP_PARTITIONED ... PARTITION BY RANGE(Quan)
```

2. 物化视图优化
```sql
CREATE TABLE MV_BOLT_SUPPLIERS AS
SELECT DISTINCT S.Snum, S.Sname, S.City
FROM S 
INNER JOIN SP_PARTITIONED SP ON S.Snum = SP.Snum
INNER JOIN P ON SP.Pnum = P.Pnum
WHERE P.Pname = 'Bolt' AND SP.Quan > 1000;
```

3. 最终查询
```sql
SELECT Sname
FROM MV_BOLT_SUPPLIERS
WHERE City = 'NANJING';
```
执行时间：0.00023750秒 (比原始查询提升98.1%)

## 优化策略详解 💡

### 1. 索引优化
- 复合索引设计
  ```sql
  CREATE INDEX idx_s_city_snum_sname ON S(City, Snum, Sname);
  CREATE INDEX idx_p_pname_pnum ON P(Pname, Pnum);
  CREATE INDEX idx_sp_composite ON SP(Pnum, Snum, Quan);
  ```

### 2. 分区表优化
- 按Quan字段范围分区
- 分区策略：
  ```sql
  PARTITION BY RANGE(Quan) (
      PARTITION p0 VALUES LESS THAN (500),
      PARTITION p1 VALUES LESS THAN (1000),
      PARTITION p2 VALUES LESS THAN (1500),
      PARTITION p3 VALUES LESS THAN (2000),
      PARTITION p4 VALUES LESS THAN MAXVALUE
  )
  ```

### 3. 物化视图优化
- 预计算查询结果
- 通过触发器保持数据同步
- 极大减少运行时计算量

### 4. 查询重写优化
- 子查询优化
- 强制索引使用
- 分区剪枝

## 性能对比 📊

| 优化阶段 | 执行时间(秒) | 性能提升 |
|---------|------------|---------|
| 原始查询 | 0.01275350 | 基准线 |
| 基础优化 | 0.00454500 | 64.4% |
| 进阶优化 | 0.00095275 | 92.5% |
| 终极优化 | 0.00023750 | 98.1% |

## 最佳实践建议 🌟

1. 数据库设计
   - 合理使用分区表
   - 建立合适的复合索引
   - 使用物化视图预计算

2. 查询优化
   - 优先考虑索引优化
   - 合理使用子查询
   - 控制查询范围

3. 维护优化
   - 定期更新统计信息
   - 监控查询性能
   - 及时优化索引

## 如何运行 🚀

1. 执行 `create_tables.sql` 创建基础表结构
2. 执行 `generate_data.sql` 生成测试数据
3. 执行 `query_test.sql` 测试基础优化
4. 执行 `advanced_optimization.sql` 测试进阶优化
5. 执行 `ultimate_optimization.sql` 实现终极优化

## 注意事项 ⚠️

- 物化视图需要额外存储空间
- 触发器可能影响写入性能
- 分区表设计需要提前规划
- 索引数量需要权衡维护成本

## 性能测试环境 💻

- 数据库版本：MySQL 8.0.36
- 操作系统：Windows 10
- 数据量：
  - 供应商表：20,000条记录
  - 零件表：10,000条记录
  - 供应关系表：10,000条记录

## 贡献指南 🤝

欢迎提交Issue和Pull Request来帮助改进这个项目！

## 未来优化方向 🔮

1. 引入缓存层
   - Redis缓存热点数据
   - 应用层查询缓存

2. 分布式优化
   - 数据分片
   - 读写分离

3. 硬件优化
   - SSD存储
   - 增加内存
   - 优化CPU配置