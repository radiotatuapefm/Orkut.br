# Playlists do Orkut - Documentação

## Visão Geral

O sistema de playlists do Orkut permite integrar playlists do Spotify diretamente na plataforma, trazendo a nostalgia musical dos anos 2000 para os usuários.

## Componentes

### OrkutPlaylist

Componente principal para exibir playlists em tamanho completo.

```tsx
import OrkutPlaylist from '@/components/OrkutPlaylist';

<OrkutPlaylist
  playlistId="2a7srdzr6N0teReSG1i7vJ"
  title="Nostalgia dos Anos 2000"
  description="As músicas que marcaram época no Orkut"
  theme="0" // 0 = dark, 1 = light
/>
```

**Props:**
- `playlistId` (string, optional): ID da playlist do Spotify
- `title` (string, optional): Título da playlist
- `description` (string, optional): Descrição da playlist
- `theme` ('0' | '1', optional): Tema do player (dark/light)

### OrkutPlaylistMini

Componente compacto para usar em sidebars ou cards menores.

```tsx
import OrkutPlaylistMini from '@/components/OrkutPlaylistMini';

<OrkutPlaylistMini
  playlistId="2a7srdzr6N0teReSG1i7vJ"
  title="Nostalgia 2000s"
  trackCount={50}
  showHeader={true}
/>
```

**Props:**
- `playlistId` (string, optional): ID da playlist do Spotify
- `title` (string, optional): Título da playlist
- `trackCount` (number, optional): Número de músicas na playlist
- `showHeader` (boolean, optional): Se deve mostrar o cabeçalho

## Como obter IDs de Playlists do Spotify

1. Acesse uma playlist no Spotify Web Player
2. Clique em "Compartilhar" > "Copiar link da playlist"
3. O ID estará no formato: `https://open.spotify.com/playlist/[ID_AQUI]?si=...`
4. Extraia apenas o ID da URL

## Playlists Pré-configuradas

O sistema vem com algumas playlists temáticas:

- **Nostalgia dos Anos 2000**: `2a7srdzr6N0teReSG1i7vJ`
- **Rock Clássico**: `37i9dQZF1DX0XUsuxWHRQd`
- **Pop dos Anos 2000**: `37i9dQZF1DWXRqgorJj26U`
- **Hits Brasileiros**: `37i9dQZF1DWYmmr74INQlb`

## Integração com a Navegação

O link para playlists está disponível na navbar principal:

```tsx
{ icon: Music, label: 'playlists', href: '/playlists' }
```

## Página de Playlists

A página `/playlists` oferece:

- Visualização de múltiplas playlists
- Estatísticas de uso
- Interface para criar novas playlists
- Call-to-action para conectar conta do Spotify

## Personalização

### Temas

- `theme="0"`: Tema escuro (padrão)
- `theme="1"`: Tema claro

### Estilos

Os componentes usam as classes CSS do projeto:
- Cores: `purple-500`, `pink-500`, `gray-800`
- Cards: `OrkutCard`, `OrkutCardHeader`, `OrkutCardContent`
- Botões: Componente `Button` com variantes

## Funcionalidades Futuras

- [ ] Integração com API do Spotify para playlists personalizadas
- [ ] Sistema de favoritos
- [ ] Criação de playlists colaborativas
- [ ] Histórico de músicas tocadas
- [ ] Recomendações baseadas no perfil do usuário

## Notas Técnicas

- Os iframes do Spotify são carregados com `loading="lazy"` para melhor performance
- Suporte completo a responsividade
- Integração com sistema de design do Orkut
- Compatível com Next.js 13+ e App Router
