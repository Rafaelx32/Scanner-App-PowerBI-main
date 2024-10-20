import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/services.dart';
import 'package:scanner_app/styles/styles.dart';

class Product {
  String? idPronto;
  String? nomeProd;
  String? qtd;
  double? precoVenda;
  TextEditingController controller;

  Product({this.idPronto, this.nomeProd, this.qtd, this.precoVenda})
      : controller = TextEditingController(text: nomeProd ?? '');
}

class AtualizacaodeVendas extends StatefulWidget {
  final DocumentSnapshot document;
  AtualizacaodeVendas(this.document);

  @override
  _AtualizacaodeVendasState createState() => _AtualizacaodeVendasState();
}

class _AtualizacaodeVendasState extends State<AtualizacaodeVendas> {
  final nomeCliente = TextEditingController();
  String? data;
  String? time;
  List<Product> produtos = [];

  @override
  void initState() {
    super.initState();
    Map<String, dynamic> data = widget.document.data() as Map<String, dynamic>;
    nomeCliente.text = data['nomeCliente'];
    List<dynamic> produtosList = data['produtos'];
    produtos = produtosList.map((produto) {
      return Product(
        idPronto: produto['idProduto'],
        nomeProd: produto['nomeProd'],
        qtd: produto['qtd'],
        precoVenda: produto['precoVenda'],
      );
    }).toList();
  }

  void atualizarProdutosVendas(BuildContext context) {
    returnTime();
    if (nomeCliente.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, insira o nome do cliente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (produtos.isEmpty ||
        produtos.any((produto) =>
            produto.idPronto == null ||
            produto.nomeProd == null ||
            produto.qtd == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, preencha todos os campos do produto.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Calcular o total da venda
    double totalVenda = produtos.fold(0, (total, produto) {
      double produtoTotal = double.parse(produto.qtd!) * produto.precoVenda!;
      return total + produtoTotal;
    });

    // Atualizar no Firestore
    FirebaseFirestore.instance.collection('Vendas').doc(widget.document.id).update({
      'Data': returnTime()['data'],
      'Time': returnTime()['time'],
      'nomeCliente': nomeCliente.text,
      'produtos': produtos.map((produto) {
        return {
          'idProduto': produto.idPronto,
          'nomeProd': produto.nomeProd,
          'qtd': produto.qtd,
          'precoVenda': produto.precoVenda,
          'total': double.parse(produto.qtd!) * produto.precoVenda!,
        };
      }).toList(),
      'totalVenda': totalVenda, // Adiciona o total da venda aqui
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Venda atualizada com sucesso.'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pushReplacementNamed(context, '/telaResumo');
  }

  void removerUltimosProdutos() {
    setState(() {
      produtos.removeRange(produtos.length - 1, produtos.length);
    });
  }

  Map<String, dynamic> returnTime() {
    final DateTime dateNow = DateTime.now();
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final timeFormatter = DateFormat('HH:mm');
    final formattedDate = dateFormatter.format(dateNow);
    final formattedTime = timeFormatter.format(dateNow);
    return {"data": formattedDate, "time": formattedTime};
  }

  Future<List<DocumentSnapshot>> buscarProdutos(String query) async {
    query = query.toLowerCase();
    var result = await FirebaseFirestore.instance.collection('Produtos').get();

    return result.docs.where((doc) {
      var referencia = doc['referencia'].toString().toLowerCase();
      return referencia.contains(query);
    }).toList();
  }

  Future<List<DocumentSnapshot>> buscarClientes(String query) async {
    query = query.toLowerCase();
    var result = await FirebaseFirestore.instance.collection('Clientes').get();

    return result.docs.where((doc) {
      var nomeCliente = doc['name'].toString().toLowerCase();
      return nomeCliente.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: StylesProntos.colorPadrao,
        title: Text(
          "Editar Vendas",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TypeAheadFormField<DocumentSnapshot>(
              textFieldConfiguration: TextFieldConfiguration(
                decoration: InputDecoration(
                  labelText: 'Insira ou selecione o nome do cliente',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                controller: nomeCliente,
              ),
              suggestionsCallback: (pattern) async {
                return await buscarClientes(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion['name']),
                );
              },
              onSuggestionSelected: (suggestion) {
                setState(() {
                  nomeCliente.text = suggestion['name'];
                });
              },
              noItemsFoundBuilder: (context) => Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Nenhum Cliente encontrado.'),
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView(
                children: [
                  for (var produto in produtos)
                    Column(
                      children: [
                        Text(
                          'Produto ${produtos.indexOf(produto) + 1}',
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                        SizedBox(height: 10.0),
                        TypeAheadFormField<DocumentSnapshot>(
                          textFieldConfiguration: TextFieldConfiguration(
                            decoration: InputDecoration(
                              labelText: 'Insira ou selecione a referência do produto',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            controller: produto.controller,
                          ),
                          suggestionsCallback: (pattern) async {
                            return await buscarProdutos(pattern);
                          },
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Text(suggestion['referencia']),
                            );
                          },
                          onSuggestionSelected: (suggestion) {
                            setState(() {
                              produto.idPronto = suggestion.id;
                              produto.nomeProd = suggestion['referencia'];
                              produto.precoVenda = double.tryParse(
                                  suggestion['precoVenda']
                                      .replaceAll('.', '')
                                      .replaceAll(',', '.'));
                              produto.controller.text = suggestion['referencia'];
                            });
                          },
                          noItemsFoundBuilder: (context) => Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Nenhum produto encontrado.'),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Quantidade',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          initialValue: produto.qtd,
                          onChanged: (value) {
                            setState(() {
                              produto.qtd = value;
                            });
                          },
                        ),
                        SizedBox(height: 16.0),
                        if (produto.precoVenda != null && produto.qtd != null && produto.qtd!.isNotEmpty)
                          Text(
                            'Total: R\$${(produto.precoVenda! * int.parse(produto.qtd!)).toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 18, color: Colors.black),
                          ),
                        SizedBox(height: 16.0),
                      ],
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (produtos.isNotEmpty)
                  TextButton(
                    style: StylesProntos.pequenoBotaoRed(context),
                    onPressed: removerUltimosProdutos,
                    child: Text(
                      '-',
                      style: StylesProntos.textBotao(context, '20', Colors.white),
                    ),
                  ),
                TextButton(
                  style: StylesProntos.pequenoBotaoVerde(context),
                  onPressed: () {
                    setState(
                      () {
                        produtos.add(Product());
                      },
                    );
                  },
                  child: Text(
                    '+',
                    style: StylesProntos.textBotao(context, '20', Colors.white),
                  ),
                ),
                TextButton(
                  style: StylesProntos.pequenoBotaoBlue(context),
                  onPressed: () => atualizarProdutosVendas(context),
                  child: Text(
                    '✓',
                    style: StylesProntos.textBotao(context, '20', Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
