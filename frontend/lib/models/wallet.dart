/// Model Wallet
class Wallet {
  final double saldoPunti;
  final double? puntiEmessi;
  final double? puntiIncassati;
  final double? saldo;
  final DateTime? ultimoAggiornamento;

  Wallet({
    required this.saldoPunti,
    this.puntiEmessi,
    this.puntiIncassati,
    this.saldo,
    this.ultimoAggiornamento,
  });

  /// Factory da JSON
  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      saldoPunti: _parseDouble(json['saldo_punti']),
      puntiEmessi: json['punti_emessi'] != null 
          ? _parseDouble(json['punti_emessi']) 
          : null,
      puntiIncassati: json['punti_incassati'] != null 
          ? _parseDouble(json['punti_incassati']) 
          : null,
      saldo: json['saldo'] != null 
          ? _parseDouble(json['saldo']) 
          : null,
      ultimoAggiornamento: json['ultimo_aggiornamento'] != null
          ? DateTime.parse(json['ultimo_aggiornamento'])
          : null,
    );
  }

  /// Helper per parsing sicuro double
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Formatta punti con 2 decimali
  String get saldoFormattato => saldoPunti.toStringAsFixed(2);

  /// Formatta saldo esercente
  String? get saldoEsercenteFormattato => 
      saldo != null ? saldo!.toStringAsFixed(2) : null;

  /// Verifica se ha saldo sufficiente
  bool hasSaldoSufficiente(double importo) => saldoPunti >= importo;

  /// Copy with
  Wallet copyWith({
    double? saldoPunti,
    double? puntiEmessi,
    double? puntiIncassati,
    double? saldo,
    DateTime? ultimoAggiornamento,
  }) {
    return Wallet(
      saldoPunti: saldoPunti ?? this.saldoPunti,
      puntiEmessi: puntiEmessi ?? this.puntiEmessi,
      puntiIncassati: puntiIncassati ?? this.puntiIncassati,
      saldo: saldo ?? this.saldo,
      ultimoAggiornamento: ultimoAggiornamento ?? this.ultimoAggiornamento,
    );
  }
}

