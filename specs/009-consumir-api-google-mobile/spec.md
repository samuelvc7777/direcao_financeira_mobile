# Feature Specification: Consumir API Google do Admin no Mobile

**Feature Branch**: `009-consumir-api-google-mobile`  
**Created**: 2026-05-27  
**Status**: Draft  
**Input**: User description: "vamos entao consumir no mobile aonde usamos a API Google cadastrada no admin"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Usar API Google centralizada nos fluxos de corrida (Priority: P1)

Como motorista usando o app, quero que os recursos que dependem da API Google usem a chave configurada no admin, para que o app seja atualizado sem precisar novo build quando a chave mudar.

**Why this priority**: Hoje os fluxos de endereco, rota, OCR/print e servico nativo usam a chave local do ambiente. Centralizar evita divergencia entre admin e mobile.

**Independent Test**: Alterar a API Google no admin, abrir o app mobile, acessar fluxos de importar print/adicionar corrida e confirmar que os servicos usam a chave atualizada.

**Acceptance Scenarios**:

1. **Given** que existe API Google cadastrada no admin, **When** o app inicializa e carrega configuracoes remotas, **Then** os servicos de endereco, rota e OCR/print usam a API remota ativa.
2. **Given** que a API Google foi alterada no admin, **When** o app recarrega as configuracoes, **Then** os fluxos passam a usar o novo valor sem rebuild.

---

### User Story 2 - Manter funcionamento com fallback local (Priority: P2)

Como usuario, quero que o app continue funcionando quando a configuracao remota nao puder ser carregada, para evitar bloqueio em rede instavel.

**Why this priority**: A API remota melhora operacao, mas uma falha temporaria nao deve quebrar recursos que ja funcionavam com chave local.

**Independent Test**: Simular erro ou ausencia da configuracao remota e confirmar que o app usa a chave local existente.

**Acceptance Scenarios**:

1. **Given** que a configuracao remota falha, **When** o app tenta preparar os servicos Google, **Then** ele usa a chave local como fallback.
2. **Given** que nao existe API Google remota cadastrada, **When** o app inicializa, **Then** ele nao quebra e usa o fallback disponivel.

---

### User Story 3 - Sincronizar chave com o servico nativo de OCR (Priority: P3)

Como usuario do semaforo/OCR em background, quero que o servico nativo receba a mesma API Google ativa do app, para que o OCR e rotas associadas fiquem consistentes com o admin.

**Why this priority**: O fluxo nativo hoje recebe a chave do ambiente pelo canal de configuracoes; ele precisa acompanhar a configuracao centralizada.

**Independent Test**: Atualizar a chave no admin, reiniciar/retomar o app e confirmar que o payload enviado ao nativo contem a chave remota ativa.

**Acceptance Scenarios**:

1. **Given** que o app carregou uma API Google remota, **When** sincroniza configuracoes com o nativo, **Then** envia a chave remota no campo esperado.
2. **Given** que a API remota nao esta disponivel, **When** sincroniza configuracoes com o nativo, **Then** envia a chave local de fallback.

### Edge Cases

- Configuracao remota demora para responder durante a inicializacao do app.
- Usuario abre a tela de importar print antes da configuracao remota finalizar.
- API Google remota vem vazia, nula ou com espacos.
- App fica offline ou recebe erro de permissao na leitura da configuracao.
- Servico nativo ja esta ativo quando uma nova chave e carregada.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O app MUST carregar a API Google ativa cadastrada no admin quando houver conexao e sessao/configuracao valida.
- **FR-002**: O app MUST expor uma unica fonte resolvida de API Google para os fluxos que hoje usam `googleMapsApiKey`.
- **FR-003**: Os fluxos de adicionar corrida e importar print MUST usar a fonte resolvida da API Google, nao apenas o valor fixo do ambiente.
- **FR-004**: A sincronizacao com o servico nativo MUST enviar a API Google resolvida.
- **FR-005**: Se a configuracao remota estiver ausente, vazia ou falhar, o app MUST usar a chave local existente como fallback.
- **FR-006**: O app MUST normalizar a API Google removendo espacos antes de decidir se ela e valida para uso.
- **FR-007**: A leitura remota MUST evitar bloquear indefinidamente a abertura do app ou das telas afetadas.
- **FR-008**: A implementacao MUST preservar os limites de Clean Architecture entre core/config, data, domain e presentation.

### Key Entities *(include if feature involves data)*

- **GoogleApiConfig**: Configuracao operacional com a API Google ativa retornada pelo admin.
- **ResolvedGoogleApiKey**: Valor final que o app usa apos aplicar prioridade remota e fallback local.

### Business Rules *(include when relevant)*

- **BR-001**: API Google remota valida tem prioridade sobre a chave local.
- **BR-002**: API Google vazia, nula ou composta so por espacos nao substitui o fallback local.
- **BR-003**: Falha de rede/configuracao nao deve impedir usuario de continuar usando os fluxos existentes com fallback.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos pontos atuais que usam `googleMapsApiKey` passam a usar a fonte resolvida.
- **SC-002**: Em teste com configuracao remota valida, importar print/adicionar corrida usam a chave cadastrada no admin sem rebuild.
- **SC-003**: Em teste com configuracao remota indisponivel, os fluxos continuam usando a chave local sem erro visivel ao usuario.
- **SC-004**: A sincronizacao nativa recebe a mesma chave resolvida usada pelos servicos Dart.

## Assumptions

- O admin ja persiste `Company.googleApiKey` e disponibiliza a configuracao ativa.
- O mobile pode consultar a mesma fonte Supabase/admin usada para configuracoes globais.
- A chave local atual em `AppEnvironment.googleMapsApiKey` permanece como fallback.
- O OCR local por ML Kit continua sem depender diretamente da API Google; a chave impacta servicos Google auxiliares usados nos fluxos de corrida/print.
