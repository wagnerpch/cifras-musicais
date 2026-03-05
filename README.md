# Cifras

Um aplicativo moderno e simples desenvolvido em **Flutter** para o armazenamento e visualização de cifras musicais. Organize as cifras no seu formato preferido e tenha todas elas na palma da sua mão.

## Funcionalidades
* Adicionar novas cifras com título, artista, tom (musical) e o conteúdo (letra com os acordes).
* Visualizar as cifras de forma otimizada.
* Exibição de dicas e mensagens instrutivas de uso nas telas em que o repositório estiver vazio.
* Suporte nativo a Temas (Dark/Light).

## Tecnologias e Bibliotecas Utilizadas
* **[Flutter](https://flutter.dev/)**
* **[sqflite](https://pub.dev/packages/sqflite)**: Banco de dados SQLite local para armazenar e organizar as cifras cadastradas.
* **[path](https://pub.dev/packages/path)**: Usado em conjunto com banco de dados para a manipulação dos diretórios do sistema do dispositivo.
* **[wakelock_plus](https://pub.dev/packages/wakelock_plus)**: Mantém a tela ligada enquanto as cifras estiverem na tela, essencial para quando se está tocando uma música!
* **[flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons)**: Usado em tempo de desenvolvimento para automatizar a geração do ícone do aplicativo para Android e iOS.

## Como Executar
Siga os passos abaixo na sua linha de comando dentro da raiz deste projeto:

1. **Baixar as dependências**
   ```bash
   flutter pub get
   ```

2. **Executar o aplicativo**
   ```bash
   flutter run
   ```