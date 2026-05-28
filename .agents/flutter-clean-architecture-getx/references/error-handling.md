# Tratamento de erros

## Padrao base

```dart
abstract class Failure {
  final String message;
  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure(super.message);
}

class DatabaseFailure extends Failure {
  DatabaseFailure(super.message);
}
```

```dart
abstract class AccountRepository {
  Future<Either<Failure, List<AccountEntity>>> getAll();
}
```

```dart
class AccountRepositoryImpl implements AccountRepository {
  final AccountDatasource datasource;

  AccountRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, List<AccountEntity>>> getAll() async {
    try {
      final result = await datasource.fetchAll();
      return Right(result.map(AccountModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure('Falha ao buscar contas: $e'));
    }
  }
}
```

```dart
final result = await getAccounts();
result.fold(
  (failure) => errorMessage.value = failure.message,
  (accounts) => items.assignAll(accounts),
);
```

## Decisoes

- Usar mensagens tecnicas somente em log quando necessario.
- Expor para a UI mensagens curtas e acionaveis.
- Preferir uma hierarquia pequena e clara de `Failure`.
