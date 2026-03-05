import 'package:flutter/material.dart';
import '../../utils/chord_parser.dart';
import '../../models/song.dart';
import '../../database/database_helper.dart';

class AddSongPage extends StatefulWidget {
  final Song? songToEdit;

  const AddSongPage({super.key, this.songToEdit});

  @override
  State<AddSongPage> createState() => _AddSongPageState();
}

class _AddSongPageState extends State<AddSongPage> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _contentController;
  late final TextEditingController _bpmController;

  late String _selectedKey;
  
  final List<String> _musicalKeys = [
    'C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F', 'F#', 'Gb', 'G', 'G#', 'Ab', 'A', 'A#', 'Bb', 'B'
  ];

  @override
  void initState() {
    super.initState();
    final song = widget.songToEdit;
    
    _titleController = TextEditingController(text: song?.title ?? '');
    _artistController = TextEditingController(text: song?.artist ?? '');
    _contentController = TextEditingController(text: song?.content ?? '');
    _bpmController = TextEditingController(text: song?.bpm.toString() ?? '120');
    
    _selectedKey = song?.key ?? 'C';
    if (!_musicalKeys.contains(_selectedKey)) {
      _selectedKey = 'C';
    }
  }

  void _insertSymbol(String symbol) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    // Se não houver seleção (cursor não está no campo), insere no final
    if (selection.baseOffset == -1) {
      _contentController.text = text + symbol;
      _contentController.selection = TextSelection.collapsed(
        offset: _contentController.text.length,
      );
      return;
    }

    // Insere o caractere na posição exata do cursor ou substituindo o texto selecionado
    final newText = text.replaceRange(selection.start, selection.end, symbol);
    _contentController.text = newText;
    
    // Reposiciona o cursor logo depois do caractere inserido
    _contentController.selection = TextSelection.collapsed(
      offset: selection.start + symbol.length,
    );
  }

  void _runChordProParser() {
    if (_contentController.text.trim().isEmpty) return;

    final result = ChordParser.convertToChordPro(_contentController.text);
    _contentController.text = result;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cifra convertida com sucesso!')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _contentController.dispose();
    _bpmController.dispose();
    super.dispose();
  }

  Future<void> _saveSong() async {
    if (_formKey.currentState!.validate()) {
      final newSong = Song(
        id: widget.songToEdit?.id,
        title: _titleController.text,
        artist: _artistController.text,
        content: _contentController.text,
        key: _selectedKey,
        bpm: int.tryParse(_bpmController.text) ?? 120,
      );

      if (widget.songToEdit == null) {
        await DatabaseHelper.instance.insertSong(newSong);
      } else {
        await DatabaseHelper.instance.updateSong(newSong);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.songToEdit == null ? 'Música salva com sucesso!' : 'Música atualizada com sucesso!')),
        );
        Navigator.pop(context, true); // Retorna true para indicar sucesso e permitir reload na Home
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.songToEdit == null ? 'Nova Cifra' : 'Editar Cifra'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Salvar',
            onPressed: _saveSong,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título da Música',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira o título.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _artistController,
              decoration: const InputDecoration(
                labelText: 'Artista',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira o artista.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedKey,
                    decoration: const InputDecoration(
                      labelText: 'Tom Original',
                      border: OutlineInputBorder(),
                    ),
                    items: _musicalKeys.map((String key) {
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Text(key),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        if (newValue != null) {
                          _selectedKey = newValue;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _bpmController,
                    decoration: const InputDecoration(
                      labelText: 'BPM',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Obrigatório';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Letra/Cifras:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _runChordProParser,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Auto-Converter pra ChordPro'),
                ),
              ],
            ),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Cole a cifra (Formato ChordPro ou Texto)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              maxLines: null, // Expansível 
              minLines: 10,
              keyboardType: TextInputType.multiline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'A cifra não pode ficar vazia.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveSong,
              icon: const Icon(Icons.save),
              label: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Salvar Cifra', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
      // Barra persistente acima do teclado
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // Levanta com o teclado
        ),
        child: Container(
          color: Theme.of(context).bottomAppBarTheme.color ?? Colors.grey[200],
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSymbolButton('['),
                _buildSymbolButton(']'),
                _buildSymbolButton('/'),
                _buildSymbolButton('#'),
                _buildSymbolButton('7'),
                _buildSymbolButton('m'),
                _buildSymbolButton('maj7'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para desenhar os botõezinhos do painel
  Widget _buildSymbolButton(String symbol) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ActionChip(
        label: Text(
          symbol,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onPressed: () => _insertSymbol(symbol),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
