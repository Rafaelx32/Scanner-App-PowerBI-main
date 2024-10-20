import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanner_app/screens/atualizacaodeVendas.dart';
import 'package:scanner_app/styles/styles.dart';

class SelecaoVendasScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: StylesProntos.colorPadrao,
        title: Text(
          'Selecione uma venda',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: StylesProntos.colorPadrao,
        onPressed: () => Navigator.pushNamed(context, "/cadastroVendas"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Vendas').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Nenhuma venda encontrada.'));
          }

          var docs = snapshot.data!.docs;

          return ListView.separated(
            padding: EdgeInsets.only(top: 20),
            itemCount: docs.length,
            separatorBuilder: (context, index) => SizedBox(height: 1),
            itemBuilder: (context, index) {
              var doc = docs[index];
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(
                    data['nomeCliente'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text('Data: ${data['Data'] ?? ''}'),
                      Text(
                          'Total: R\$${data['totalVenda']?.toStringAsFixed(2) ?? '0.00'}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AtualizacaodeVendas(doc),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, size: 28),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Confirmar exclusão'),
                              content: Text(
                                  'Tem certeza de que deseja excluir esta venda?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection('Vendas')
                                        .doc(doc.id)
                                        .delete();
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.red,
                                        content:
                                            Text('Venda excluída com sucesso.'),
                                      ),
                                    );
                                  },
                                  child: Text('Confirmar'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
