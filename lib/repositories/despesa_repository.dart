import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:registro_despesa/models/despesa_model.dart';

abstract class IDespesaRepository {
  Future<DespesaListResponse> fetchDespesasList();
}

class DespesaListResponse {
  List<DespesaListResponse> despesas;

  DespesaListResponse({required this.despesas});

  factory DespesaListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> jsonData = json['despesas'];
    List<DespesaListResponse> despesasList =
        jsonData.map((item) => DespesaListResponse.fromJson(item)).toList();
    return DespesaListResponse(despesas: despesasList);
  }
}

class DespesaRepository implements IDespesaRepository {
  final _host = "https://localhost:7197";
  final Map<String, String> _headers = {
    "Accept": "application/json",
    "contect-type": "application/json",
  };

  @override
  Future<DespesaListResponse> fetchDespesasList() async {
    var getAllDespesasUrls = _host + "/api/Despesas";

    var results =
        await http.get(Uri.parse(getAllDespesasUrls), headers: _headers);
    if (results.statusCode == 200) {
      // A resposta foi bem-sucedida (código 200)
      print('Resposta bem-sucedida');
      // Resto do seu código para processar a resposta e retornar os dados desejados
    } else {
      // A resposta foi diferente de 200
      print('Falha na solicitação: ${results.statusCode}');
    }

    final jsonObject = json.decode(results.body);

    var despesaListResponse = DespesaListResponse.fromJson(jsonObject);

    return despesaListResponse;
  }
}
