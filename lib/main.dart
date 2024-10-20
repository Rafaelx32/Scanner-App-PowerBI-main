import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'package:firebase_core/firebase_core.dart';


const firebaseConfig = FirebaseOptions(
      apiKey: "AIzaSyCXbA5x7S9R7-93c9T82nNwnBy7WDdeZc4",
      authDomain: "scanner-app-4c13b.firebaseapp.com",
      projectId: "scanner-app-4c13b",
      storageBucket: "scanner-app-4c13b.appspot.com",
      messagingSenderId: "860734642829",
      appId: "1:860734642829:web:59d9629a9dcd544202e0c4");
void main() {
  WidgetsFlutterBinding.ensureInitialized();//aguardando flutter carregar para carregar o firebase
  Firebase.initializeApp(options: firebaseConfig);
  runApp(const ScannerApp()); //rodando de fato o APP
}
