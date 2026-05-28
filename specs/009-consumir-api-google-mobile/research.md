# Research - Consumir API Google do Admin no Mobile

## Decisao 1: Fonte remota via tabela Company

- Decision: Ler `Company.googleApiKey` no Supabase, registro singleton `id = 1`.
- Rationale: O admin ja salva esse valor nessa fonte de verdade, seguindo o padrao global de metadados da empresa.
- Alternatives considered: chamar endpoint do admin web diretamente; rejeitado por acoplar o mobile ao deploy do painel e exigir token de admin.

## Decisao 2: Fallback local permanece ativo

- Decision: Manter `AppEnvironment.googleMapsApiKey` como fallback quando o remoto estiver indisponivel, vazio ou invalido.
- Rationale: O app ja funciona com chave local; remover fallback poderia quebrar usuario em rede instavel ou antes da primeira sincronizacao.
- Alternatives considered: bloquear os fluxos ate carregar remoto; rejeitado por piorar UX e contrariar FR-007.

## Decisao 3: Resolver chave em dependencia compartilhada

- Decision: Registrar um servico/use case de chave resolvida no binding central e usa-lo nos bindings da Jornada e no `AccessibilityController`.
- Rationale: Evita duplicar regra de prioridade em varios pontos e mantem controllers/views longe da regra de negocio.
- Alternatives considered: chamar datasource direto nos bindings; rejeitado por espalhar logica de fallback.

## Decisao 4: OCR ML Kit continua local

- Decision: Nao alterar o mecanismo de OCR local; a chave Google impacta servicos auxiliares de Maps/Routes/autocomplete e sincronizacao nativa.
- Rationale: O OCR atual usa ML Kit local e nao precisa da API key para processar imagem. A feature e sobre configuracao Google ja usada pelo app.
- Alternatives considered: trocar OCR para API remota Google Vision; fora do escopo e mudaria custo, privacidade e arquitetura.
