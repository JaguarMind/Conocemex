# CONOCEMEX — Guia de Implementacion de Chat para el Cliente (Next.js PWA)

> **Equipo:** JaguarMind — Hackathon Talent Land Mexico 2026
> **Audiencia:** Desarrollador frontend Next.js (app del turista/cliente)
> **Estado:** Comunidades funcionales. Chat 1 a 1 pendiente (requiere tablas nuevas en BD).

---

## 1. Resumen

La app del vendedor (Flutter) ya tiene implementado:
- Chat grupal en comunidades con mensajes en tiempo real
- Traduccion automatica de mensajes al idioma del usuario via DeepL
- Sistema de invitacion por codigo para unirse a comunidades
- Crear comunidades con auto-join como admin
- Seccion placeholder para chat directo 1 a 1 (pendiente de BD)

Tu trabajo es replicar esta funcionalidad en la PWA del turista/cliente con Next.js + Supabase.

---

## 2. Tablas de la BD (ya existen)

### `communities`
| Columna | Tipo | Descripcion |
|---|---|---|
| `id` | uuid PK | |
| `creator_id` | uuid FK→profiles | Quien la creo |
| `name` | text | Nombre visible |
| `slug` | text UNIQUE | Formato: `{nombre-slugificado}-{codigo6chars}`. **Es el codigo de invitacion** |
| `description` | text | Opcional |
| `icon_url` | text | Opcional |
| `cover_image_url` | text | Opcional |
| `member_count` | integer | Mantenido por trigger automatico |
| `is_active` | boolean | Default true |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |

### `community_members`
| Columna | Tipo | Descripcion |
|---|---|---|
| `community_id` | uuid PK, FK | |
| `profile_id` | uuid PK, FK | |
| `role` | community_role | `member`, `moderator`, `admin` |
| `joined_at` | timestamptz | |

### `community_messages`
| Columna | Tipo | Descripcion |
|---|---|---|
| `id` | uuid PK | |
| `community_id` | uuid FK | |
| `sender_id` | uuid FK→profiles | |
| `content` | text | Texto del mensaje |
| `shared_business_id` | uuid | Opcional, para compartir negocios |
| `shared_route_id` | uuid | Opcional, para compartir rutas |
| `reply_to_id` | uuid | Opcional, respuesta a otro mensaje |
| `is_deleted` | boolean | Soft delete |
| `created_at` | timestamptz | |

### `message_reactions`
| Columna | Tipo | Descripcion |
|---|---|---|
| `message_id` | uuid PK, FK | |
| `profile_id` | uuid PK, FK | |
| `emoji` | text PK | 1-16 chars |
| `created_at` | timestamptz | |

### RLS activo
- **SELECT** mensajes: solo si eres miembro de la comunidad Y `is_deleted = false`
- **INSERT** mensajes: solo si `sender_id = auth.uid()` y eres miembro
- **UPDATE** mensajes: solo si eres el autor
- **community_members**: self-join y self-leave permitidos

---

## 3. Flujos a implementar

### 3.1 — Listar mis comunidades

```ts
const { data } = await supabase
  .from('community_members')
  .select('community_id, role, communities(id, name, description, slug, member_count, creator_id)')
  .eq('profile_id', user.id)
  .order('joined_at', { ascending: false });

// Mapear
const myCommunities = data.map(row => ({
  ...row.communities,
  my_role: row.role,
}));
```

### 3.2 — Crear comunidad

```ts
// 1. Generar invite code
const inviteCode = Array.from({ length: 6 }, () =>
  'abcdefghijklmnopqrstuvwxyz0123456789'[Math.floor(Math.random() * 36)]
).join('');

const slug = name
  .toLowerCase()
  .replace(/[^a-z0-9\s-]/g, '')
  .replace(/\s+/g, '-')
  .replace(/-+/g, '-');

// 2. Insertar comunidad
const { data: community } = await supabase
  .from('communities')
  .insert({
    creator_id: user.id,
    name,
    slug: `${slug}-${inviteCode}`,
    description,
  })
  .select()
  .single();

// 3. Auto-join como admin
await supabase.from('community_members').insert({
  community_id: community.id,
  profile_id: user.id,
  role: 'admin',
});

// El slug completo ES el codigo de invitacion
const inviteCodeToShare = community.slug;
```

### 3.3 — Unirse por codigo de invitacion

```ts
const code = inputCode.trim().toLowerCase();

// Buscar comunidad por slug
const { data: community } = await supabase
  .from('communities')
  .select('id, name, slug')
  .or(`slug.eq.${code},slug.ilike.%${code}`)
  .eq('is_active', true)
  .maybeSingle();

if (!community) throw new Error('Codigo de invitacion no valido');

// Verificar si ya es miembro
const { data: existing } = await supabase
  .from('community_members')
  .select('community_id')
  .eq('community_id', community.id)
  .eq('profile_id', user.id)
  .maybeSingle();

if (existing) throw new Error('Ya eres miembro de esta comunidad');

// Unirse
await supabase.from('community_members').insert({
  community_id: community.id,
  profile_id: user.id,
  role: 'member',
});
```

### 3.4 — Salir de una comunidad

```ts
await supabase
  .from('community_members')
  .delete()
  .eq('community_id', communityId)
  .eq('profile_id', user.id);
```

### 3.5 — Mensajes en tiempo real

```ts
// Suscripcion con Supabase Realtime
const channel = supabase
  .channel(`community-${communityId}`)
  .on(
    'postgres_changes',
    {
      event: '*',
      schema: 'public',
      table: 'community_messages',
      filter: `community_id=eq.${communityId}`,
    },
    (payload) => {
      // payload.new contiene el mensaje nuevo/actualizado
      // Actualizar el state del chat
    }
  )
  .subscribe();

// Cargar mensajes iniciales
const { data: messages } = await supabase
  .from('community_messages')
  .select('*')
  .eq('community_id', communityId)
  .eq('is_deleted', false)
  .order('created_at', { ascending: true })
  .limit(100);

// Cleanup
return () => supabase.removeChannel(channel);
```

### 3.6 — Enviar mensaje

```ts
await supabase.from('community_messages').insert({
  community_id: communityId,
  sender_id: user.id,
  content: messageText,
  // Opcionales:
  // reply_to_id: replyingToMessageId,
  // shared_business_id: businessId,
});
```

### 3.7 — Soft delete

```ts
await supabase
  .from('community_messages')
  .update({ is_deleted: true })
  .eq('id', messageId);
```

### 3.8 — Cargar perfil del sender

```ts
// Cachear en el cliente para no repetir queries
const profileCache = new Map<string, Profile>();

async function getSenderProfile(senderId: string) {
  if (profileCache.has(senderId)) return profileCache.get(senderId);
  
  const { data } = await supabase
    .from('profiles')
    .select('id, full_name, avatar_url')
    .eq('id', senderId)
    .maybeSingle();
  
  if (data) profileCache.set(senderId, data);
  return data;
}
```

---

## 4. Traduccion automatica con DeepL

### API endpoint
```
POST https://api-free.deepl.com/v2/translate
```

### Headers
```
Authorization: DeepL-Auth-Key cbffd6a1-4a8e-4028-b78f-12b443e9b86b:fx
Content-Type: application/json
```

### Traducir un mensaje
```ts
const response = await fetch('https://api-free.deepl.com/v2/translate', {
  method: 'POST',
  headers: {
    'Authorization': 'DeepL-Auth-Key cbffd6a1-4a8e-4028-b78f-12b443e9b86b:fx',
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    text: [messageContent],
    target_lang: targetLang, // 'ES', 'EN', 'FR', 'PT-BR'
  }),
});

const data = await response.json();
const translated = data.translations[0].text;
```

### Traducir multiples mensajes (batch)
```ts
// Mas eficiente: enviar multiples textos en una sola llamada
const response = await fetch('https://api-free.deepl.com/v2/translate', {
  method: 'POST',
  headers: {
    'Authorization': 'DeepL-Auth-Key cbffd6a1-4a8e-4028-b78f-12b443e9b86b:fx',
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    text: ['Hola', 'Como estas', 'Bienvenido'],
    target_lang: 'EN',
  }),
});

const data = await response.json();
// data.translations = [
//   { text: 'Hello', detected_source_language: 'ES' },
//   { text: 'How are you?', detected_source_language: 'ES' },
//   { text: 'Welcome', detected_source_language: 'ES' },
// ]
```

### Mapeo de idiomas app → DeepL
| Codigo app (profile_languages) | Codigo DeepL |
|---|---|
| `es` | `ES` |
| `en` | `EN` |
| `fr` | `FR` |
| `pt` | `PT-BR` |

### Estrategia de cache
```ts
// Cache en memoria: "texto|idioma" → traduccion
const translationCache = new Map<string, string>();

async function translateMessage(text: string, targetLang: string): Promise<string> {
  const key = `${text}|${targetLang}`;
  if (translationCache.has(key)) return translationCache.get(key)!;
  
  const translated = await callDeepL(text, targetLang);
  translationCache.set(key, translated);
  return translated;
}
```

### Flujo de traduccion en la UI
1. Mensaje llega por Realtime → se muestra el texto **original**
2. En background se lanza `translateMessage(content, userLang)`
3. Mientras traduce: mostrar spinner pequeno junto al texto
4. Cuando llega la traduccion: reemplazar texto y quitar spinner
5. Si falla: mostrar texto original sin error visible

---

## 5. Sistema de invitacion por codigo

### Como funciona
- Al crear una comunidad, se genera un **slug** con formato: `nombre-del-grupo-abc123`
- El slug completo **es** el codigo de invitacion
- Para unirse: el usuario ingresa el codigo (o parte de el) en un input
- La busqueda es case-insensitive y soporta match parcial

### Compartir
- **Copiar al portapapeles**: `navigator.clipboard.writeText(codigo)`
- **Share nativo**: `navigator.share({ text: 'Unete a "Nombre" en CONOCEMEX con el codigo: slug-completo' })`
- **Ejemplo de mensaje**: *Unete a "Foodies Mexico" en CONOCEMEX con el codigo: foodies-mexico-x7k2m9*

---

## 6. Estructura de UI sugerida (referencia de Flutter)

### Pantalla principal del chat
```
┌─────────────────────────────────────┐
│  Chat                    [📩]       │  ← boton solicitudes (placeholder)
├─────────────────────────────────────┤
│  💬 CHATS DIRECTOS                  │
│  ┌─────────────────────────────┐    │
│  │ Proximamente               │    │  ← placeholder (pendiente BD)
│  │ Solicitudes de clientes     │    │
│  └─────────────────────────────┘    │
│                                     │
│  👥 MIS COMUNIDADES                 │
│  ┌─────────────────────────────┐    │
│  │ 🔗 Unirse con codigo    →   │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 👥 Comunidad X      Admin  │    │  ← tap abre chat
│  │    Desc...      3 miembros  │    │     long-press → opciones
│  └─────────────────────────────┘    │
│                                     │
│                          [➕ FAB]   │  ← crear comunidad
└─────────────────────────────────────┘
```

### Pantalla del chat
```
┌─────────────────────────────────────┐
│  ← 👥 Chat                         │
│       Nombre de la comunidad        │
├─────────────────────────────────────┤
│                                     │
│        ┌──────────────────┐         │
│        │ Juan:            │         │  ← mensaje de otro (izquierda)
│        │ Hola a todos     │         │
│        │            10:30 │         │
│        └──────────────────┘         │
│                                     │
│  ┌──────────────────┐               │
│  │ Tu mensaje       │               │  ← mi mensaje (derecha, verde)
│  │            10:31 │               │
│  └──────────────────┘               │
│                                     │
├─────────────────────────────────────┤
│  [  Escribe un mensaje...  ] [📤]  │
└─────────────────────────────────────┘
```

### Colores del diseno (Stitch)
| Variable | Valor | Uso |
|---|---|---|
| darkBlue | `#001F3F` | Textos principales |
| primaryGreen | `#00DF5F` | Botones, acentos, badges |
| bgGrey | `#F3F3F4` | Fondos de inputs, burbujas ajenas |
| Mi burbuja | `#00DF5F` al 15% | Fondo de mis mensajes |
| Otra burbuja | `#F3F3F4` | Fondo de mensajes ajenos |

---

## 7. Chat 1 a 1 (PENDIENTE)

### Estado actual
Tanto la app Flutter como la PWA muestran un **placeholder** en la seccion "Chats Directos". La funcionalidad esta pendiente porque faltan estas tablas en la BD:

### Tablas necesarias (aun no creadas)
```sql
-- Conversacion 1 a 1
CREATE TABLE direct_chats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id uuid NOT NULL REFERENCES profiles(id),  -- cliente
  vendor_id uuid NOT NULL REFERENCES profiles(id),      -- vendedor
  business_id uuid REFERENCES businesses(id),            -- negocio relacionado
  status text NOT NULL DEFAULT 'pending',                -- pending, accepted, rejected
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(requester_id, vendor_id)
);

-- Mensajes del chat directo
CREATE TABLE direct_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id uuid NOT NULL REFERENCES direct_chats(id),
  sender_id uuid NOT NULL REFERENCES profiles(id),
  content text NOT NULL,
  is_deleted boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);
```

### Flujo esperado
1. **Cliente** busca un negocio → toca "Enviar mensaje" → crea un `direct_chat` con `status: 'pending'`
2. **Vendedor** ve la solicitud en su app → toca "Aceptar" → `status: 'accepted'`
3. Ambos pueden enviar mensajes en `direct_messages`
4. Los mensajes se traducen automaticamente igual que en comunidades

### Cuando esten listas las tablas
Avisar al equipo Flutter para que ambas apps implementen la funcionalidad en paralelo.

---

## 8. Datos de prueba

- **Comunidad demo**: `Comunidad Demo Chat`
  - `community_id`: `b0b43725-967c-419a-bcca-fbea89d97fb7`
  - Ya tiene 2 mensajes seed
- **Usuario admin de la comunidad**: `miguemolina4570@gmail.com`
  - `profile_id`: `b36fd860-111c-49d8-a08e-74fceb52c08b`

---

## 9. Checklist de implementacion

### Comunidades
- [ ] Listar mis comunidades con datos de membresia
- [ ] Crear comunidad (nombre + descripcion + auto-join admin)
- [ ] Mostrar codigo de invitacion (slug) con opcion de copiar y compartir
- [ ] Unirse por codigo de invitacion (input + busqueda por slug)
- [ ] Salir de una comunidad
- [ ] Pull-to-refresh en la lista

### Chat en comunidad
- [ ] Stream de mensajes en tiempo real (Supabase Realtime)
- [ ] Enviar mensaje de texto
- [ ] Mostrar nombre y avatar del sender (con cache)
- [ ] Burbujas alineadas (mias derecha, otros izquierda)
- [ ] Auto-scroll al ultimo mensaje
- [ ] Formateo de hora (HH:MM)
- [ ] Traduccion automatica via DeepL
- [ ] Cache de traducciones en memoria
- [ ] Indicador de "traduciendo..." mientras carga
- [ ] Soft delete de mensajes propios

### Chat directo (cuando la BD este lista)
- [ ] Solicitar chat con vendedor desde ficha de negocio
- [ ] Listar chats directos pendientes/activos
- [ ] Aceptar/rechazar solicitud (lado vendedor)
- [ ] Mensajes en tiempo real 1 a 1
- [ ] Traduccion automatica

---

## 10. Variables de entorno necesarias

```env
# Supabase (ya las tienes)
NEXT_PUBLIC_SUPABASE_URL=https://lcbgheoufqlrqimlxpei.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_A0fRIqGioRaKDg44yOaejQ_zQ4_uYvj

# DeepL (para traduccion)
DEEPL_API_KEY=cbffd6a1-4a8e-4028-b78f-12b443e9b86b:fx
```

> **Nota sobre DeepL**: La API key es del tier gratuito. Tiene limite de 500,000 caracteres/mes. Para el hackathon es mas que suficiente. En produccion habria que migrar al tier paid.

---

**Equipo JaguarMind — Talent Land Mexico 2026**
