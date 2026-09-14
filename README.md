# Catálogo de Animes

Aplicativo Flutter do Somativo 1 da disciplina Desenvolvimento Mobile Híbrido (BSI, PUCPR).
Catálogo interativo de animes com login, favoritos, lista de assistidos, busca e persistência local.

## Tema e configuração

| Item | Escolha |
|---|---|
| Tema | Animes |
| API | [Kitsu](https://kitsu.docs.apiary.io/) (`https://kitsu.io/api/edge`), pública, sem chave e sem cadastro |
| Persistência | Local, com `shared_preferences` |
| Login | Local, usuário e senha guardados no dispositivo com hash SHA-256 |
| Verbo do RF07 | "Assistido" |

Endpoints usados:

| Uso | Requisição |
|---|---|
| Lista paginada | `GET /anime?page[limit]=20&page[offset]=N&sort=-userCount` |
| Busca | `GET /anime?filter[text]=termo&page[limit]=1` |
| Detalhe | `GET /anime/{id}?include=genres` |

## Como rodar

```bash
flutter pub get
flutter run -d chrome
```

Para Android, com um emulador ou aparelho conectado:

```bash
flutter run -d android
```

Testes e análise estática:

```bash
flutter analyze
flutter test
```

## Requisitos funcionais

| RF | Implementado | Arquivo principal |
|---|---|---|
| RF01 Catálogo e paginação | Sim | `lib/screens/catalog_screen.dart` |
| RF02 Navegação para detalhes | Sim | `lib/screens/catalog_screen.dart`, `lib/screens/detail_screen.dart` |
| RF03 Tela de detalhes | Sim | `lib/screens/detail_screen.dart` |
| RF04 Favoritos com Provider | Sim | `lib/providers/favorites_provider.dart` |
| RF05 Tela de favoritos | Sim | `lib/screens/favorites_screen.dart` |
| RF06 Persistência de dados | Sim | `lib/providers/anime_list_provider.dart`, `lib/services/local_store.dart` |
| RF07 Login e assistidos | Sim | `lib/providers/auth_provider.dart`, `lib/screens/watched_screen.dart` |
| RF08 Busca | Sim | `lib/screens/catalog_screen.dart`, `lib/services/anime_api_service.dart` |
| RF09 Feedback de UI | Sim | `lib/widgets/loading_view.dart`, `lib/widgets/error_view.dart` |
| RF10 Acessibilidade | Sim | `lib/widgets/anime_poster.dart`, `lib/widgets/anime_card.dart`, `lib/widgets/anime_grid.dart` |

## Estrutura

```
lib/
  main.dart          Monta os providers e inicia o app
  app.dart           MaterialApp, tema e MultiProvider
  models/            Anime, página de resultados e rótulos em português
  services/          Cliente da Kitsu, erros amigáveis e acesso ao armazenamento local
  providers/         Sessão do usuário, favoritos e assistidos
  screens/           Login, catálogo, detalhes, favoritos e assistidos
  widgets/           Grade, card, pôster e telas de carregamento, erro e vazio
test/                Testes de modelo, serviço, providers e widgets
```

## Observações

O login é local e serve apenas ao fluxo de sessão do trabalho. A senha não é guardada
em texto puro, mas o app não faz autenticação real contra um servidor.
