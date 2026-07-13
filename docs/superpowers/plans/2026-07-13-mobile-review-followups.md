# Mobile Review Follow-ups — S2, A4/C7, C8, A5

**Goal:** Corrigir follow-ups restantes do review `docs/reviews/2026-07-12-review-mobile-flutter.md` que não dependem de decisão de produto: S2, A4/C7, C8, A5.

**Fora de escopo:** A3 (camada de models — decisão), S3 (debug TEMP — depende do teste no device), L3 (identidade do app), P1/P2/P3.

---

### Task 1: S2 — Refresh não envia Authorization velho

`api_client.dart`: `onRequest` pula auth headers quando `options.extra['skipAuth'] == true`; `_doRefresh` marca o request com essa flag.
Teste: `api_client_test.dart` — onRequest com skipAuth não adiciona Authorization nem lê o storage.

### Task 2: A4/C7 — Regra "upcoming" na entity com tryParse

`appointment.dart`: getters `startDateTime` (`DateTime.tryParse`, null se malformado) e `isUpcoming` (status ativo + futuro; false se data inválida). `isCancellable` reusa. `my_appointments_screen.dart` e `home_bloc.dart` passam a usar os getters (remove duplicação e `DateTime.parse` cru no build).
Teste: `test/features/appointments/domain/appointment_test.dart` (novo).

### Task 3: C8 — Cast seguro de `state.extra` no router de booking

`app_router.dart`: ShellRoute de booking faz `state.extra as Service?`; null (restore de processo) → tela stub que redireciona para `/services` em vez de `TypeError`.
Teste: widget test navegando para `/booking/date` sem extra espera redirect.

### Task 4: A5 — Logout via SessionCubit

`core/auth/session_cubit.dart` (novo): `logout()` limpa token+tenant; `expireTokens()` limpa só tokens. `HomeScreen` deixa de receber storages; usa o cubit provido na rota `/home`.
Teste: `test/core/auth/session_cubit_test.dart` (novo) + ajustar `home_screen_test.dart`.

### Task 5: Verificação final

`flutter analyze` + `flutter test` completos; atualizar nota no review.
