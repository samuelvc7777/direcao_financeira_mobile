# Server Client Boundaries

## Escolha rapida

- Usar `Server Component` para leitura inicial, seguranca de dados e composicao do shell da pagina.
- Usar `Client Component` para estado local, eventos, browser APIs, animações e interacoes ricas.
- Usar `Server Action` para mutacao disparada pela interface dentro do App Router.
- Usar `Route Handler` para endpoints publicos, webhooks, integracoes maquina-a-maquina ou contratos HTTP explicitos.

## Perguntas de decisao

1. O codigo precisa acessar segredo, banco ou recurso privado?
   Entao manter no servidor.
2. O codigo precisa de `useState`, `useEffect`, DOM ou evento de clique complexo?
   Entao usar cliente apenas nessa fatia.
3. A mutacao nasce de um formulario ou acao de UI interna?
   Entao considerar `Server Action`.
4. A mutacao precisa ser consumida por app externo ou outro cliente HTTP?
   Entao considerar `Route Handler`.

## Regras praticas

- Fazer o menor componente possivel virar cliente.
- Nao promover a pagina inteira para cliente sem necessidade real.
- Nao colocar regra de negocio em `use client`.
- Nao vazar objetos de infraestrutura para componentes visuais.
- Centralizar invalidacao de cache junto da mutacao bem-sucedida.
- Tratar autorizacao na borda do servidor antes de executar o caso de uso.

## Exemplo mental

`page.tsx` consulta o caso de uso de listagem no servidor.
Um formulario cliente envia a mutacao para uma `Server Action`.
A action valida input, chama o caso de uso, revalida cache e retorna estado amigavel para a UI.
