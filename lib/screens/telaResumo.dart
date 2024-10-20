import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:scanner_app/styles/styles.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class TelaResumo extends StatelessWidget {
  TelaResumo({super.key});

  final firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot<Map<String, dynamic>>> getLastSale() async {
    var querySnapshot = await firestore
        .collection('Vendas')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    } else {
      throw Exception('No Sales Found');
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getClientData(
      String clientName) async {
    var querySnapshot = await firestore
        .collection('Clientes')
        .where('name', isEqualTo: clientName)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    } else {
      throw Exception('No Client Found');
    }
  }

  Future<void> _printScreen(BuildContext context) async {
    final doc = pw.Document();

    final saleSnapshot = await getLastSale();
    if (saleSnapshot.data() != null) {
      final saleData = saleSnapshot.data()!;
      final clientName = saleData['nomeCliente'];
      final clientSnapshot = await getClientData(clientName);
      final clientData = clientSnapshot.data()!;
      final produtos = List<Map<String, dynamic>>.from(saleData['produtos']);
      final totalVenda = saleData['totalVenda'] is num ? saleData['totalVenda'] : double.parse(saleData['totalVenda']);

      doc.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Nome do Cliente: $clientName',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('CNPJ: ${clientData['cnpj']}',
                      style: pw.TextStyle(fontSize: 12)),
                  pw.Text('Telefone: ${clientData['telefone']}',
                      style: pw.TextStyle(fontSize: 12)),
                  pw.Text('Cidade: ${clientData['cidade']}',
                      style: pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 20),
                  pw.Text('Data: ${saleData['Data'] ?? "Data não disponível"}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Hora: ${saleData['Time'] ?? "Tempo não disponível"}',
                      style: pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 20),
                  pw.Text('Produtos:',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  ...produtos.map((produto) {
                    final precoVenda = produto['precoVenda'] is num ? produto['precoVenda'] : double.parse(produto['precoVenda']);
                    final qtd = produto['qtd'] is num ? produto['qtd'] : double.parse(produto['qtd']);
                    final totalProduto = precoVenda * qtd;
                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Nome do Produto: ${produto['nomeProd']}',
                            style: pw.TextStyle(fontSize: 12)),
                        pw.Text('Quantidade: ${qtd % 1 == 0 ? qtd.toInt() : qtd}',
                            style: pw.TextStyle(fontSize: 12)),
                        pw.Text('Preço de Venda: R\$${precoVenda.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 12)),
                        pw.Text('Total: R\$${totalProduto.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 12)),
                        pw.SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                  pw.SizedBox(height: 20),
                  pw.Text('Total da Venda: R\$${totalVenda.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            );
          },
        ),
      );

      // Salvar o PDF no dispositivo
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/resumo_venda.pdf");
      await file.writeAsBytes(await doc.save());

      // Compartilhar o PDF
      await Share.shareFiles([file.path], text: 'Resumo da última venda');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: StylesProntos.colorPadrao,
        title: Text("Tela de Resumo", style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: getLastSale(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return Center(child: Text("No sales found"));
          }
          var data = snapshot.data?.data() as Map<String, dynamic>?;

          if (data == null) {
            return Center(child: Text("No data available"));
          }

          List<dynamic> produtos = data['produtos'];
          double totalVenda = data['totalVenda'] is num ? data['totalVenda'] : double.parse(data['totalVenda']);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['nomeCliente'],
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text('Data: ${data['Data'] ?? "Data não disponível"}',
                            style: TextStyle(fontSize: 18)),
                        Text('Hora: ${data['Time'] ?? "Tempo não disponível"}',
                            style: TextStyle(fontSize: 18)),
                        SizedBox(height: 20),
                        Text('Produtos:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                        SizedBox(height: 10),
                        ...produtos.map(
                          (produto) {
                            final precoVenda = produto['precoVenda'] is num ? produto['precoVenda'] : double.parse(produto['precoVenda']);
                            final qtd = produto['qtd'] is num ? produto['qtd'] : double.parse(produto['qtd']);
                            final totalProduto = precoVenda * qtd;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nome do Produto: ${produto['nomeProd']}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text('Quantidade: ${qtd % 1 == 0 ? qtd.toInt() : qtd}',
                                      style: TextStyle(fontSize: 16)),
                                  Text('Preço de Venda: R\$${precoVenda.toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 16)),
                                  Text('Total: R\$${totalProduto.toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 16)),
                                  Divider(),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Total da Venda: R\$${totalVenda.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StylesProntos.colorPadrao,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _printScreen(context),
                  icon: Icon(Icons.share, color: Colors.white),
                  label: Text(
                    'Compartilhar PDF',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
