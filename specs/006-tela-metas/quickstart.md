# Quickstart: Tela de metas

## Objetivo

Implementar a feature `006-tela-metas` com entidade propria `Goal`, separada de `CostsGainsSettings`, seguindo Clean Architecture, SOLID e padrao de arquivos do app.

## Ordem recomendada

1. Backend/schema
   - Adicionar `GoalStatus` e `Goal` em `direcao_financeira_backend/prisma/schema.prisma`.
   - Criar migration Prisma `add_goals`.
   - Adicionar DTOs `create-goal.dto.ts` e `update-goal.dto.ts`.
   - Expandir `FinanceRepository`, `PrismaFinanceRepository`, `FinanceService` e `FinanceController`.

2. Mobile data/domain
   - Criar `GoalEntity`, `IGoalRepository`, `goal_use_cases.dart`.
   - Criar `GoalModel`, `IGoalDataSource`, `GoalRepository`.
   - Criar datasources `NestGoalRemoteDataSource` e `SupabaseGoalRemoteDataSource`.
   - Registrar `Goal` em `SupabaseTableNames` e `ProviderBinding`.

3. Mobile presentation
   - Criar modulo `presentation/modules/goals/`.
   - Adicionar `AppRoutes.goals` e `GetPage`.
   - Atualizar `SettingsController` para abrir `AppRoutes.goals`.
   - Atualizar `HomeBinding` e `HomeController` para carregar Goals reais.
   - Atualizar `GoalsSection` para remover mock/demo.

4. Testes
   - Domain: progresso e validacoes de `GoalEntity`.
   - Data: model/datasource/repository.
   - Presentation: `GoalsController`, Settings rota, Home sem mock.
   - Backend: service/controller/e2e do contrato `/finance/goals`.

## Comandos de verificacao

Mobile:

```powershell
flutter analyze
flutter test
```

Backend:

```powershell
cd ..\direcao_financeira_backend
npm run test
npm run build
```

## UAT manual

1. Abrir Settings.
2. Tocar em "Configurar Metas".
3. Confirmar que a tela real abre.
4. Criar uma Goal com nome e valor objetivo.
5. Editar valor atual e confirmar progresso.
6. Marcar como concluida.
7. Voltar para a Home e confirmar que "Minhas Metas" reflete dados reais.
8. Arquivar/remover a meta e confirmar que a Home nao mostra mock.

## Riscos

- Se apenas um provider for implementado, ambientes com outro `BackendProviderKind` podem quebrar.
- Se a Home continuar usando `controller.metas` mockado, a feature falha no criterio principal.
- Se regras de progresso ficarem em widgets/controller, a implementacao viola a constituicao do projeto.
