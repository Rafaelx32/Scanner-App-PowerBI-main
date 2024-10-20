import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:scanner_app/screens/atualizarProdutos.dart';
import 'package:scanner_app/styles/styles.dart';
import 'package:scanner_app/screens/homepage.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'cadastrarProdutos_page.dart';
import 'cadastrarVendas.dart';

class TelaProduto extends StatefulWidget {
  @override
  _TelaProduto createState() => _TelaProduto();
}

class _TelaProduto extends State<TelaProduto> {
  final firestore = FirebaseFirestore.instance;
  String barcode = '';

  Future<String> scanBarcode() async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Cancelar',
        true,
        ScanMode.BARCODE,
      );
      return barcodeScanRes;
    } catch (e) {
      return '';
    }
  }

  Future<bool> checkBarcodeExists(String barcode) async {
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection('Produtos')
        .where('codigoBarras', isEqualTo: barcode)
        .get();
    final List<DocumentSnapshot> documents = result.docs;
    return documents.isNotEmpty;
  }

  Future<void> scanAndCheckBarcode() async {
    String scannedBarcode = await scanBarcode();
    if (scannedBarcode == '-1') {
      return;
    }
    if (scannedBarcode.isNotEmpty) {
      bool exists = await checkBarcodeExists(scannedBarcode);
      setState(() {
        barcode = scannedBarcode;
      });
      if (exists) {
        // Código de barras já existe no Firestore
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Código de barras encontrado no banco de dados!'),
          backgroundColor: Colors.green,
        ));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CadastroVendas(scannedBarcode: scannedBarcode),
          ),
        );
      } else {
        // Código de barras não existe no Firestore
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Código de barras não encontrado no banco de dados.'),
          backgroundColor: Colors.red,
        ));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CadastrarProdutosPage(
              codigoBarras: scannedBarcode,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: StylesProntos.colorPadrao,
        title: Text(
          "Tela de Produtos",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true, // centraliza o titulo
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: StylesProntos.colorPadrao,
        onPressed: () => Navigator.pushNamed(context, "/cadastroProdutos"),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore.collection('Produtos').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          return ListView(
            padding: EdgeInsets.only(top: 13),
            children: snapshot.data!.docs.map(
              (DocumentSnapshot document) {
                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                  child: ListTile(
                    leading: data['imageUrl'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              data['imageUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) {
                                  return child; // Imagem carregada, exibe a imagem
                                }
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey
                                          .shade200, // Fundo cinza claro enquanto carrega
                                    ),
                                    CircularProgressIndicator(), // Mostra o indicador de carregamento
                                  ],
                                );
                              },
                            ),
                          )
                        : Icon(Icons.image_not_supported),

                    title: Text(
                      data['descricao'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ), // deixa as letras mais escuras
                    subtitle: Text(
                      data['precoVenda'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ), // deixa as letras mais escuras
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit,
                              size: 28), // Define o tamanho do ícone como 28
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UpdateProdutosPage(document),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete,
                              size: 28), // Define o tamanho do ícone como 28
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Confirmar exclusão'),
                                content: Text(
                                    'Tem certeza que deseja excluir este produto?'),
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
                                          .collection('Produtos')
                                          .doc(document.id)
                                          .delete();
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('confirmar'),
                                  )
                                ],
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            ).toList(),
          );
        },
      ),
    );
  }
}
