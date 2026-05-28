# Config Contract: Ajuda com videos

## Videos

O catalogo da tela de Ajuda vem de `HELP_VIDEO_CATALOG_JSON`, com fallback local para um video de teste.

Formato esperado:

```json
{
  "id": "video-teste-ajuda",
  "title": "Video de teste",
  "description": "Video temporario para validar o player interno da tela de ajuda.",
  "youtubeVideoId": "HxgGW_ECu0w",
  "category": "Teste",
  "durationLabel": "Teste",
  "isFeatured": true,
  "sortOrder": 0
}
```

Regras:

- `youtubeVideoId` deve ser o identificador do video, nao a URL completa.
- URLs completas do YouTube podem ser aceitas como fallback e normalizadas para ID.
- A lista deve ser ordenada por `sortOrder`.
- O video deve ser reproduzido dentro do app.

## WhatsApp

Origem principal:

- Função Supabase `get_company_support_phone()`, lendo o numero da empresa salvo no painel em `User.companyPhone`.

Fallbacks:

- Leitura direta de `User.companyPhone`, quando permitido.
- `HELP_WHATSAPP_PHONE`.
- `HELP_WHATSAPP_URL`.

Regras:

- Se `HELP_WHATSAPP_URL` existir, ele tem prioridade sobre telefone montado.
- Se somente telefone existir, montar link `wa.me` com mensagem inicial opcional.
- Se nenhum contato existir, o FAB informa que o suporte ainda nao foi configurado.
