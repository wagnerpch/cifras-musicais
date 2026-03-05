import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/song.dart';
import 'song_view_page.dart';
import 'add_song_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    final songs = await DatabaseHelper.instance.getSongs();
    setState(() {
      _songs = songs;
      _isLoading = false;
    });
  }

  Future<void> _navigateToAddSong() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSongPage()),
    );

    // Se a tela retornou true (salvou), recarrega as músicas
    if (result == true) {
      _loadSongs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Cifras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Cifra',
            onPressed: _navigateToAddSong,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddSong,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma cifra encontrada. Toque no ícone (+) para adicionar um teste.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return Dismissible(
                      key: Key(song.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
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
                      },
                      onDismissed: (direction) async {
                        await DatabaseHelper.instance.deleteSong(song.id!);
                        setState(() {
                          _songs.removeAt(index);
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cifra excluída com sucesso!')),
                          );
                        }
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(song.key),
                        ),
                        title: Text(song.title),
                        subtitle: Text(song.artist),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SongViewPage(song: song),
                            ),
                          );
                          // A música pode ter sido editada, então recarrega a lista
                          _loadSongs();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
