# direcao_financeira_mobile Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-05-28

## Active Technologies
- Dart 3.11.1 / Flutter 3.x + Flutter, GetX, geolocator, flutter_background_service, socket_io_client, google_mlkit_text_recognition, image_picker, intl (002-otimizacao-performance-bateria)
- Dart 3.11.1 / Flutter 3.x + Flutter, GetX, intl, dartz, Supabase via os repositorios/datasources atuais, widgets compartilhados do app (003-pagamento-total-parcial-fatura)
- Supabase transactions table via `TransactionDataSource` e `SupabaseTransactionRemoteDatasource`; nao ha novo schema previsto (003-pagamento-total-parcial-fatura)
- Dart 3.11.1 / Flutter 3.x + Flutter, GetX, GetStorage, Supabase Flutter, Dio, google_mlkit_text_recognition (009-consumir-api-google-mobile)
- Supabase para configuracao remota `Company.googleApiKey`; `AppEnvironment.googleMapsApiKey` como fallback local (009-consumir-api-google-mobile)
- Dart 3.11.1 / Flutter 3.x + Flutter, GetX, dartz, GetStorage, Supabase/Nest via repositorios existentes, componentes visuais atuais do app (010-bloqueio-assinatura)
- assinatura atual em cache de usuario e fonte remota de assinatura via `ISubscriptionRepository`; nenhum novo schema previsto (010-bloqueio-assinatura)
- Dart 3.11.1 / Flutter 3.x + Flutter, GetX, in_app_update, url_launcher, flutter_test (011-banner-atualizacao-global)
- N/A para o MVP; cancelamento vale apenas em memoria na sessao atual (011-banner-atualizacao-global)

- Dart 3.11.1 / Flutter 3.x + Flutter, GetX, dartz, dio, intl, currency_text_input_formatter, supabase_flutter (001-importar-entradas-corridas)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Dart 3.11.1 / Flutter 3.x

## Code Style

Dart 3.11.1 / Flutter 3.x: Follow standard conventions

## Recent Changes
- 011-banner-atualizacao-global: Added Dart 3.11.1 / Flutter 3.x + Flutter, GetX, in_app_update, url_launcher, flutter_test
- 010-bloqueio-assinatura: Added Dart 3.11.1 / Flutter 3.x + Flutter, GetX, dartz, GetStorage, Supabase/Nest via repositorios existentes, componentes visuais atuais do app
- 009-consumir-api-google-mobile: Added Dart 3.11.1 / Flutter 3.x + Flutter, GetX, GetStorage, Supabase Flutter, Dio, google_mlkit_text_recognition


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
