# Quickstart - Consumir API Google do Admin no Mobile

## Pre-condicoes

- Coluna `Company.googleApiKey` aplicada no Supabase.
- Admin web com API Google salva em Configuracoes.
- App mobile usando backend Supabase.

## Validacao automatizada

1. Rodar testes de resolucao da chave remota vs fallback.
2. Rodar testes de datasource para leitura de `Company.googleApiKey`.
3. Rodar testes de sincronizacao nativa do `AccessibilityController`.
4. Executar `flutter analyze`.

## Validacao manual

1. Salvar uma API Google no admin.
2. Abrir o app mobile e restaurar sessao.
3. Entrar em `Jornada > Adicionar corrida` e confirmar autocomplete/rota sem erro.
4. Entrar em `Jornada > Importar print` e confirmar fluxo sem usar chave hardcoded quando remoto existe.
5. Ativar/retomar o semaforo e confirmar sincronizacao com nativo.
6. Remover ou invalidar temporariamente o valor remoto e confirmar fallback local.

## Criterios de pronto

- Todos os usos de `googleMapsApiKey` foram revisados.
- Servicos Dart e nativo usam a mesma chave resolvida.
- Fallback local cobre erro remoto sem travar tela.
- Testes e `flutter analyze` passam.

## Pendencia manual

- Validar em device/emulador Android que o semaforo/OCR ativo recebe a chave resolvida depois de abrir/retomar o app, porque o teste automatizado cobre o payload do canal nativo, mas nao executa o servico Android real.
