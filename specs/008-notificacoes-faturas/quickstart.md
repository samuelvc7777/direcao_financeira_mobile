# Quickstart: Notificacoes de Faturas

## Objetivo

Validar que notificacoes locais Android de faturas sao agendadas, deduplicadas e exibidas corretamente com app aberto ou fechado.

## Pre-requisitos

- Android com notificacoes do app permitidas.
- Cartao ativo cadastrado com `closingDay` e `dueDay`.
- Fatura com valor pendente para cenarios de vencimento/atraso.

## Fluxo de Desenvolvimento

1. Rodar analise estatica:

```powershell
flutter analyze
```

2. Rodar testes de dominio e data da feature:

```powershell
flutter test test/app/domain test/app/data
```

3. Rodar testes de presentation se houver superficie visual nova:

```powershell
flutter test test/app/presentation
```

4. Validar build Android:

```powershell
flutter build apk --debug
```

## Cenarios Manuais

### Permissao

1. Instalar o app em Android 13+.
2. Negar notificacoes.
3. Abrir o app e confirmar que o uso normal continua.
4. Conceder notificacoes e confirmar que os avisos podem ser reagendados.

### Fechamento

1. Configurar cartao ativo com fechamento hoje.
2. Garantir fatura relevante para revisao.
3. Simular ou aguardar o horario planejado.
4. Confirmar notificacao de fechamento e acao para revisar o cartao.

### Vencimento

1. Configurar cartao ativo com vencimento hoje.
2. Garantir fatura com valor pendente.
3. Confirmar notificacao as 10h.
4. Pagar a fatura e confirmar que nao ha nova notificacao para o mesmo evento.

### Atraso

1. Criar fatura vencida com valor pendente.
2. Confirmar aviso diario as 10h.
3. Pagar parcialmente e confirmar que o aviso continua enquanto houver saldo.
4. Pagar integralmente e confirmar que o aviso para.

### App fechado e reinicio

1. Agendar aviso futuro.
2. Fechar o app.
3. Confirmar notificacao no horario planejado.
4. Reiniciar o aparelho.
5. Confirmar que os avisos futuros sao reprogramados.

## Evidencia Esperada

- Testes automatizados passando.
- APK debug gerado.
- Logs ou prints mostrando permissao, agendamento e dedupe.
- Validacao manual em aparelho Android para app fechado e reinicio.
