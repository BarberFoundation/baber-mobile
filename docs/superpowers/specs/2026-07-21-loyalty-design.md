# Loyalty (cartão fidelidade + clube de assinatura) no app mobile — Design

## Contexto

O módulo `loyalty` já existe completo na API (`baber` monorepo): cartão fidelidade
(carimbos + crédito) e clube de assinatura (planos, ativação via Asaas, cotas por
ciclo, cancelamento). O app mobile (CLIENT) não tem nenhuma tela pra isso ainda —
essa é a última pendência de paridade entre API e mobile (demais módulos —
scheduling, catalog, notifications, identity, tenants — já estão cobertos).

## Escopo

1. Backend (monorepo `baber`): 1 endpoint novo pro CLIENT listar planos com preço
   calculado (hoje só existe versão ADMIN, sem preço).
2. Mobile (`baber-mobile`): feature `loyalty` nova, seguindo o padrão de
   `catalog`/`booking` (domain/data/presentation), 1 atalho novo na Home.

Fora de escopo: pagamento in-app (Asaas já lida com isso via PIX/boleto fora do
app), notificação push de cobrança/renovação (fica pro módulo `notifications`
existente, sem mudança aqui), edição de planos (é tela ADMIN, já existe no web).

## 1. Backend — endpoint novo

`GET /loyalty/club-subscription/tiers/available`, `@Roles('CLIENT')`.

Novo use case `GetAvailableSubscriptionTiersUseCase`:
- Busca tiers do tenant, filtra só `isActive`.
- Para cada tier, busca preços no catálogo (mesmo padrão de
  `activate-club-subscription.use-case.ts`) e calcula
  `monthlyPriceInCents = tier.calculatePriceInCents(catalogPrices)`.
- Retorna: `{ tier, services: [{ serviceId, quantity, priceInCents }], monthlyPriceInCents, discountPercentage }[]`.

O endpoint ADMIN (`GET tiers`) não muda — serve outro propósito (edição, inclui
tiers inativos, sem preço calculado).

## 2. Mobile — feature `loyalty`

```
lib/features/loyalty/
  domain/
    stamp_card.dart              // currentStamps, stampsRequired, creditBalanceInCents
    subscription_tier.dart       // tier, services[], monthlyPriceInCents, discountPercentage
    club_subscription.dart       // status, tierId, currentCycleStart/End, quotas[]
    loyalty_repository.dart      // interface
  data/
    loyalty_repository_impl.dart // Dio via api_client.dart existente
  presentation/
    loyalty_bloc.dart / loyalty_event.dart / loyalty_state.dart
    loyalty_hub_screen.dart
    subscription_plans_screen.dart
    activate_subscription_screen.dart
```

### Navegação

Home ganha 4º atalho "Clube" (ícone `Icons.workspace_premium_outlined`), ao lado
de Serviços/Consultas/Notificações, roteando pra `/loyalty` (rota nova no
`app_router.dart`).

### `loyalty_hub_screen.dart` — tela principal

Ao entrar, dispara `GET /loyalty/club-subscription/me` e
`GET /loyalty/stamp-card/me` em paralelo.

- `club-subscription/me` responde 404 (`ClubSubscriptionNotFoundError`) → não é
  erro, é o estado "sem assinatura". Mostra:
  - Cartão fidelidade: progresso (`currentStamps`/`stampsRequired`), saldo de
    crédito (`creditBalanceInCents`), botão "Usar crédito" (resgata o saldo
    inteiro de uma vez, com confirmação — é só bookkeeping, o desconto real
    acontece no balcão). Botão desabilitado se saldo = 0.
  - Botão "Ver planos" → `subscription_plans_screen.dart`.
- `club-subscription/me` responde 200, `status: ACTIVE` ou `PAST_DUE` → mostra
  card da assinatura: nome do tier, ciclo atual (`currentCycleStart` –
  `currentCycleEnd`), cotas por serviço ("Corte: 1/2 usado no ciclo") — cruza
  `quotas[].serviceId` com a lista de serviços já carregada pelo
  `ServiceRepository` existente (feature `catalog`) pra pegar o nome. `PAST_DUE`
  soma um banner de aviso (pagamento atrasado). Botão "Cancelar assinatura"
  (confirma antes, `POST /cancel`, volta pro estado sem-assinatura).
  Regra de negócio já existente no backend: se tem assinatura ativa, não pode
  ter progresso no cartão fidelidade ao mesmo tempo — então nesse estado o
  cartão fidelidade não é mostrado.

### `subscription_plans_screen.dart`

Lista os tiers de `GET tiers/available` (nome, serviços inclusos + quantidade,
preço mensal, % desconto). Botão "Assinar" por plano → `activate_subscription_screen.dart`.

### `activate_subscription_screen.dart`

Form: nome (pré-preenchido do perfil, editável), CPF/CNPJ (obrigatório, campo
novo — não existe em nenhum lugar do app hoje, não é persistido no perfil,
usado só nessa chamada), email e telefone (opcionais, pré-preenchidos se
disponíveis). Submit → `POST activate` com o tier escolhido → sucesso volta pro
hub (já mostrando a assinatura ativa).

## Tratamento de erros

- 404 em `GET club-subscription/me` → estado normal (sem assinatura), não
  aciona tela de erro genérica.
- Falha de rede/outros erros → segue o padrão já usado em `appointments`/`catalog`
  (retry UI existente via `DioFailureMapper`/`Failure`).
- `ClubSubscriptionAlreadyActiveError`/`ClubSubscriptionBlockedByStampCardError`
  (o backend já valida) → mensagem de erro amigável no form de ativação.

## Testes

- Backend: spec unitário do novo use case (tiers ativos, preço calculado,
  tiers inativos excluídos) + spec do controller (`@Roles('CLIENT')`, 200/401).
- Mobile: bloc tests (padrão já usado em `services_bloc`/`booking_bloc`) pros 3
  estados do hub (sem assinatura, ativa, past due) + teste do fluxo de
  ativação (form válido/inválido) + teste do redeem (saldo zerado desabilita
  botão).
