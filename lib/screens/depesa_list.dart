import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:registro_despesa/providers/despesa_providers.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:registro_despesa/models/despesa_model.dart';

class DespesaListView extends StatelessWidget {
  const DespesaListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Despesa List"),
        ),
        body: Center(
            child: Column(
          children: const [Text("Test")],
        )),
      ),
    );
  }
}

class DespesasListView extends ConsumerWidget {
  const DespesasListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<DespesaListResponse>(
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final despesas = snapshot.data!.despesas;
          return Expanded(
            child: ListView.builder(
              itemCount: despesas.length,
              itemBuilder: (context, index) {
                final despesa = despesas[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: ListTile(
                      title: Text(despesa.nomeDespesa),
                    ),
                  ),
                );
              },
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Erro ao carregar os dados: ${snapshot.error}');
        }

        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}


