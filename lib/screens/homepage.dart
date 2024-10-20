import 'package:flutter/material.dart';
import '../styles/styles.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanner_app/screens/cadastrarVendas.dart';
import 'package:scanner_app/screens/cadastrarProdutos_page.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
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
        showConfirmationDialog(context, scannedBarcode);
      } else {
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
  void initState() {
    super.initState();
    importarDadosParaFirestore(); // Chamar a função durante a inicialização do aplicativo
  }

  Future<void> importarDadosParaFirestore() async {
    try {
      // Carregar o arquivo JSON
      final String jsonString =
          await rootBundle.loadString('assets/seu_arquivo.json');
      final Map<String, dynamic> dados = json.decode(jsonString);

      // Iterar sobre os dados e adicionar ao Firestore
      final collectionRef = FirebaseFirestore.instance.collection('Dataset');
      for (String chave in dados.keys) {
        await collectionRef.doc(chave).set(dados[chave]);
      }

      print('Importação concluída com sucesso!');
    } catch (e) {
      print('Erro ao importar os dados: $e');
    }
  }

  Future<void> showConfirmationDialog(
      BuildContext context, String scannedBarcode) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Código de Barras Encontrado'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Deseja ir para a tela de vendas?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Não'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o pop-up
              },
            ),
            TextButton(
              child: Text('Sim'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o pop-up
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CadastroVendas(scannedBarcode: scannedBarcode),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  double getResponsiveIconSize(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * 0.06; // Ajuste a proporção conforme necessário
  }

  Widget _buildButton(
      {required IconData icon,
      required String label,
      required Function onPressed,
      required BuildContext context}) {
    double iconSize = getResponsiveIconSize(context);
    return FractionallySizedBox(
      widthFactor: 0.6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 1).withOpacity(0.15),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextButton(
          style: StylesProntos.estiloBotaoPadrao(context),
          onPressed: () => onPressed(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: iconSize, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  label,
                  style: StylesProntos.textBotao(context, '16', Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(250, 191, 79, 1),
        title: Text(
          "Seja Bem Vindo(a)!",
          style: TextStyle(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            // Container(
            //   child: Center(
            //     child: FractionallySizedBox(
            //       widthFactor: 0.6,
            //       child: Image.asset(
            //         "lib/images/icon.png",
            //         width: 30,
            //       ),
            //     ),
            //   ),
            // ),
            Expanded(
              child: Center(
                child: ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    SizedBox(height: 40),
                    _buildButton(
                      icon: Icons.people,
                      label: 'Clientes',
                      onPressed: () =>
                          Navigator.pushNamed(context, "/clientes"),
                      context: context,
                    ),
                    SizedBox(height: 25),
                    _buildButton(
                      icon: Icons.shopping_cart,
                      label: 'Produtos',
                      onPressed: () =>
                          Navigator.pushNamed(context, "/tabelaProdutos"),
                      context: context,
                    ),
                    SizedBox(height: 25),
                    _buildButton(
                      icon: Icons.sell,
                      label: 'Vendas',
                      onPressed: () =>
                          Navigator.pushNamed(context, "/vendasScreen"),
                      context: context,
                    ),
                    SizedBox(height: 25),
                    _buildButton(
                      icon: Icons.qr_code_scanner,
                      label: 'Leitura Produto',
                      onPressed: () => scanAndCheckBarcode(),
                      context: context,
                    ),
                    SizedBox(height: 100),
                    _buildButton(
                      icon: Icons.align_horizontal_left_rounded,
                      label: 'Análises',
                      onPressed: () =>
                          Navigator.pushNamed(context, "/analises"),
                      context: context,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
