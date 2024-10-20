import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'dart:io';
import 'package:extended_masked_text/extended_masked_text.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:scanner_app/styles/styles.dart';
import 'package:uuid/uuid.dart';

// Update page
class UpdateProdutosPage extends StatefulWidget {
  final DocumentSnapshot document;
  UpdateProdutosPage(this.document);

  @override
  State<UpdateProdutosPage> createState() => _UpdateProdutosPageState();
}

class _UpdateProdutosPageState extends State<UpdateProdutosPage> {
  late TextEditingController txtDescricao;
  late MoneyMaskedTextController txtPrecoVenda;
  late TextEditingController txtReferencia;
  late ImagePicker imagePicker;
  late String newImageUrl;
  File? imageFile;
  Uuid uuid = Uuid();

  @override
  void initState() {
    super.initState();
    txtDescricao = TextEditingController();
    txtPrecoVenda =
        MoneyMaskedTextController(thousandSeparator: '.', precision: 2);
    txtReferencia = TextEditingController();
    imagePicker = ImagePicker();
    newImageUrl = widget.document['imageUrl'];
    load();
  }

  load() async {
    var doc = await FirebaseFirestore.instance
        .collection('Produtos')
        .doc(widget.document.id)
        .get();

    if (doc.exists) {
      var data = doc.data();
      if (data != null) {
        txtDescricao.text = data['descricao'] ?? '';
        txtPrecoVenda.text = data['precoVenda'] ?? '';
        txtReferencia.text = data['referencia'] ?? '';

        String? imageUrl = data['imageUrl'];

        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final http.Response response = await http.get(Uri.parse(imageUrl));
            final List<int> imageData = response.bodyBytes;
            setState(() {
              imageFile = File.fromRawPath(Uint8List.fromList(imageData));
            });
          } catch (e) {
            print('Erro ao carregar a imagem: $e');
            // Lidar com o erro, por exemplo, exibir uma imagem padrão
            setState(() {
              imageFile = null; // Pode definir uma imagem padrão aqui
            });
          }
        } else {
          // Se não houver URL de imagem válido, definir uma imagem padrão
          setState(() {
            imageFile = null; // Defina uma imagem padrão aqui
          });
        }
      }
    }
  }

  void _UpdateProdutos(BuildContext context) async {
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
      String ImageUrl = await _uploadImageToFirebase(imageFile!.path);
      String productId = uuid.v4();
      FirebaseFirestore.instance
          .collection('Produtos')
          .doc(widget.document.id)
          .update(
        {
          'descricao': txtDescricao.text,
          'precoVenda': txtPrecoVenda.text,
          'referencia': txtReferencia.text,
          'produtoId': productId,
          'imageUrl': newImageUrl,
        },
      );
      Navigator.pop(context);
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text("Erro ao cadastrar produto"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('ok'),
                )
              ],
            );
          });
    }
  }

  FirebaseStorage _storage = FirebaseStorage.instance;

  _pick(ImageSource source) async {
    final XFile? xFile = await imagePicker.pickImage(source: source);

    if (xFile != null) {
      setState(() {
        imageFile = File(xFile.path);
      });
      _uploadImageToFirebase(xFile.path);
    }
  }

  Future<String> _uploadImageToFirebase(String imagePath) async {
    final storage = FirebaseStorage.instance;
    File file = File(imagePath);
    try {
      String imageName = "images/img-${DateTime.now().toString()}.png";
      await storage.ref(imageName).putFile(file);
      String imageUrl = await storage.ref(imageName).getDownloadURL();
      setState(() {
        newImageUrl = imageUrl;
      });
      return imageUrl;
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      return '';
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
          backgroundColor: StylesProntos.colorPadrao,
          title: Text(
            "Atualizar Produtos",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                            backgroundImage: NetworkImage(newImageUrl),
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
                  height: 15,
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
                TextFormField(
                  controller: txtPrecoVenda,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    label: Text("Preço de Venda"),
                    prefixText: "R\$",
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: txtReferencia,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    label: Text("Referência"),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 15),
                Container(
                  width: 150,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.blue),
                    ),
                    child: Text(
                      "Atualizar",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    onPressed: () => _UpdateProdutos(context),
                  ),
                ),
                SizedBox(height: 15),
                Container(
                  width: 150,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.red),
                    ),
                    child: Text(
                      "Cancelar",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
