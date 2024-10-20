import 'package:flutter/cupertino.dart';
import "package:flutter/material.dart";
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:extended_masked_text/extended_masked_text.dart';
import 'package:scanner_app/styles/styles.dart';

class cadastroClientes extends StatelessWidget {
  final _txtName = TextEditingController();
  final _txtCnpj = MaskedTextController(mask: '00.000.000/0000-00');
  final _txtCidade = TextEditingController();
  final _txtTelefone = MaskedTextController(mask: '(00)00000-0000');

  void _onSaved(BuildContext context) {
    final nameText = _txtName.text.trim();
    if (nameText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('Insira um nome para o Cliente'),
      ));
      return;
    }

    final cnpjText = _txtCnpj.text.trim();
    if (cnpjText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text('Por favor, insira um CNPJ válido')));
      return;
    }

    final cidadeText = _txtCidade.text.trim();
    if (cidadeText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text('Por favor, insira uma Cidade')));
      return;
    }

    final telefoneText = _txtTelefone.text.trim();
    if (telefoneText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text('Por favor, insira uma Número da casa')));
      return;
    }

    FirebaseFirestore.instance.collection('Clientes').add({
      'name': _txtName.text,
      'cnpj': _txtCnpj.text,
      'telefone': _txtTelefone.text,
      'cidade': _txtCidade.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text('Cliente cadastrado com sucesso'),
      ),
    );

    Navigator.pushReplacementNamed(context, "/clientes");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: StylesProntos.colorPadrao,
        title: Text(
          "Cadastro de Clientes",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Container(
        margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _txtName,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text("Nome do Cliente")),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _txtCnpj,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("CNPJ do Cliente"),
                ),
              ),
              SizedBox(height: 10),

              TextField(
                controller: _txtCidade,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("Cidade do Cliente"),
                ),
              ),
              SizedBox(height: 10),

              TextField(
                controller: _txtTelefone,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("Telefone do Cliente"),
                ),
              ),
              SizedBox(height: 10),

              Container(
                margin: EdgeInsets.only(top: 10),
                width: 150,
                child: TextButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.green),
                  ),
                  child: Text(
                    "Salvar",
                    style: StylesProntos.textBotao(context, '14', Colors.white),
                  ),
                  onPressed: () => _onSaved(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
