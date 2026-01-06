/// Model Transazione
class Transazione {
  final int id;
  final String tipo;
  final String tipoDescrizione;
  final double punti;
  final double? importoEuro;
  final String? descrizione;
  final DateTime createdAt;
  final TransazioneMittente? mittente;
  final TransazioneMittente? destinatario;

  Transazione({
    required this.id,
    required this.tipo,
    required this.tipoDescrizione,
    required this.punti,
    this.importoEuro,
    this.descrizione,
    required this.createdAt,
    this.mittente,
    this.destinatario,
  });

  /// Factory da JSON
  factory Transazione.fromJson(Map<String, dynamic> json) {
    return Transazione(
      id: json['id'],
      tipo: json['tipo'],
      tipoDescrizione: json['tipo_descrizione'] ?? json['tipo'],
      punti: _parseDouble(json['punti']),
      importoEuro: json['importo_euro'] != null 
          ? _parseDouble(json['importo_euro']) 
          : null,
      descrizione: json['descrizione'],
      createdAt: DateTime.parse(json['created_at']),
      mittente: json['mittente'] != null 
          ? TransazioneMittente.fromJson(json['mittente']) 
          : null,
      destinatario: json['destinatario'] != null 
          ? TransazioneMittente.fromJson(json['destinatario']) 
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Formatta punti
  String get puntiFormattati => '${punti.toStringAsFixed(2)} punti';

  /// Formatta importo euro
  String? get importoFormattato => 
      importoEuro != null ? '€ ${importoEuro!.toStringAsFixed(2)}' : null;

  /// Verifica se è entrata (ricevuto punti)
  bool get isEntrata => tipo == 'assegnazione' || tipo.startsWith('bonus_');

  /// Verifica se è uscita (speso punti)
  bool get isUscita => tipo == 'pagamento' || tipo == 'scadenza';
}

/// Mittente/Destinatario transazione
class TransazioneMittente {
  final int id;
  final String nome;
  final String tipo;
  final String? nomeNegozio;

  TransazioneMittente({
    required this.id,
    required this.nome,
    required this.tipo,
    this.nomeNegozio,
  });

  factory TransazioneMittente.fromJson(Map<String, dynamic> json) {
    return TransazioneMittente(
      id: json['id'],
      nome: json['nome'],
      tipo: json['tipo'],
      nomeNegozio: json['nome_negozio'],
    );
  }

  String get nomeVisualizzato => nomeNegozio ?? nome;
}

