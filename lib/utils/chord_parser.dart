class ChordParser {
  // Regex para detectar se uma linha contém estritamente "Acordes e Espaços".
  // Identifica A-G (maior/menor/sustenido/bemol) e ramificações como m7, maj7, /B, 9, etc...
  static final RegExp _chordLineRegex = RegExp(
    r'^[\sA-G][b#]?(?:m|maj|dim|aug)?(?:[0-9]{1,2})?(?:\/[A-G][b#]?)?(?:sus[24])?(?:add[0-9]{1,2})?[\w\/\+\-\s]*$',
    caseSensitive: true,
  );

  /// Recebe um texto onde as cifras estão na linha de cima da letra 
  /// e retorna o formarto unificado do ChordPro `[Nota]Letra`
  static String convertToChordPro(String input) {
    if (input.isEmpty) return '';

    // Separa todas as linhas preservando as vazias
    final lines = input.split('\n');
    final List<String> outputLines = [];
    
    int i = 0;
    while (i < lines.length) {
      final String currentLine = lines[i];
      
      // Se não for uma linha de acordes ou for só espaço em branco, passa pra frente sem alterar
      if (!_isChordLine(currentLine) || currentLine.trim().isEmpty) {
        outputLines.add(currentLine);
        i++;
        continue;
      }

      // Se chegamos aqui, currentLine É uma linha de cifras!
      // Precisamos identificar exatamente em quais "colunas" estão as cifras
      final Map<int, String> chordPositions = _extractChordsAndPositions(currentLine);

      // Olha a linha posterior pra ver se é uma letra de música (texto) onde vamos injetar a cifra
      if (i + 1 < lines.length) {
        final nextLine = lines[i + 1];
        
        // Se a próxima linha NÃO FOR outra linha de acordes E NÃO FOR uma linha vazia,
        // consideramos que é a letra da música respectiva e faremos o match
        if (!_isChordLine(nextLine) && nextLine.trim().isNotEmpty) {
          // Aqui a mágica acontece: pegamos o texto inferior e injetamos
          // retroativamente as cifras lidas com [] formatado
          final mergedLine = _mergeChordsIntoText(nextLine, chordPositions);
          outputLines.add(mergedLine);
          
          // Como engolimos as duas linhas, pulamos +2
          i += 2;
          continue;
        }
      }

      // Fallback: Se for uma linha isolada de acordes sem letra embaixo (Ex: INTRODUÇÃO)
      // apenas cercamos as cifras por colchetes, preservando os espaços
      outputLines.add(_envelopStandaloneChords(currentLine, chordPositions));
      i++;
    }

    return outputLines.join('\n');
  }

  /// Ex: Avalia se "C  Am  G/B  F" é apenas notas e espaços. Uma palavra normal vai estourar pro 'false'.
  static bool _isChordLine(String line) {
    // Ignora linhas totalmente vazias ou só com espaços para não gerar falso positivo
    if (line.trim().isEmpty) return false;
    
    // Testa contra regex de formatação de notas musicais
    return _chordLineRegex.hasMatch(line.trimRight());
  }

  /// Devolve Map<IndexInicial, texto_do_acorde> extraído da string
  static Map<int, String> _extractChordsAndPositions(String line) {
    final Map<int, String> positions = {};
    
    // Captura qualquer sequência de caracteres que NÃO seja espaço
    final RegExp wordRegex = RegExp(r'[^\s]+');
    
    for (final match in wordRegex.allMatches(line)) {
      positions[match.start] = match.group(0)!;
    }
    
    return positions;
  }

  /// Injeta "D    A/C#" dentro de "Como é grande o meu amor" 
  /// Resultando em: "[D]Como é gran[A/C#]de o meu amor"
  static String _mergeChordsIntoText(String textLine, Map<int, String> chordPositions) {
    // Ordena os índices em ordem DECRESCENTE para que as modificações
    // no fim da string não afetem os índices do começo durante a injeção.
    final sortedIndices = chordPositions.keys.toList()..sort((a, b) => b.compareTo(a));
    
    String result = textLine;
    
    for (final index in sortedIndices) {
      final chord = chordPositions[index]!;
      final formattedChord = '[$chord]';
      
      // Se a nota caiu numa posição MAIOR que o comprimento da string de baixo
      // (ex: a batida de violão continua mesmo quando o cantor parou de cantar a frase)
      // devemos adicionar espaços vazios para alinhar e injetá-la lá no final
      if (index > result.length) {
        final padding = ' ' * (index - result.length);
        result = '$result$padding$formattedChord';
      } else {
        // Injeta exatamente na coluna em que foi encontrada
        result = result.substring(0, index) + formattedChord + result.substring(index);
      }
    }
    
    return result;
  }

  /// Se não tiver frase embaixo (ex: Introdução C F G Am), retorna apenas [C] [F] [G] [Am]
  static String _envelopStandaloneChords(String chordLine, Map<int, String> chordPositions) {
    final sortedIndices = chordPositions.keys.toList()..sort((a, b) => b.compareTo(a));
    String result = chordLine;
    
    for (final index in sortedIndices) {
      final chord = chordPositions[index]!;
      // Substitui o acorde puro pela sua versão encapsulada com []
      result = result.replaceRange(index, index + chord.length, '[$chord]');
    }
    
    return result;
  }
}
