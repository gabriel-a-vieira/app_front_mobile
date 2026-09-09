import 'package:flutter/material.dart';

import 'package:google_sign_in_web/web_only.dart' as web;

class GoogleAuthButton extends StatelessWidget {
  final bool loading;

  const GoogleAuthButton({super.key, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: loading,
      child: Opacity(
        opacity: loading ? 0.55 : 1,
        child: web.renderButton(
          configuration: web.GSIButtonConfiguration(
            type: web.GSIButtonType.standard,

            theme: web.GSIButtonTheme.filledBlack,

            size: web.GSIButtonSize.large,

            text: web.GSIButtonText.continueWith,

            shape: web.GSIButtonShape.rectangular,

            minimumWidth: 130,

            locale: 'pt-BR',
          ),
        ),
      ),
    );
  }
}
