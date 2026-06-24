import 'package:dipl/app/app_colors.dart';
import 'package:dipl/features/user/data/user_api_service.dart';
import 'package:flutter/material.dart';

class CertificatePage extends StatefulWidget {
  const CertificatePage({required this.courseId, super.key});

  final String courseId;

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  late Future<CertificateInfo> _certificateFuture;

  @override
  void initState() {
    super.initState();
    _certificateFuture = UserApiService.instance.issueCertificate(
      widget.courseId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CertificateInfo>(
      future: _certificateFuture,
      builder: (context, snapshot) {
        final CertificateInfo? certificate = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: const Text('Сертификат')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 2),
                if (snapshot.hasError)
                  _ErrorCard(
                    message: snapshot.error.toString(),
                    onRetry: () => setState(() {
                      _certificateFuture = UserApiService.instance
                          .issueCertificate(widget.courseId);
                    }),
                  ),
                if (certificate != null) _CertificateCard(certificate),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard(this.certificate);

  final CertificateInfo certificate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                size: 46,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(height: 10),
              Text(
                certificate.courseTitle.isEmpty
                    ? 'Сертификат о прохождении'
                    : certificate.courseTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (certificate.recipientName.isNotEmpty)
                    certificate.recipientName,
                  if (certificate.level.isNotEmpty) certificate.level,
                  if (certificate.finalScore > 0) '${certificate.finalScore}%',
                ].join(' · '),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Код проверки',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        SelectableText(
          certificate.verificationCode,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        _InfoRow(label: 'Статус', value: certificate.status),
        _InfoRow(label: 'Дата выдачи', value: certificate.issuedAt),
        if (certificate.pdfUrl.isNotEmpty)
          _InfoRow(label: 'PDF', value: certificate.pdfUrl),
        if (certificate.verificationUrl.isNotEmpty)
          _InfoRow(label: 'Проверка', value: certificate.verificationUrl),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3F2),
        border: Border.all(color: const Color(0xFFFDA29B)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: Color(0xFFB42318))),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}
