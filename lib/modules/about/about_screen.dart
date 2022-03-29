import 'package:borrador_placas/variables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';

class AboutScreen extends StatefulWidget {
  AboutScreen();

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sobre"),
        backgroundColor: primaryColor,
      ),
      body: Container(
        margin: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Opacity(
                child: SizedBox(
                    child: Image.asset('assets/images/logo.png'),
                    height: 150.0),
                opacity: 0.25),
            SizedBox(height: 8.0),
            Html(data: """
              O app não precisa de conexão com a internet para funcionar, ou seja: <b>todo processamento acontece no seu smartphone e suas imagens não são enviadas para nenhum servidor através da internet</b>.
              <br>
              O ad é exibido no momento que as imagens são processadas.
              O modelo não está utilizando por padrão a gpu do dispositivo, talvez em versões futuras seja atualizado para melhor performance em imagens de alta resolução.
            """, style: {
             "b": Style(
               color: primaryColor
             ),
              "html": Style(
                textAlign: TextAlign.justify
              )
            }),
          ],
        ),
      )
    );
  }
}
