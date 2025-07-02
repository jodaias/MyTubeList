# 🎬 MyTubeList

<img src="assets/images/mytubelist_logo.png" width="200" alt="English AI Chat Logo">

Aplicativo Flutter para gerenciamento de listas de vídeos do YouTube com suporte a múltiplos perfis.

---

## 🚀 Funcionalidades

✅ Gerenciamento de **perfis de usuário**
✅ Criação, exclusão e seleção de perfis
✅ Visualização de vídeos do YouTube em player integrado
✅ Reprodução fullscreen com lista lateral de vídeos
✅ Alternância de vídeos em sequência
✅ Design responsivo com Material Design
✅ Confirmações modais para ações críticas

---

## 🛠️ Tecnologias utilizadas

- **Flutter**
- **Provider** – gerenciamento de estado
- **youtube_player_flutter** – player de vídeos YouTube
- **Material Design** – UI clean e intuitiva

---

## 📁 Estrutura do projeto

lib/
┣ models/
┃ ┗ profile_model.dart
┃ ┗ video_model.dart
┣ providers/
┃ ┗ profile_provider.dart
┃ ┗ video_provider.dart
┣ utils/
┃ ┗ confirmation_modal.dart
┣ pages/
┃ ┗ profile_page.dart
┃ ┗ player_page.dart
┃ ┗ full_screen_player_page.dart
┣ main.dart

---

## ⚡ Como rodar o projeto

1. **Clone o repositório**

```bash

git clone https://github.com/seu-usuario/my_tube_list.git
cd my_tube_list

2. Instale as dependências

flutter pub get

3. Execute o projeto

flutter run

🔑 Configurações adicionais

Certifique-se de adicionar seu API key do YouTube se for implementar busca dinâmica de vídeos futuramente.

Atualmente, os vídeos são gerenciados via VideoModel com id, title e thumbnailUrl.

✨ Próximos passos

- 🔍 Implementar busca de vídeos direto da API do YouTube

- 📥 Suporte a download offline

- 🗂️ Categorias personalizadas por perfil

- 🌓 Tema escuro e claro automático

🤝 Contribuições
Contribuições são bem-vindas! Abra um Pull Request ou crie um Issue para discussão de melhorias.

📄 Licença
Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

👤 Autor
Feito com 💚 por Jodaías B. S.

📫 Contact
feel free to contact me!
<a href="https://www.linkedin.com/in/jodaias-barreto">Linkedin</a> • <a href="https://github.com/jodaias">Github</a>
```
