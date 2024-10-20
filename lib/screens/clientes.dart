import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanner_app/screens/updateClientes.dart';
import 'package:scanner_app/styles/styles.dart';

class clientes extends StatelessWidget {
  clientes({Key? key});

  final firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: StylesProntos.colorPadrao,
        title: Text(
          "Clientes",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true, // Centraliza o título
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Navigator.pushNamed(context, "/cadastroClientes"),
        backgroundColor: StylesProntos.colorPadrao,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore.collection('Clientes').snapshots(),
        builder: (context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.separated(
            padding: EdgeInsets.only(top: 20),
            // Utiliza ListView.separated para adicionar espaçamento entre os cartões
            itemCount: docs.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: 10), // Adiciona espaçamento entre os cartões
            itemBuilder: (context, index) {
              var doc = docs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: ListTile(
                  title: Text(
                    doc['name'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          height:
                              4), // Adiciona espaçamento entre o nome e as outras informações
                      Text('CNPJ: ${doc['cnpj']}'),
                      Text('Cidade: ${doc['cidade']}'),
                      Text('Telefone: ${doc['telefone']}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit,
                            size: 28), // Define o tamanho do ícone como 24
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  updateClientes(docId: doc.id),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete,
                            size: 28), // Define o tamanho do ícone como 24
                        onPressed: () {
                          doc.reference.delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text('Cliente excluído com sucesso.'),
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
