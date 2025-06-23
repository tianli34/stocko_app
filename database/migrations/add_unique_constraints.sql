-- 数据库迁移脚本：添加唯一约束
-- 日期：2025-06-22
-- 目的：为类别和单位表添加唯一约束，防止重复数据

-- 1. 为单位表添加唯一约束
-- 首先移除重复的单位记录（如果存在）
DELETE FROM units 
WHERE id NOT IN (
    SELECT MIN(id) 
    FROM units 
    GROUP BY name
);

-- 为单位名称添加唯一约束
CREATE UNIQUE INDEX IF NOT EXISTS idx_units_name_unique 
ON units(name);

-- 2. 为类别表添加复合唯一约束
-- 首先移除重复的类别记录（如果存在）
DELETE FROM categories 
WHERE id NOT IN (
    SELECT MIN(id) 
    FROM categories 
    GROUP BY name, COALESCE(parent_id, 'null')
);

-- 为类别名称和父级ID的组合添加唯一约束
CREATE UNIQUE INDEX IF NOT EXISTS idx_categories_name_parent_unique 
ON categories(name, COALESCE(parent_id, 'null'));

-- 3. 验证约束是否生效
-- 查询是否还有重复记录
SELECT name, COUNT(*) as count 
FROM units 
GROUP BY name 
HAVING COUNT(*) > 1;

SELECT name, COALESCE(parent_id, 'null') as parent, COUNT(*) as count 
FROM categories 
GROUP BY name, COALESCE(parent_id, 'null') 
HAVING COUNT(*) > 1;
