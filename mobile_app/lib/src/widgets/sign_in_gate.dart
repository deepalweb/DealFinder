import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../services/app_session.dart';
import '../screens/login_screen.dart';

/// Keep the originating route alive. A cancelled login never runs its action.
Future<bool> requireSignIn(BuildContext context,
    {WidgetBuilder? loginBuilder}) async {
  if ((await AppSession.read()).isSignedIn) return context.mounted;
  if (!context.mounted) return false;
  final accepted = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      builder: loginBuilder ?? (_) => const LoginScreen(returnToAction: true),
      fullscreenDialog: true,
    ),
  );
  return context.mounted &&
      accepted == true &&
      (await AppSession.read()).isSignedIn;
}

class SignInGate extends StatefulWidget {
  const SignInGate({super.key, required this.title});
  final String title;

  @override
  State<SignInGate> createState() => _SignInGateState();
}

class _SignInGateState extends State<SignInGate> {
  bool _opening = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.person_outline,
                size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text(l10n.discoverySignInTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(l10n.discoverySignInBody, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _opening
                  ? null
                  : () async {
                      setState(() => _opening = true);
                      await requireSignIn(context);
                      if (mounted) setState(() => _opening = false);
                    },
              child: Text(l10n.discoverySignIn),
            ),
          ]),
        ),
      ),
    );
  }
}
