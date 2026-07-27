<img width="370" height="800" alt="image" src="https://github.com/user-attachments/assets/2c49dc7a-2a6d-4a5a-a37f-859982fd4f81" />

# baber_mobile

App Flutter do cliente da plataforma de barbearia (multi-tenant). Consome a API do monorepo `baber` (NestJS). Painel admin web e API vivem no outro repo.

## Stack

- **Flutter** (Dart SDK ^3.12) — Android + iOS.
- **Estado** — flutter_bloc + equatable.
- **Navegação** — go_router (deep links via app_links).
- **HTTP** — dio (client em `core/api`, tokens em flutter_secure_storage).
- **Auth** — Firebase Auth (phone/OTP, projeto `baber-fundation`; iOS exige URL scheme do reCAPTCHA).
- **Erros funcionais** — dartz (`Either`).
- **Testes** — flutter_test + bloc_test + mocktail.

## Arquitetura

Feature-first com camadas clean (`data` / `domain` / `presentation`) por feature:

```
lib/
  main.dart               entrypoint (lê API_BASE_URL via --dart-define)
  baber_app.dart          MaterialApp.router + tema
  core/
    api/                  dio client (auth headers, refresh de token)
    auth/                 sessão (SessionCubit: logout, limpeza de tokens)
    config/               base_url_guard
    firebase/             init Firebase
    router/               go_router (redirects de auth/tenant)
    tenancy/              tenant ativo
  features/
    splash/               boot + decisão de rota inicial
    tenant_selection/     escolha da barbearia (multi-tenant)
    auth/                 login por telefone (Firebase OTP)
    home/                 shell pós-login
    catalog/              serviços da barbearia
    booking/              fluxo de agendamento (serviço → barbeiro → horário)
    appointments/         meus agendamentos (regra de "próximos" no domain)
    notifications/        notificações
    profile/              perfil do cliente
  shared/                 theme, utils, widgets
test/                     espelha lib/ (core, features, shared)
```

Regras:

- `domain/` não importa `data/` nem `presentation/`.
- Toda chamada à API passa pelo client de `core/api` (injeta auth headers; refresh de token não envia headers de auth).
- Feature nova segue o mesmo esqueleto `data`/`domain`/`presentation`.

## Setup

Pré-requisitos: Flutter SDK, API do repo `baber` rodando (local ou Fly.io), emulador Android (AVD `baber_phone`) ou device.

```bash
flutter pub get

# rodar apontando para API local
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000   # emulador Android
flutter run --dart-define=API_BASE_URL=http://localhost:3000  # iOS simulator
```

`API_BASE_URL` default é `http://localhost:3000` (só funciona no iOS simulator; emulador Android precisa de `10.0.2.2`).

Firebase já configurado via FlutterFire (`lib/firebase_options.dart`, `firebase.json`). Phone auth usa reCAPTCHA como fallback — no iOS o URL scheme (`REVERSED_CLIENT_ID`) precisa estar no `Info.plist` (já registrado).

## Comandos

| Comando                  | Ação                          |
|--------------------------|-------------------------------|
| `flutter run`            | roda no device/emulador       |
| `flutter test`           | testes (bloc_test + mocktail) |
| `flutter analyze`        | lint (flutter_lints)          |
| `flutter build apk`      | build Android                 |
| `flutter build ios`      | build iOS (requer macOS)      |

## Docs

- `docs/reviews/` — reviews de código e follow-ups.
