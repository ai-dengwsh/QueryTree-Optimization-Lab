-- 创建供应商表(S)
CREATE TABLE S (
    Snum VARCHAR(10) PRIMARY KEY,
    Sname VARCHAR(50),
    City VARCHAR(50)
);

-- 创建零件表(P)
CREATE TABLE P (
    Pnum VARCHAR(10) PRIMARY KEY,
    Pname VARCHAR(50),
    Weight DECIMAL(10,2),
    Size INT
);

-- 创建供应关系表(SP)
CREATE TABLE SP (
    Snum VARCHAR(10),
    Pnum VARCHAR(10),
    Dept VARCHAR(50),
    Quan INT,
    PRIMARY KEY (Snum, Pnum),
    FOREIGN KEY (Snum) REFERENCES S(Snum),
    FOREIGN KEY (Pnum) REFERENCES P(Pnum)
);

-- 创建索引
CREATE INDEX idx_city ON S(City);
CREATE INDEX idx_pname ON P(Pname);
CREATE INDEX idx_sp_quan ON SP(Quan);
CREATE INDEX idx_sp_snum ON SP(Snum);
CREATE INDEX idx_sp_pnum ON SP(Pnum); 