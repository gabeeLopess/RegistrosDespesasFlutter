import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:registro_despesa/models/despesa_model.dart' as models;
import 'package:registro_despesa/repositories/despesa_repository.dart';

final despesaRepositoryProviders =
    Provider<IDespesaRepository>((ref) => DespesaRepository());

final despesaList =
    FutureProvider.autoDispose<DespesaListResponse>((ref) async {
  final repository = ref.watch(despesaRepositoryProviders);

  return repository.fetchDespesasList();
});
