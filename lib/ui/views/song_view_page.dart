import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/song.dart';
import '../../database/database_helper.dart';
import 'add_song_page.dart';

class SongViewPage extends StatefulWidget {
  final Song song;

  const SongViewPage({super.key, required this.song});

  @override
  State<SongViewPage> createState() => _SongViewPageState();
}

class _SongViewPageState extends State<SongViewPage> {
  late Song _currentSong;
  final ScrollController _scrollController = ScrollController();
  bool _isAutoScrolling = false;
  double _scrollSpeedPixelsPerSecond = 50.0; // Velocidade inicial

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    // Ativa o wakelock para impedir que a tela apague
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    // Desativa o wakelock ao sair da página
    WakelockPlus.disable();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleAutoScroll() {
    setState(() {
      _isAutoScrolling = !_isAutoScrolling;
    });

    if (_isAutoScrolling) {
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
  }

  void _startAutoScroll() {
    if (!_scrollController.hasClients || !_isAutoScrolling) return;

    final double maxScrollExtent = _scrollController.position.maxScrollExtent;
    final double currentPixels = _scrollController.position.pixels;
    final double remainingDistance = maxScrollExtent - currentPixels;

    if (remainingDistance <= 0) {
      setState(() {
        _isAutoScrolling = false;
      });
      return;
    }

    // Calcula a duração baseada na distância restante e na velocidade desejada
    final int durationInSeconds = (remainingDistance / _scrollSpeedPixelsPerSecond).round();

    _scrollController.animateTo(
      maxScrollExtent,
      duration: Duration(seconds: durationInSeconds),
      curve: Curves.linear,
    ).then((_) {
      // Quando a animação terminar (chegou ao fim ou foi interrompida)
      if (mounted && _scrollController.position.pixels >= maxScrollExtent) {
        setState(() {
          _isAutoScrolling = false;
        });
      }
    });
  }

  void _stopAutoScroll() {
    if (_scrollController.hasClients) {
      // Para interromper a animação atual, animamos para a posição atual
      // com duração zero.
      _scrollController.animateTo(
        _scrollController.position.pixels,
        duration: const Duration(milliseconds: 1),
        curve: Curves.linear,
      );
    }
  }

  void _onSpeedChanged(double newSpeed) {
    setState(() {
      _scrollSpeedPixelsPerSecond = newSpeed;
    });
    
    if (_isAutoScrolling) {
      _stopAutoScroll();
      // Um pequeno delay para garantir que o scroll anterior parou antes de iniciar o novo
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && _isAutoScrolling) {
           _startAutoScroll();
        }
      });
    }
  }

  Future<void> _editSong() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSongPage(songToEdit: _currentSong),
      ),
    );

    if (result == true && mounted) {
      // Recarrega a música do banco de dados para refletir as alterações
      final updatedSong = await DatabaseHelper.instance.getSongById(_currentSong.id!);
      if (updatedSong != null && mounted) {
        setState(() {
          _currentSong = updatedSong;
        });
      }
    }
  }

  Future<void> _deleteSong() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Tem certeza que deseja excluir esta cifra?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await DatabaseHelper.instance.deleteSong(_currentSong.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cifra excluída com sucesso!')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentSong.title),
            Text(
              _currentSong.artist,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
           Center(
             child: Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16.0),
               child: Text('Tom: ${_currentSong.key} | BPM: ${_currentSong.bpm}', style: const TextStyle(fontSize: 12)),
             ),
           ),
           IconButton(
             icon: const Icon(Icons.edit),
             tooltip: 'Editar Cifra',
             onPressed: _editSong,
           ),
           IconButton(
             icon: const Icon(Icons.delete),
             tooltip: 'Excluir Cifra',
             onPressed: _deleteSong,
           ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              // Detecta scroll manual do usuário para cancelar o auto-scroll
              child: NotificationListener<ScrollUpdateNotification>(
                onNotification: (notification) {
                  // Se o usuário rolou a tela manualmente (drag), para o auto scroll
                  if (notification.dragDetails != null && _isAutoScrolling) {
                     setState(() {
                       _isAutoScrolling = false;
                     });
                     _stopAutoScroll();
                  }
                  return false;
                },
                child: Text(
                  _currentSong.content,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.5, // Melhor legibilidade para letras/cifras
                    fontFamily: 'monospace', // Ideal para manter os acordes alinhados no padrão ChordPro/TXT
                  ),
                ),
              ),
            ),
          ),
          // Barra de controles de velocidade na parte inferior
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Theme.of(context).bottomAppBarTheme.color ?? Colors.grey[700],
            child: Row(
              children: [
                const Icon(Icons.speed),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _scrollSpeedPixelsPerSecond,
                    min: 10.0,
                    max: 150.0,
                    divisions: 14,
                    label: '${_scrollSpeedPixelsPerSecond.round()} px/s',
                    onChanged: _onSpeedChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleAutoScroll,
        child: Icon(_isAutoScrolling ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}
