git clone https://github.com/seu-usuario/my_tube_list.git

# 🎬 MyTubeList

<img src="assets/images/mytubelist_logo.png" width="200" alt="MyTubeList Logo">

Aplicativo Flutter para gerenciamento de listas de vídeos do YouTube, com múltiplos perfis, integração Firebase e suporte local/offline.

---

## 🚀 Funcionalidades

- Gerenciamento de **múltiplos perfis** (local e Firebase)
- Criação, exclusão, seleção e login de perfis
- Busca de vídeos do YouTube (com histórico)
- Adição e remoção em lote de vídeos em listas
- Player integrado com suporte a fullscreen e lista lateral
- Alternância rápida entre vídeos
- Confirmação modal para ações críticas (com desafio matemático para perfis infantis)
- Suporte a categorias de perfil (faixa etária)
- Design responsivo (Material Design)
- Suporte a modo escuro/claro (em breve)
- **🔐 Autenticação segura** (Firebase Auth sem armazenar senhas no Firestore)

---

## 🛡️ Segurança

O MyTubeList implementa uma arquitetura de segurança robusta:

- **🔐 Firebase Auth**: Autenticação exclusiva via Firebase Auth
- **🚫 Sem senhas no Firestore**: Senhas nunca são armazenadas no banco de dados
- **🔒 Criptografia**: Firebase Auth gerencia toda a criptografia
- **📱 Dados locais seguros**: Informações sensíveis apenas localmente quando necessário

Veja mais detalhes em [SECURITY.md](SECURITY.md)

---

## 🛠️ Tecnologias utilizadas

- **Flutter** 3.x
- **Provider** (gerenciamento de estado)
- **youtube_player_flutter** (player YouTube)
- **Hive** (armazenamento local)
- **Firebase Auth** e **Cloud Firestore** (sincronização e autenticação)
- **Material Design**

---

## 📁 Estrutura do projeto (resumida)

lib/
┣ main.dart
┣ firebase_options.dart
┣ models/
┃ ┣ profile_model.dart
┃ ┣ video_model.dart
┃ ┗ video_list_model.dart
┣ providers/
┃ ┣ firebase_profile_provider.dart
┃ ┣ firebase_video_list_provider.dart
┃ ┣ firebase_video_provider.dart
┃ ┗ local_profiles_provider.dart
┣ pages/
┃ ┣ auth_page.dart
┃ ┣ home_page.dart
┃ ┣ player_page.dart
┃ ┣ profiles_page.dart
┃ ┣ search_page.dart
┃ ┣ splash_page.dart
┃ ┗ videos_page.dart
┣ services/
┃ ┗ firebase_service.dart
┣ utils/
┃ ┣ confirmation_modal.dart
┃ ┣ math_question.dart
┃ ┗ password_utils.dart
┣ widgets/
┃ ┗ video_card.dart

assets/
┣ images/
┃ ┣ mytubelist_logo.png
┃ ┣ mytubelist_logo.svg
┃ ┣ mytubelist_logo_name.png
┃ ┗ paused.png
┣ gifs/
┃ ┗ playing.gif
┣ icons/
┃ ┗ player_green_icon.png

---

## ⚡ Como rodar o projeto

1. **Clone o repositório**

```

```
