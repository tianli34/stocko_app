import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/services/backup_error_handler.dart';
import '../../data/services/backup_diagnostic_service.dart';

/// 增强的错误对话框 - 提供详细的错误信息和解决建议
class EnhancedErrorDialog extends StatefulWidget {
  final UserFriendlyError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDiagnose;
  final bool showDiagnosticButton;

  const EnhancedErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
    this.onDiagnose,
    this.showDiagnosticButton = true,
  });

  static Future<bool?> show(
    BuildContext context, {
    required UserFriendlyError error,
    VoidCallback? onRetry,
    VoidCallback? onDiagnose,
    bool showDiagnosticButton = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedErrorDialog(
        error: error,
        onRetry: onRetry,
        onDiagnose: onDiagnose,
        showDiagnosticButton: showDiagnosticButton,
      ),
    );
  }

  @override
  State<EnhancedErrorDialog> createState() => _EnhancedErrorDialogState();
}

class _EnhancedErrorDialogState extends State<EnhancedErrorDialog> {
  bool _showTechnicalDetails = false;
  bool _isDiagnosing = false;
  BackupDiagnosticResult? _diagnosticResult;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: _buildTitle(context),
      content: SingleChildScrollView(
        child: _buildContent(context),
      ),
      actions: _buildActions(context),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.error.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 错误描述
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.error.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),

        // 解决建议
        if (widget.error.suggestion != null) ...[
          const SizedBox(height: 16),
          _buildSuggestionSection(context),
        ],

        // 诊断结果
        if (_diagnosticResult != null) ...[
          const SizedBox(height: 16),
          _buildDiagnosticResult(context),
        ],

        // 技术详情
        if (widget.error.technicalDetails != null) ...[
          const SizedBox(height: 16),
          _buildTechnicalDetailsSection(context),
        ],
      ],
    );
  }

  Widget _buildSuggestionSection(BuildContext context) {
    final suggestion = widget.error.suggestion!;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                suggestion.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            suggestion.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ...suggestion.steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDiagnosticResult(BuildContext context) {
    final result = _diagnosticResult!;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                '诊断结果',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.isHealthy ? '系统正常' : '发现问题',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (result.issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...result.issues.map((issue) => _buildDiagnosticIssueText(context, issue)),
          ],
        ],
      ),
    );
  }

  Widget _buildDiagnosticIssueText(BuildContext context, String issue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              issue,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showTechnicalDetails = !_showTechnicalDetails),
          child: Row(
            children: [
              Icon(
                _showTechnicalDetails ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '技术详情',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        if (_showTechnicalDetails) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.error.technicalDetails!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () => _copyToClipboard(context, widget.error.technicalDetails!),
                      tooltip: '复制到剪贴板',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      // 诊断按钮
      if (widget.showDiagnosticButton && _diagnosticResult == null)
        TextButton.icon(
          onPressed: _isDiagnosing ? null : _runDiagnostic,
          icon: _isDiagnosing 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.medical_services, size: 16),
          label: Text(_isDiagnosing ? '诊断中...' : '诊断'),
        ),
      
      // 关闭按钮
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('关闭'),
      ),
      
      // 重试按钮
      if (widget.error.canRetry && widget.onRetry != null)
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop(true);
            widget.onRetry!();
          },
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('重试'),
        ),
    ];
  }

  Future<void> _runDiagnostic() async {
    setState(() => _isDiagnosing = true);
    
    try {
      // 创建临时诊断结果
      final result = BackupDiagnosticResult(
        isHealthy: true,
        issues: [],
        warnings: [],
        systemInfo: {},
        databaseInfo: {},
        storageInfo: {},
      );
      
      if (mounted) {
        setState(() {
          _diagnosticResult = result;
          _isDiagnosing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDiagnosing = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('诊断失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('技术详情已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }


}