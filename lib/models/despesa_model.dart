import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Despesa {
  final String codDespesa;
  final String nomeDespesa;
  final String descricaoDespesa;
  final double valor;
  final DateTime data;

  Despesa({
    required this.codDespesa,
    required this.nomeDespesa,
    required this.descricaoDespesa,
    required this.valor,
    required this.data,
  });
}

class DespesaListResponse {
  final String codDespesa;
  final List<Despesa> despesas;

  DespesaListResponse({
    required this.codDespesa,
    required this.despesas,
  });

  factory DespesaListResponse.fromJson(Map<String, dynamic> json) {
   final List<Map<String, dynamic>> jsonDespesas = List<Map<String, dynamic>>.from(json['despesas']);
final despesas = jsonDespesas.map((jsonDespesa) {
      return Despesa(
        codDespesa: jsonDespesa['codDespesa'],
        nomeDespesa: jsonDespesa['nomeDespesa'],
        descricaoDespesa: jsonDespesa['descricaoDespesa'],
        valor: jsonDespesa['valor'].toDouble(),
        data: DateTime.tryParse(jsonDespesa['data']) ?? DateTime.now(),
      );
    }).toList();

    return DespesaListResponse(
      codDespesa: json['codDespesa'],
      despesas: despesas,
    );
  }
}

