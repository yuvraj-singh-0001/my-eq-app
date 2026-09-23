// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:myeq_app/application.dart';
import 'package:myeq_app/features/authentication/presentation/pages/login_page.dart';
import 'package:myeq_app/features/authentication/presentation/pages/signup_page.dart';

void main() {
  testWidgets('MyEQ App welcome screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const Application());

    expect(find.text('MyEQ'), findsOneWidget);
    expect(find.text(' App'), findsOneWidget);
    expect(find.text('A Happier, Stronger'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text("Let's Get Started"), findsOneWidget);
    expect(find.textContaining('Sign In'), findsOneWidget);
  });

  testWidgets('Get started opens the login page', (WidgetTester tester) async {
    await tester.pumpWidget(const Application());

    await tester.tap(find.text("Let's Get Started"));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
  });

  testWidgets('Create Account opens the signup page', (WidgetTester tester) async {
    await tester.pumpWidget(const Application());
    await tester.tap(find.text("Let's Get Started"));
    await tester.pumpAndSettle();
    final createAccount = find.textContaining('Create Account');
    await tester.ensureVisible(createAccount);
    await tester.tap(createAccount);
    await tester.pumpAndSettle();

    expect(find.byType(SignupPage), findsOneWidget);
    expect(find.text('Create Your\nAccount'), findsOneWidget);
  });
}
