import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import 'auth_header.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundMint, AppColors.backgroundCream],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 720;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      SizedBox(
                        height: compact ? 142 : 280,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: compact ? 0 : 24),
                          child: Align(
                            alignment:
                                compact
                                    ? Alignment.center
                                    : Alignment.bottomCenter,
                            child: AuthHeader(compact: compact),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 28,
                                offset: Offset(0, -6),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            top: false,
                            minimum: const EdgeInsets.only(bottom: 12),
                            child: SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                30,
                                compact ? 18 : 46,
                                30,
                                20,
                              ),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
