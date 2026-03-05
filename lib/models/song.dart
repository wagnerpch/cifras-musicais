class Song {
  final int? id;
  final String title;
  final String artist;
  final String content;
  final String key;
  final int bpm;

  Song({
    this.id,
    required this.title,
    required this.artist,
    required this.content,
    required this.key,
    required this.bpm,
  });

  // Converte o objeto Song para um Map (para salvar no SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'content': content,
      'key': key,
      'bpm': bpm,
    };
  }

  // Cria um objeto Song a partir de um Map (lido do SQLite)
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      content: map['content'] ?? '',
      key: map['key'] ?? '',
      bpm: map['bpm']?.toInt() ?? 0,
    );
  }

  // Método opcional para facilitar a atualização de campos específicos
  Song copyWith({
    int? id,
    String? title,
    String? artist,
    String? content,
    String? key,
    int? bpm,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      content: content ?? this.content,
      key: key ?? this.key,
      bpm: bpm ?? this.bpm,
    );
  }
}
