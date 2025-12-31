import 'package:flutter/material.dart';
import '../../domain/model/category.dart';

/// 删除类别对话框组件
class DeleteCategoryDialog extends StatefulWidget {
  final CategoryModel category;
  final bool hasSubCategories;
  final int subCategoriesCount;
  final int relatedProductsCount;
  final VoidCallback onDeleteOnly;
  final VoidCallback onDeleteCascade;

  const DeleteCategoryDialog({
    super.key,
    required this.category,
    required this.hasSubCategories,
    required this.subCategoriesCount,
    required this.relatedProductsCount,
    required this.onDeleteOnly,
    required this.onDeleteCascade,
  });

  @override
  State<DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends State<DeleteCategoryDialog> {
  int _selectedOption = 0; // 0: 仅删除当前类别, 1: 级联删除

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 24),
          SizedBox(width: 8),
          Text('删除类别'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '即将删除类别 "${widget.category.name}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildImpactInfo(),
            const Text(
              '请选择删除模式：',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildDeleteOnlyOption(),
            const SizedBox(height: 12),
            _buildCascadeDeleteOption(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _selectedOption == 0
              ? widget.onDeleteOnly
              : widget.onDeleteCascade,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedOption == 0 ? Colors.blue : Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(_selectedOption == 0 ? '仅删除类别' : '级联删除'),
        ),
      ],
    );
  }

  Widget _buildImpactInfo() {
    if (!widget.hasSubCategories && widget.relatedProductsCount <= 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '影响范围：',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (widget.hasSubCategories)
          Row(
            children: [
              const Icon(Icons.folder, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              Text('子类别：${widget.subCategoriesCount} 个'),
            ],
          ),
        if (widget.relatedProductsCount > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.inventory, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Text('关联产品：${widget.relatedProductsCount} 个'),
            ],
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDeleteOnlyOption() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedOption == 0
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300,
          width: _selectedOption == 0 ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: _selectedOption == 0
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : null,
      ),
      child: RadioListTile<int>(
        value: 0,
        groupValue: _selectedOption,
        onChanged: (value) => setState(() => _selectedOption = value!),
        title: const Text(
          '仅删除当前类别',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Text('保留子类别和关联产品'),
            const SizedBox(height: 8),
            if (widget.hasSubCategories) ...[
              Row(
                children: [
                  const Icon(Icons.arrow_forward, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.category.parentId != null
                          ? '子类别将转移到上级类别'
                          : '子类别将成为根类别',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (widget.relatedProductsCount > 0) ...[
              Row(
                children: [
                  const Icon(Icons.arrow_forward, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.category.parentId != null
                          ? '产品将转移到上级类别'
                          : '产品将取消类别关联',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildCascadeDeleteOption() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedOption == 1 ? Colors.red : Colors.grey.shade300,
          width: _selectedOption == 1 ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: _selectedOption == 1 ? Colors.red.withOpacity(0.1) : null,
      ),
      child: RadioListTile<int>(
        value: 1,
        groupValue: _selectedOption,
        onChanged: (value) => setState(() => _selectedOption = value!),
        title: const Text(
          '级联删除所有内容',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Text('删除类别及所有关联内容'),
            const SizedBox(height: 8),
            if (widget.hasSubCategories) ...[
              Row(
                children: [
                  const Icon(
                    Icons.delete,
                    size: 14,
                    color: Color.fromARGB(255, 136, 54, 244),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '删除所有子类别（${widget.subCategoriesCount} 个）',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(255, 178, 47, 211),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (widget.relatedProductsCount > 0) ...[
              Row(
                children: [
                  const Icon(
                    Icons.delete,
                    size: 14,
                    color: Color.fromARGB(255, 152, 54, 244),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '删除所有关联产品（${widget.relatedProductsCount} 个）',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            const Row(
              children: [
                Icon(Icons.warning, size: 14, color: Colors.orange),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '此操作不可恢复',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
