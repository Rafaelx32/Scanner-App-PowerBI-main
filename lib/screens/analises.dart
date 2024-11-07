import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanner_app/screens/updateClientes.dart';
import 'package:scanner_app/styles/styles.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter/webview_flutter.dart';

class analises extends StatelessWidget {
  analises({Key? key}) : super(key: key);

  // Insira o link do seu dashboard do Power BI aqui
  final String powerBiDashboardUrl =
      'https://app.powerbi.com/view?r=eyJrIjoiMWFiY2QyMGItZmEyOC00NDE1LTg5MjYtM2UwZmMxODllOTM1IiwidCI6ImE3MWVmZTEyLTIxOGQtNDgwMy05NWJkLTRjODk2YmE3Y2U2NiJ9';

  final WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {},
        onPageFinished: (String url) {},
        onHttpError: (HttpResponseError error) {},
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith('https://www.youtube.com/')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    )
    ..loadRequest(Uri.parse(
        'https://app.powerbi.com/view?r=eyJrIjoiMWFiY2QyMGItZmEyOC00NDE1LTg5MjYtM2UwZmMxODllOTM1IiwidCI6ImE3MWVmZTEyLTIxOGQtNDgwMy05NWJkLTRjODk2YmE3Y2U2NiJ9')); // Altere aqui

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: StylesProntos.colorPadrao,
        title: Text(
          "Análise",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: WebViewWidget(
          controller: controller), // Exibe o WebView com o Power BI
    );
  }
}
