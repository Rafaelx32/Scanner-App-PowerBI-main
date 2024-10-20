// ignore_for_file: prefer_const_constructors
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:scanner_app/styles/styles.dart';
import 'dart:io';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:extended_masked_text/extended_masked_text.dart';

class CadastrarProdutosPage extends StatefulWidget {
  final String codigoBarras;

  CadastrarProdutosPage({Key? key, required this.codigoBarras})
      : super(key: key);

  @override
  _CadastrarProdutosPageState createState() => _CadastrarProdutosPageState();
}

class _CadastrarProdutosPageState extends State<CadastrarProdutosPage> {
  String randomNumbers = '';
  final imagePicker = ImagePicker();
  File? imageFile;
  // Instancie um objeto Uuid
  Uuid uuid = Uuid();

  @override
  void initState() {
    super.initState();
    if (widget.codigoBarras.isEmpty) {
      _generatedRandomNumber();
    } else {
      randomNumbers = widget.codigoBarras;
    }
  }

  _pick(ImageSource source) async {
    final pickedFile = await imagePicker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
      // _uploadImageToFirebase(pickedFile.path);
    }
  }

  Future<String> _uploadImageToFirebase(String imagePath) async {
    final storage = FirebaseStorage.instance;
    File file = File(imagePath);
    try {
      String imageName = "images/img-${DateTime.now().toString()}.png";
      await storage.ref(imageName).putFile(file);
      String imageUrl = await storage.ref(imageName).getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      return '';
    }
  }

  void _generatedRandomNumber() {
    setState(() {
      randomNumbers = List.generate(12, (index) => Random().nextInt(10)).join();
    });
  }

  final txtDescricao = TextEditingController();
  final txtPrecoVenda =
      MoneyMaskedTextController(thousandSeparator: '.', precision: 2);
  final txtReferencia = TextEditingController();

  void _Cadastrar(BuildContext context) async {
    List<String> camposNaoPreenchidos = [];

    if (txtDescricao.text.isEmpty) {
      camposNaoPreenchidos.add("Descrição");
    }

    if (txtPrecoVenda.text.isEmpty) {
      camposNaoPreenchidos.add("Preço de venda");
    }

    if (txtReferencia.text.isEmpty) {
      camposNaoPreenchidos.add("Referência");
    }

    if (randomNumbers.isEmpty) {
      camposNaoPreenchidos.add("Código de Barras");
    }

    if (imageFile == null) {
      camposNaoPreenchidos.add("Imagem");
    }

    if (camposNaoPreenchidos.isNotEmpty) {
      String mensagem = "Os seguintes campos não foram preenchidos:\n";
      mensagem += camposNaoPreenchidos.join(",\n");

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Campos Obrigatórios"),
            content: Text(mensagem),
            actions: <Widget>[
              TextButton(
                child: Text("Ok"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    if (imageFile != null) {
      String imageUrl = await _uploadImageToFirebase(imageFile!.path);
      String productId = uuid.v4();
      FirebaseFirestore.instance.collection('Produtos').add(
        {
          'descricao': txtDescricao.text,
          'precoVenda': txtPrecoVenda.text,
          'referencia': txtReferencia.text,
          'codigoBarras': randomNumbers,
          'produtoId': productId,
          'imageUrl': imageUrl,
        },
      ).then((DocumentReference docRef) {
        print('ID do produto cadastrado: $productId');
        _uploadImageToFirebase(imageFile!.path);
      }).catchError((error) {
        print('Erro ao cadastrar o produto: $error');
      });
      Navigator.pop(context);
    }
  }

  void _ShowOpcoesBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      PhosphorIcons.download(),
                    ),
                  ),
                ),
                title: Text(
                  'Galeria',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pick(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      PhosphorIcons.camera(),
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                title: Text(
                  'Câmera',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      PhosphorIcons.trash(),
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                title: Text(
                  'Remover',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    imageFile = null;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Cadastro de Produtos",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: StylesProntos.colorPadrao,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 60),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 75,
                        backgroundColor: Colors.grey[200],
                        child: CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              imageFile != null ? FileImage(imageFile!) : null,
                        ),
                      ),
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: IconButton(
                            onPressed: _ShowOpcoesBottomSheet,
                            icon: Icon(
                              PhosphorIcons.pencilSimple(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: 50,
              ),
              TextField(
                controller: txtDescricao,
                decoration: InputDecoration(
                  label: Text("Descrição"),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 15),
              TextField(
                controller: txtPrecoVenda,
                decoration: InputDecoration(
                  label: Text("Preço de Venda"),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixText: "R\$",
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 15),
              TextField(
                controller: txtReferencia,
                decoration: InputDecoration(
                  label: Text("Referência"),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 50),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                onPressed: _generatedRandomNumber,
                child: Text(
                  randomNumbers.isEmpty
                      ? 'Gerar Novo Código de Barras'
                      : 'Código de Barras: $randomNumbers',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 25),
              Container(
                width: 150,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () => _Cadastrar(context),
                  child: Text(
                    "Cadastrar",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
