import 'package:dipl/app/app_colors.dart';
import 'package:flutter/material.dart';

class CertificatePage extends StatelessWidget {
  const CertificatePage({required this.courseId, super.key});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    const String code = 'DIPL-2026-B1-7Q4X';
    return Scaffold(
      appBar: AppBar(title: const Text('Сертификат')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            Container(
              height: 230,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFEDE9FE), Color(0xFFD1FAE5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 46,
                    color: AppColors.brandPrimary,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Сертификат о прохождении',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text('Кыргызский язык · уровень B1'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Код проверки',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const SelectableText(
              code,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Скачать PDF'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share_outlined),
              label: const Text('Поделиться'),
            ),
            const SizedBox(height: 20),
            Text(
              'Публичная проверка: /certificate/verify?code=$code',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
