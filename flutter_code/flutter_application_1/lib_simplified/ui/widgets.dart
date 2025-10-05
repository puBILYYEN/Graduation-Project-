// AK47 風格精簡版：通用 UI 組件
import 'package:flutter/material.dart';
import '../utils/constants.dart';

// 簡潔的載入指示器
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: AppColors.primary),
  );
}

// 簡潔的錯誤顯示
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message, style: AppTextStyles.body),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.m),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('重試'),
          ),
        ],
      ],
    ),
  );
}

// 簡潔的輸入欄位
class InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const InputField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: AppBorders.radius),
      suffixIcon: suffixIcon,
    ),
  );
}

// 簡潔的主要按鈕
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
        shape: RoundedRectangleBorder(borderRadius: AppBorders.radius),
      ),
      child: isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.background),
            ),
          )
        : Text(text),
    ),
  );
}

// 簡潔的卡片容器
class CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const CardContainer({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(AppSpacing.m),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: AppBorders.radius,
      boxShadow: AppShadows.card,
    ),
    child: child,
  );
}