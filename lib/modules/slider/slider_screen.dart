import 'dart:io';

import 'package:borrador_placas/variables.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

class SliderScreen extends StatefulWidget {
  final List<img.Image> images;

  SliderScreen(this.images);

  @override
  _SliderScreenState createState() => _SliderScreenState();
}

class _SliderScreenState extends State<SliderScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Borrador de Placas"),
        // automaticallyImplyLeading: !isLoading,
        backgroundColor: primaryColor,
      ),
      floatingActionButton: Opacity(
        opacity: isLoading ? 0.25 : 1.0,
        child: FloatingActionButton.extended(
            onPressed: isLoading
                ? null
                : () async {
                    var result = await PhotoManager.requestPermission();
                    if (result) {
                      setState(() {
                        isLoading = true;
                      });

                      final directory = await getTemporaryDirectory();
                      Future.forEach(
                              widget.images,
                              (image) async {

                                String path = '${directory.path}/temp.jpg';
                                File file = new File(path);
                                await file
                                    .writeAsBytes(img.encodeJpg(image, quality: 80));

                                return await PhotoManager.editor
                                  .saveImageWithPath(path);
                              })
                          .then((_) {
                        setState(() {
                          isLoading = false;
                          Navigator.pop(context, true);
                        });
                      });
                    }
                  },
            icon: Icon(Icons.save),
            backgroundColor: Colors.black,
            label: Text("Salvar na galeria",
                style: TextStyle(
                    fontWeight: FontWeight.bold, letterSpacing: 0.0))),
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: isLoading ? 0.25 : 1.0,
            child: Builder(
              builder: (context) {
                final double height = MediaQuery.of(context).size.height;
                return CarouselSlider(
                  options: CarouselOptions(
                    height: height,
                    viewportFraction: 1.0,
                    enlargeCenterPage: false,
                    // autoPlay: false,
                  ),
                  items: widget.images
                      .map((image) => Container(
                            child: Center(
                                child: Image.memory(img.encodePng(image),
                                    fit: BoxFit.fitWidth, height: height)),
                          ))
                      .toList(),
                );
              },
            ),
          ),
          isLoading
              ? Center(
                  child: CircularProgressIndicator(
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor)))
              : Container(),
        ],
      ),
    );
  }
}
