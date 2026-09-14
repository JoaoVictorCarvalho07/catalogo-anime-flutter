import 'package:catalogo_anime/providers/auth_provider.dart';
import 'package:catalogo_anime/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  AuthProvider buildAuth(LocalStore store) =>
      AuthProvider(store, minimumFeedback: Duration.zero);

  test('cadastro inicia sessão e login posterior funciona', () async {
    final store = await LocalStore.open();
    final auth = buildAuth(store);

    expect(await auth.register('  Ana ', 'segredo'), isNull);
    expect(auth.currentUser, 'ana');

    await auth.logout();
    expect(auth.isLoggedIn, isFalse);

    expect(await auth.login('ana', 'errada'), 'Usuário ou senha incorretos.');
    expect(auth.isLoggedIn, isFalse);

    expect(await auth.login('ANA', 'segredo'), isNull);
    expect(auth.currentUser, 'ana');
  });

  test('sessão é restaurada ao reabrir o app', () async {
    final store = await LocalStore.open();
    await buildAuth(store).register('ana', 'segredo');

    expect(buildAuth(store).currentUser, 'ana');
  });

  test('não permite usuário duplicado', () async {
    final store = await LocalStore.open();
    await buildAuth(store).register('ana', 'segredo');

    final error = await buildAuth(store).register('ANA', 'outra');

    expect(error, 'Esse nome de usuário já está em uso.');
  });

  test('login de usuário inexistente falha', () async {
    final auth = buildAuth(await LocalStore.open());

    expect(await auth.login('ninguem', 'segredo'), isNotNull);
  });

  test('senha não é salva em texto puro', () async {
    await buildAuth(await LocalStore.open()).register('ana', 'minhasenhasecreta');

    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getString('auth.users'), isNot(contains('minhasenhasecreta')));
  });

  test('isBusy fica ativo durante a autenticação', () async {
    final auth = buildAuth(await LocalStore.open());
    final busyStates = <bool>[];
    auth.addListener(() => busyStates.add(auth.isBusy));

    await auth.register('ana', 'segredo');

    expect(busyStates.first, isTrue);
    expect(auth.isBusy, isFalse);
  });
}
