import 'package:flutter/material.dart';

import 'auth_primary_button.dart';
import 'sensitive_data_consent_card.dart';

Future<bool> showAuthSensitiveDataConsentSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _AuthSensitiveDataConsentSheet(),
  );

  return result ?? false;
}

class _AuthSensitiveDataConsentSheet extends StatefulWidget {
  const _AuthSensitiveDataConsentSheet();

  @override
  State<_AuthSensitiveDataConsentSheet> createState() =>
      _AuthSensitiveDataConsentSheetState();
}

class _AuthSensitiveDataConsentSheetState
    extends State<_AuthSensitiveDataConsentSheet> {
  bool accepted = false;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight = MediaQuery.sizeOf(context).height * 0.86;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: availableHeight),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 18, 24, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: SensitiveDataConsentCard(
                  accepted: accepted,
                  onChanged: (value) => setState(() => accepted = value),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AuthPrimaryButton(
              label: 'LI E CONCORDO',
              isLoading: false,
              onPressed: accepted
                  ? () => Navigator.of(context).pop(true)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
