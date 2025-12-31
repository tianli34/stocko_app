import 'package:flutter/material.dart';
import '../../domain/model/category.dart';

/// 类别列表项组件
class CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final int level;
  final bool isSelected;
  final bool hasSubCategories;
  final bool isExpanded;
  final int productCount;
  final int subCategoriesCount;
  final VoidCallback? onTap;
  final VoidCallback? onExpandToggle;
  final void Function(String action)? onAction;

  const CategoryTile({
    super.key,
    required this.category,
    this.level = 0,
    this.isSelected = false,
    this.hasSubCategories = false,
    this.isExpanded = false,
    this.productCount = 0,
    this.subCategoriesCount = 0,
    this.onTap,
    this.onExpandToggle,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isSubCategory = level > 0;
    final leftMargin = level * 24.0;

    return Container(
      margin: EdgeInsets.only(bottom: 8, left: leftMargin),
      child: Card(
        elevation: isSelected ? 4 : 1,
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : null,
        child: ListTile(
          title: Row(
            children: [
              if (hasSubCategories) ...[
                GestureDetector(
                  onTap: onExpandToggle,
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Row(
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: isSubCategory ? 14 : 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$productCount',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: hasSubCategories
              ? Text(
                  '$subCategoriesCount 个子类别',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                onSelected: onAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add_parent_category',
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 20),
                        SizedBox(width: 8),
                        Text('新增父类'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('重命名'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          size: 20,
                          color: Color.fromARGB(255, 78, 6, 138),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '删除',
                          style: TextStyle(color: Color.fromARGB(255, 85, 0, 141)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
