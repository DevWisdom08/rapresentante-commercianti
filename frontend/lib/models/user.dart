/// Model Utente
class User {
  final int id;
  final String email;
  final String nome;
  final String cognome;
  final String? telefono;
  final String ruolo;
  final bool emailVerificata;
  final bool attivo;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.nome,
    required this.cognome,
    this.telefono,
    required this.ruolo,
    required this.emailVerificata,
    required this.attivo,
    this.createdAt,
  });

  /// Factory da JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      nome: json['nome'],
      cognome: json['cognome'],
      telefono: json['telefono'],
      ruolo: json['ruolo'],
      emailVerificata: json['email_verificata'] ?? false,
      attivo: json['attivo'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  /// Converti a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nome': nome,
      'cognome': cognome,
      'telefono': telefono,
      'ruolo': ruolo,
      'email_verificata': emailVerificata,
      'attivo': attivo,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Nome completo
  String get nomeCompleto => '$nome $cognome';

  /// Verifica se è cliente
  bool get isCliente => ruolo == 'cliente';

  /// Verifica se è esercente
  bool get isEsercente => ruolo == 'esercente';

  /// Verifica se è rappresentante
  bool get isRappresentante => ruolo == 'rappresentante';

  /// Verifica se è centrale
  bool get isCentrale => ruolo == 'centrale';

  /// Copy with
  User copyWith({
    int? id,
    String? email,
    String? nome,
    String? cognome,
    String? telefono,
    String? ruolo,
    bool? emailVerificata,
    bool? attivo,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nome: nome ?? this.nome,
      cognome: cognome ?? this.cognome,
      telefono: telefono ?? this.telefono,
      ruolo: ruolo ?? this.ruolo,
      emailVerificata: emailVerificata ?? this.emailVerificata,
      attivo: attivo ?? this.attivo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

