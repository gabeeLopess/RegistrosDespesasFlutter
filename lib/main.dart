import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:date_field/date_field.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Despesas',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const DespesasListView(),
      routes: {
        DespesasListView.routeName: (ctx) => const DespesasListView(),
        DespesaFormView.routeName: (ctx) => const DespesaFormView(),
        DespesaView.routeName: (ctx) {
          final despesa = ModalRoute.of(ctx)!.settings.arguments as Despesa;
          return DespesaView(despesa: despesa);
        },
        DespesaView.UpdaterouteName: (ctx) {
          final despesa = ModalRoute.of(ctx)!.settings.arguments as Despesa;
          return DespesaUpdateView(despesa: despesa);
        },
      },
    );
  }
}

class Despesa {
  String? codDespesa;
  final String nomeDespesa;
  final String descricaoDespesa;
  final double valor;
  final DateTime data;

  Despesa({
    this.codDespesa,
    required this.nomeDespesa,
    required this.descricaoDespesa,
    required this.valor,
    required this.data,
  });

  factory Despesa.fromJson(Map<String, dynamic> json) {
    return Despesa(
      codDespesa: json['codDespesa'],
      nomeDespesa: json['nomeDespesa'],
      descricaoDespesa: json['descricaoDespesa'],
      valor: json['valor'].toDouble(),
      data: DateTime.tryParse(json['data']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (codDespesa != null) 'codDespesa': codDespesa,
      'nomeDespesa': nomeDespesa,
      'descricaoDespesa': descricaoDespesa,
      'valor': valor,
      'data': DateFormat('yyyy-MM-ddTHH:mm:ss').format(data),
    };
  }
}

class DespesaRepository {
  late String _host;
  final Map<String, String> _headers = {
    "Accept": "application/json",
    "Content-Type": "application/json",
  };

  DespesaRepository() {
    if (kIsWeb) {
      _host = "https://localhost:7197";
    } else {
      _host = "https://10.0.2.2:7197";
    }
  }

  Future<List<Despesa>> fetchDespesasList() async {
    var getAllDespesasUrl = _host + "/api/Despesas";

    var results =
        await http.get(Uri.parse(getAllDespesasUrl), headers: _headers);
    if (results.statusCode == 200) {
      print('Resposta bem-sucedida');
      final List<dynamic> jsonList = json.decode(results.body);
      List<Despesa> despesas = jsonList
          .map((item) => Despesa.fromJson(item as Map<String, dynamic>))
          .toList();
      return despesas;
    } else {
      print('Falha na solicitação: ${results.statusCode}');
      throw Exception('Falha na solicitação: ${results.statusCode}');
    }
  }

  Future<Despesa> createNewDespesa(Despesa despesa) async {
    var createDespesaUrl = _host + "/api/Despesas";

    // Gera um GUID aleatório
    var uuid = Uuid();
    despesa.codDespesa = uuid.v4();

    var body = json.encode(despesa.toJson());
    print(body);

    var response = await http.post(
      Uri.parse(createDespesaUrl),
      headers: _headers,
      body: body,
    );

    if (response.statusCode != 200) {
      print('Falha ao criar a despesa: ${response.statusCode}');
      throw Exception('Falha ao criar a despesa');
    }

    print('Despesa criada com sucesso');
    var createdDespesa = Despesa.fromJson(json.decode(response.body));
    return createdDespesa;
  }

  Future<Despesa> updateDespesa(Despesa despesa) async {
    var updateDespesaUrl = _host + "/api/Despesas/${despesa.codDespesa}";

    var body = json.encode(despesa.toJson());
    print(body);

    var response = await http.put(
      Uri.parse(updateDespesaUrl),
      headers: _headers,
      body: body,
    );

    if (response.statusCode != 200) {
      print('Falha ao atualizar a despesa: ${response.statusCode}');
      throw Exception('Falha ao atualizar a despesa');
    }

    print('Despesa atualizada com sucesso');
    var updatedDespesa = Despesa.fromJson(json.decode(response.body));
    return updatedDespesa;
  }

  Future<void> deleteDespesa(Despesa despesa) async {
    var deleteDespesaUrl = _host + "/api/Despesas/${despesa.codDespesa}";

    var response =
        await http.delete(Uri.parse(deleteDespesaUrl), headers: _headers);

    if (response.statusCode != 200) {
      print('Falha ao excluir a despesa: ${response.statusCode}');
      throw Exception('Falha ao excluir a despesa');
    }

    print('Despesa excluída com sucesso');
  }
}

class DespesasListView extends StatefulWidget {
  const DespesasListView({Key? key}) : super(key: key);

  static const String routeName = "/depesalist";

  @override
  _DespesasListViewState createState() => _DespesasListViewState();
}

class _DespesasListViewState extends State<DespesasListView> {
  late Future<List<Despesa>> _futureDespesas;
  double _totalDespesas = 0;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _futureDespesas = DespesaRepository().fetchDespesasList();
  }

  Future<void> _refreshDespesas() async {
    setState(() {
      _futureDespesas = DespesaRepository().fetchDespesasList();
    });
  }

  double _calcularTotalDespesas(List<Despesa> despesas) {
    double total = 0;
    for (var despesa in despesas) {
      total += despesa.valor;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Desabilitar o botão voltar
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lista de Despesas'),
        ),
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _refreshDespesas,
          child: Center(
            child: FutureBuilder<List<Despesa>>(
              future: _futureDespesas,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Erro ao carregar os dados: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  final despesas = snapshot.data!;
                  _totalDespesas = _calcularTotalDespesas(despesas);

                  return ListView.builder(
                    itemCount: despesas.length,
                    itemBuilder: (context, index) {
                      final despesa = despesas[index];
                      final formattedDate =
                          DateFormat('dd/MM/yyyy').format(despesa.data);
                      return Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              DespesaView.routeName,
                              arguments: despesa,
                            );
                          },
                          child: ListTile(
                            title: Text(despesa.nomeDespesa),
                            subtitle: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(despesa.descricaoDespesa),
                                SizedBox(width: 8),
                                Text(formattedDate),
                              ],
                            ),
                            trailing:
                                Text('R\$ ${despesa.valor.toStringAsFixed(2)}'),
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return Text('Nenhum dado encontrado');
                }
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, DespesaFormView.routeName);
          },
          label: Text("Adicione uma nova Despesa"),
          icon: const Icon(Icons.monetization_on),
        ),
        persistentFooterButtons: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Total: R\$ $_totalDespesas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class DespesaFormView extends StatelessWidget {
  const DespesaFormView({Key? key}) : super(key: key);

  static const String routeName = "/depesaform";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Adicionando Despesa"),
        ),
        body: Center(
          child: Column(
            children: const [
              DepesaForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class DepesaForm extends ConsumerStatefulWidget {
  const DepesaForm({Key? key}) : super(key: key);

  @override
  _DepesaFormState createState() => _DepesaFormState();
}

class _DepesaFormState extends ConsumerState<DepesaForm> {
  final _formKey = GlobalKey<FormState>();

  final _nomeDespesaController = TextEditingController();
  final _descricaoDespesaController = TextEditingController();
  final _dataDespesaController = TextEditingController();
  final _valorDespesaController = TextEditingController();

  bool _showSuccessMessage = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: TextFormField(
              maxLength: 10,
              controller: _nomeDespesaController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Por favor preencha o nome da despesa";
                }
                return null;
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Nome de sua Despesa",
                labelText: "Nome Despesa",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: TextFormField(
              maxLength: 15,
              controller: _descricaoDespesaController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Por favor preencha a descrição da despesa";
                }
                return null;
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Descrição de sua Despesa",
                labelText: "Descrição Despesa",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: TextFormField(
              controller: _dataDespesaController,
              maxLength: 10,
              readOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecione uma data';
                }
                return null;
              },
              onTap: () {
                showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                ).then((selectedDate) {
                  if (selectedDate != null) {
                    setState(() {
                      _dataDespesaController.text =
                          DateFormat('dd/MM/yyyy').format(selectedDate);
                    });
                  }
                });
              },
              decoration: const InputDecoration(
                labelText: 'Data da Despesa',
                hintText: 'Selecione uma data',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: TextFormField(
              maxLength: 15,
              controller: _valorDespesaController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Por favor, preencha o valor da despesa";
                }
                return null;
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Valor de sua Despesa",
                labelText: "Valor Despesa",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  var formattedDate = DateFormat('dd/MM/yyyy')
                      .parse(_dataDespesaController.text);
                  var despesa = Despesa(
                    codDespesa: '',
                    nomeDespesa: _nomeDespesaController.text,
                    descricaoDespesa: _descricaoDespesaController.text,
                    valor: double.parse(_valorDespesaController.text),
                    data: formattedDate,
                  );

                  DespesaRepository()
                      .createNewDespesa(despesa)
                      .then((createdDespesa) {
                    // Ação realizada após a criação da despesa
                    print('Despesa criada: ${createdDespesa.nomeDespesa}');
                    setState(() {
                      _showSuccessMessage = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Salvo com sucesso'),
                        backgroundColor:
                            Colors.green, // Defina a cor desejada aqui
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }).catchError((error) {
                    print('Erro ao criar a despesa: $error');
                  }).whenComplete(() {
                    Navigator.pushReplacementNamed(
                        context, DespesasListView.routeName);
                  });
                }
              },
              child: const Text("Salvar"),
            ),
          ),
          if (_showSuccessMessage)
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(
                'Salvo com sucesso',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DespesaView extends StatelessWidget {
  final Despesa despesa;

  const DespesaView({Key? key, required this.despesa}) : super(key: key);

  static const String routeName = "/depesa-view";

  static const String UpdaterouteName = "/update-view";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Despesa"),
      ),
      body: Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  ' ${despesa.nomeDespesa ?? ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  ' ${despesa.descricaoDespesa ?? ''}',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  ' R\$ ${despesa.valor.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  ' ${DateFormat('dd/MM/yyyy').format(despesa.data)}',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                    child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _confirmDelete(context);
                        },
                        child: Icon(Icons.delete, color: Colors.red),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            DespesaView.UpdaterouteName,
                            arguments: despesa,
                          );
                        },
                        child: Icon(Icons.edit, color: Colors.blue),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmar exclusão"),
          content: Text("Deseja realmente excluir esta despesa?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                DespesaRepository().deleteDespesa(despesa);

                Navigator.pushReplacementNamed(
                    context, DespesasListView.routeName);
              },
              child: Text("Excluir"),
            ),
          ],
        );
      },
    );
  }
}

class DespesaUpdateView extends StatefulWidget {
  final Despesa despesa;

  const DespesaUpdateView({Key? key, required this.despesa}) : super(key: key);

  @override
  _DespesaUpdateViewState createState() => _DespesaUpdateViewState();
}

class _DespesaUpdateViewState extends State<DespesaUpdateView> {
  final _formKey = GlobalKey<FormState>();

  final _nomeDespesaController = TextEditingController();
  final _descricaoDespesaController = TextEditingController();
  final _dataDespesaController = TextEditingController();
  final _valorDespesaController = TextEditingController();

  bool _showSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    _nomeDespesaController.text = widget.despesa.nomeDespesa;
    _descricaoDespesaController.text = widget.despesa.descricaoDespesa;
    _dataDespesaController.text =
        DateFormat('dd/MM/yyyy').format(widget.despesa.data);
    _valorDespesaController.text = widget.despesa.valor.toString();
  }

  void updateDespesa() {
    if (_formKey.currentState!.validate()) {
      var formattedDate =
          DateFormat('dd/MM/yyyy').parse(_dataDespesaController.text);
      var despesaAtualizada = Despesa(
        codDespesa: widget.despesa.codDespesa,
        nomeDespesa: _nomeDespesaController.text,
        descricaoDespesa: _descricaoDespesaController.text,
        valor: double.parse(_valorDespesaController.text),
        data: formattedDate,
      );

      DespesaRepository()
          .updateDespesa(despesaAtualizada)
          .then((updatedDespesa) {
        // Ação realizada após a atualização da despesa
        print('Despesa atualizada: ${updatedDespesa.nomeDespesa}');
        setState(() {
          _showSuccessMessage = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Atualizado com sucesso'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }).catchError((error) {
        print('Erro ao atualizar a despesa: $error');
      }).whenComplete(() {
        Navigator.pushReplacementNamed(context, DespesasListView.routeName);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atualizar Despesa'),
      ),
      body: Container(
        padding: const EdgeInsets.all(3.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: TextFormField(
                  maxLength: 15,
                  controller: _nomeDespesaController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Por favor preencha o nome da despesa";
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Nome de sua Despesa",
                    labelText: "Nome Despesa",
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: TextFormField(
                  maxLength: 15,
                  controller: _descricaoDespesaController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Por favor preencha a descrição da despesa";
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Descrição de sua Despesa",
                    labelText: "Descrição Despesa",
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: TextFormField(
                  controller: _dataDespesaController,
                  maxLength: 10,
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma data';
                    }
                    return null;
                  },
                  onTap: () {
                    showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    ).then((selectedDate) {
                      if (selectedDate != null) {
                        setState(() {
                          _dataDespesaController.text =
                              DateFormat('dd/MM/yyyy').format(selectedDate);
                        });
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Data da Despesa',
                    hintText: 'Selecione uma data',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: TextFormField(
                  maxLength: 15,
                  controller: _valorDespesaController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Por favor, preencha o valor da despesa";
                    }
                    return null;
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Valor de sua Despesa",
                    labelText: "Valor Despesa",
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: ElevatedButton(
                  onPressed: updateDespesa,
                  child: const Text("Salvar"),
                ),
              ),
              if (_showSuccessMessage)
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    'Atualizado com sucesso',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
