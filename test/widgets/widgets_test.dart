import 'package:catalogo_anime/providers/auth_provider.dart';
import 'package:catalogo_anime/screens/login_screen.dart';
import 'package:catalogo_anime/services/local_store.dart';
import 'package:catalogo_anime/widgets/anime_poster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('pôster sem URL mostra placeholder com rótulo acessível', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AnimePoster(url: null, title: 'Naruto')),
      ),
    );

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(find.bySemanticsLabel('Imagem indisponível para Naruto'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('login valida os campos antes de autenticar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = (await tester.runAsync(LocalStore.open))!;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(store, minimumFeedback: Duration.zero),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Informe um usuário com pelo menos 3 caracteres.'), findsOneWidget);
    expect(find.text('A senha precisa ter pelo menos 4 caracteres.'), findsOneWidget);
  });

  testWidgets('login alterna para modo cadastro', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = (await tester.runAsync(LocalStore.open))!;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(store, minimumFeedback: Duration.zero),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Não tem conta? Cadastre-se'));
    await tester.pump();

    expect(find.widgetWithText(FilledButton, 'Criar conta'), findsOneWidget);
  });
}
