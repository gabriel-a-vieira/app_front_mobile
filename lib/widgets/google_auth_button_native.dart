import 'package:app_front_mobile/services/google_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GoogleAuthButton extends StatelessWidget {
  final bool loading;

  const GoogleAuthButton({super.key, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: loading
            ? null
            : () {
                GoogleAuthService.instance.authenticateInteractive();
              },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.google,
              size: 16,
              color: Color.fromARGB(255, 244, 72, 66),
            ),

            SizedBox(width: 10),

            Text('Google'),
          ],
        ),
      ),
    );
  }
}
