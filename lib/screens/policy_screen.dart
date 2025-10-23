import 'package:flutter/material.dart';

import '../apis/content_api.dart';
import '../core/localization/app_localizations.dart';
import '../models/policy_content.dart';
import '../apis/auth_api.dart' show ApiException;

enum PolicyType { terms, privacy }

class PolicyScreen extends StatefulWidget {
  PolicyScreen({
    super.key,
    required this.type,
    ContentApi? api,
  }) : _api = api ?? ContentApi();

  final PolicyType type;
  final ContentApi _api;

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  late Future<PolicyContent> _policyFuture;
  String? _policyTitle;

  @override
  void initState() {
    super.initState();
    _policyFuture = _loadPolicy();
  }

  Future<PolicyContent> _loadPolicy() async {
    final policy = await _fetchPolicy();
    if (!mounted) return policy;

    final title = policy.title.trim();
    if (title.isNotEmpty) {
      setState(() {
        _policyTitle = title;
      });
    }
    return policy;
  }

  Future<PolicyContent> _fetchPolicy() {
    if (widget.type == PolicyType.terms) {
      return widget._api.fetchTerms();
    }
    return widget._api.fetchPrivacy();
  }

  void _retry() {
    setState(() {
      _policyTitle = null;
      _policyFuture = _loadPolicy();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fallbackTitle = widget.type == PolicyType.terms
        ? l.userAgreement
        : l.privacyPolicy;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
        title: Text(
          _policyTitle ?? fallbackTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: FutureBuilder<PolicyContent>(
        future: _policyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = _errorMessage(snapshot.error, l);
            return _ErrorView(
              message: message,
              retryLabel: l.policyRetryButton,
              onRetry: _retry,
            );
          }

          if (!snapshot.hasData) {
            return _ErrorView(
              message: l.policyLoadFailed,
              retryLabel: l.policyRetryButton,
              onRetry: _retry,
            );
          }

          final policy = snapshot.data!;
          return _PolicyContentView(
            policy: policy,
            fallbackTitle: _policyTitle ?? fallbackTitle,
            lastUpdatedLabel: l.policyLastUpdatedLabel,
          );
        },
      ),
    );
  }

  String _errorMessage(Object? error, AppLocalizations l) {
    if (error is ApiException) return error.message;
    return l.policyLoadFailed;
  }
}

class _PolicyContentView extends StatelessWidget {
  const _PolicyContentView({
    required this.policy,
    required this.fallbackTitle,
    required this.lastUpdatedLabel,
  });

  final PolicyContent policy;
  final String fallbackTitle;
  final String lastUpdatedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastUpdated = policy.lastUpdatedLabel;

    final displayTitle = policy.title.trim().isEmpty
        ? fallbackTitle
        : policy.title.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          if (lastUpdated != null) ...[
            Text(
              '$lastUpdatedLabel: $lastUpdated',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            policy.normalizedContent,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF111827),
                  ) ??
                  const TextStyle(color: Color(0xFF111827)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
