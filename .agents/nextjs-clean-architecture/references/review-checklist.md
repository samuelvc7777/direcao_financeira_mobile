# Review Checklist

## Checklist final

- A regra de negocio esta fora de `app/` e fora dos componentes visuais.
- O dominio nao depende de Next.js, React, ORM ou SDK externo.
- Os casos de uso recebem contratos abstratos e nao implementacoes concretas.
- Existe separacao clara entre DTO, entidade e modelo de persistencia quando necessario.
- O ponto de entrada escolhido faz sentido: Server Component, Client Component, Server Action ou Route Handler.
- A validacao de entrada ocorre na borda e nao esta espalhada.
- O tratamento de erro nao vaza detalhes tecnicos desnecessarios para a UI.
- A estrategia de cache e revalidacao foi decidida conscientemente.
- O acoplamento com `Prisma`, `Drizzle`, `Supabase`, `fetch` ou SDK externo esta isolado.
- Existe caminho claro para testes do caso de uso sem depender de Next.js.
- A feature segue nomes e pastas consistentes com o restante do modulo.

## Sinais de alerta

- Arquivos de rota grandes demais concentrando negocio, validacao e acesso a dados.
- Repeticao de mapeamento manual em varios pontos por falta de presenter ou mapper.
- Uso excessivo de `any` entre camadas.
- Dependencias circulares entre modulo, UI e infraestrutura.
- Componentes cliente importando funcoes que deveriam estar restritas ao servidor.
