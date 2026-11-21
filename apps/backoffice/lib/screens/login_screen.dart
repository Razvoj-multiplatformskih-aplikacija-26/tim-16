import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Ekran za prijavu. [reason] je razlog iz SessionBloc-a (istekla prijava,
/// pogrešna aplikacija…), a [roleNotAllowedMessage] tekst za pogrešnu aplikaciju.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.title, required this.roleNotAllowedMessage, this.reason});

  final String title;
  final String roleNotAllowedMessage;
  final SignOutReason? reason;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => LoginFormBloc(sessions: context.read<SessionRepository>()),
    child: _LoginForm(title: title, roleNotAllowedMessage: roleNotAllowedMessage, reason: reason),
  );
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.title, required this.roleNotAllowedMessage, this.reason});

  final String title;
  final String roleNotAllowedMessage;
  final SignOutReason? reason;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() => context.read<LoginFormBloc>().add(
    LoginSubmitted(username: _username.text, password: _password.text),
  );

  String? _messageOf(LoginFormState form) => switch (form) {
    LoginRejected() => 'Pogrešno korisničko ime ili lozinka.',
    LoginFailed() => 'Server nije dostupan. Proverite vezu i pokušajte ponovo.',
    _ => switch (widget.reason) {
      SignOutReason.expired => 'Prijava je istekla. Prijavite se ponovo.',
      SignOutReason.roleNotAllowed => widget.roleNotAllowedMessage,
      SignOutReason.unreachable => 'Server nije dostupan. Proverite vezu i pokušajte ponovo.',
      SignOutReason.loggedOut || null => null,
    },
  };

  @override
  Widget build(BuildContext context) => BlocConsumer<LoginFormBloc, LoginFormState>(
    listener: (context, form) {
      // Da li ta uloga sme u ovu aplikaciju, odlučuje SessionBloc (admits).
      if (form is LoginSucceeded) context.read<SessionBloc>().add(SessionStarted(form.user));
    },
    builder: (context, form) {
      final busy = form is LoginSubmitting;
      final message = _messageOf(form);
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Text(widget.title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (message != null) ...[
                  Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _username,
                  enabled: !busy,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(labelText: 'Korisničko ime'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  enabled: !busy,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(labelText: 'Lozinka'),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : _submit,
                  child: busy
                      ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Prijavi se'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}