import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final localization = AppLocalizations.of(context);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(
        SnackBar(content: Text(localization.helpSupportLaunchFailed)),
      );
    }
  }

  void _showComingSoonMessage(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final localization = AppLocalizations.of(context);

    messenger.showSnackBar(
      SnackBar(content: Text(localization.helpSupportComingSoon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F3FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                AppAssets.helpSupport,
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l.helpSupportLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: const Color(0xFF111827),
                  ) ??
                  const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFF111827),
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SupportHeroCard(
              title: l.helpSupportTitle,
              subtitle: l.helpSupportSubtitle,
              hoursLabel: l.helpSupportHoursLabel,
              hoursValue: l.helpSupportHoursValue,
              responseLabel: l.helpSupportResponseTimeLabel,
              responseValue: l.helpSupportResponseTimeValue,
            ),
            const SizedBox(height: 24),
            _SectionTitle(text: l.helpSupportQuickActionsTitle),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickActionCard(
                  icon: Icons.help_outline,
                  label: l.helpSupportFaqsLabel,
                  description: l.helpSupportFaqsSubtitle,
                  onTap: () => _showComingSoonMessage(context),
                ),
                _QuickActionCard(
                  icon: Icons.menu_book_outlined,
                  label: l.helpSupportGuidesLabel,
                  description: l.helpSupportGuidesSubtitle,
                  onTap: () => _showComingSoonMessage(context),
                ),
                _QuickActionCard(
                  icon: Icons.report_problem_outlined,
                  label: l.helpSupportReportIssueLabel,
                  description: l.helpSupportReportIssueSubtitle,
                  onTap: () => _showComingSoonMessage(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle(text: l.helpSupportContactTitle),
            const SizedBox(height: 12),
            _ContactCard(
              icon: Icons.email_outlined,
              label: l.helpSupportEmailLabel,
              value: l.helpSupportEmailValue,
              buttonLabel: l.helpSupportEmailButton,
              onPressed: () => _launchUri(
                context,
                Uri(
                  scheme: 'mailto',
                  path: l.helpSupportEmailValue,
                  queryParameters: {'subject': l.appTitle},
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ContactCard(
              icon: Icons.phone_outlined,
              label: l.helpSupportPhoneLabel,
              value: l.helpSupportPhoneValue,
              buttonLabel: l.helpSupportCallButton,
              onPressed: () => _launchUri(
                context,
                Uri(
                  scheme: 'tel',
                  path:
                      l.helpSupportPhoneValue.replaceAll(RegExp(r'[^0-9+]'), ''),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ContactCard(
              icon: Icons.chat_bubble_outline,
              label: l.helpSupportChatLabel,
              value: l.helpSupportChatSubtitle,
              buttonLabel: l.helpSupportChatButton,
              onPressed: () => _showComingSoonMessage(context),
            ),
            const SizedBox(height: 24),
            _SectionTitle(text: l.helpSupportAdditionalInfoTitle),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.update,
              label: l.helpSupportLastUpdatedLabel,
              value: l.helpSupportLastUpdatedValue,
            ),
            const SizedBox(height: 8),
            _InfoTile(
              icon: Icons.shield_outlined,
              label: l.helpSupportPolicyLabel,
              value: l.helpSupportPolicyValue,
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportHeroCard extends StatelessWidget {
  const _SupportHeroCard({
    required this.title,
    required this.subtitle,
    required this.hoursLabel,
    required this.hoursValue,
    required this.responseLabel,
    required this.responseValue,
  });

  final String title;
  final String subtitle;
  final String hoursLabel;
  final String hoursValue;
  final String responseLabel;
  final String responseValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ) ??
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ) ??
                          TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(
                  AppAssets.helpSupport,
                  width: 48,
                  height: 48,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroInfoChip(
                  label: hoursLabel,
                  value: hoursValue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroInfoChip(
                  label: responseLabel,
                  value: responseValue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroInfoChip extends StatelessWidget {
  const _HeroInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ) ??
                TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF111827),
          ) ??
          const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF111827),
          ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        width: 180,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F3FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF1C87FF)),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ) ??
                  const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ) ??
                  const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String value;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F3FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF1C87FF)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4B5563),
                      ) ??
                      const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 14,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              buttonLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ) ??
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F3FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF1C87FF)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                        fontSize: 15,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ) ??
                      const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
