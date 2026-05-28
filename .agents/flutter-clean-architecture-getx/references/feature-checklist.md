# Checklist de feature

- Existe `Entity` clara para o caso de uso.
- O contrato do repository esta no `domain`.
- O `usecase` tem responsabilidade unica.
- O `repository_impl` encapsula falhas tecnicas.
- O controller trata loading, sucesso e erro.
- A page nao conhece datasource ou excecoes tecnicas.
- O binding registra toda a cadeia de dependencias.
- O nome dos arquivos segue um padrao consistente.
