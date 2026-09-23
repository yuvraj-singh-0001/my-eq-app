import 'package:flutter/material.dart';

import '../../../authentication/presentation/pages/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;
          final horizontalPadding = isCompact ? 24.0 : 32.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'lib/assets/images/mindgrow_welcome_background.png',
                fit: BoxFit.cover,
                cacheWidth: 900,
                filterQuality: FilterQuality.medium,
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    20,
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF243657),
                            backgroundColor: Colors.white.withAlpha(210),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 9,
                            ),
                            minimumSize: const Size(64, 40),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Skip'),
                        ),
                      ),
                      SizedBox(height: isCompact ? 10 : 18),
                      const _BrandHeader(),
                      SizedBox(height: isCompact ? 30 : 52),
                      Text(
                        'A Happier, Stronger',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF101C38),
                          fontSize: isCompact ? 27 : 31,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'You',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF18916D),
                          fontSize: 34,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 330),
                        child: Text(
                          'Track your feelings, overcome challenges,\nand grow with the support of\nyour teachers and parents.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF53647C),
                            fontSize: 15,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const LoginPage(),
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E376C),
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Let's Get Started"),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward, size: 22),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LoginPage(),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF53647C),
                          minimumSize: const Size(180, 40),
                        ),
                        child: const Text.rich(
                          TextSpan(
                            text: 'Already have an account?  ',
                            children: [
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color: Color(0xFF176B87),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.spa_outlined,
              size: 49,
              color: Color(0xFF18916D),
            ),
            const SizedBox(width: 6),
            const Text(
              'MyEQ',
              style: TextStyle(
                color: Color(0xFF101C38),
                fontSize: 31,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              ' App',
              style: TextStyle(
                color: Color(0xFF18916D),
                fontSize: 31,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'Understand  ·  Support  ·  Grow',
          style: TextStyle(
            color: Color(0xFF53647C),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
