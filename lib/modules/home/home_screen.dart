import 'dart:typed_data';

import 'package:borrador_placas/modules/about/about_screen.dart';
import 'package:borrador_placas/modules/classifier/classifier.dart';
import 'package:borrador_placas/modules/slider/slider_screen.dart';
import 'package:borrador_placas/variables.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen();

  final key = GlobalKey<ScaffoldState>();

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Classifier classifier;
  bool isLoading = false;
  List<Widget> images = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    FirebaseAdMob.instance.initialize(appId: "");
    RewardedVideoAd.instance.listener =
        (RewardedVideoAdEvent event, {String rewardType, int rewardAmount}) {
      print("RewardedVideoAd event $event");
    };
    fetchAlbum();

    super.initState();
  }

  fetchAlbum() async {
    var result = await PhotoManager.requestPermission();
    if (result) {
      List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(onlyAll: true);

      AssetPathEntity album = albums.first;

      List<AssetEntity> media = (await album.assetList)
          .where((AssetEntity element) => element.title.startsWith("image_"))
          .take(100)
          .toList();

      List<Widget> temp = [];
      for (var asset in media) {
        temp.add(
          FutureBuilder(
            future: asset.thumbDataWithSize(200, 200),
            builder: (BuildContext context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done)
                return Image.memory(
                  snapshot.data,
                  fit: BoxFit.cover,
                );
              return Container();
            },
          ),
        );
      }
      setState(() {
        images = temp;
      });
    } else {
      // PhotoManager.openSetting();
    }
  }

  Future<void> selectImages() async {
    List<Asset> resultList = List<Asset>();

    RewardedVideoAd.instance.load(
        // adUnitId: RewardedVideoAd.testAdUnitId,
        adUnitId: "",
        targetingInfo: MobileAdTargetingInfo(
          // testDevices: ["BA1CDCAB96026DABF5401EE5B3FF6A74"],
          keywords: <String>['carro', 'moto', 'caminhão', 'seguro'],
          childDirected: true,
          nonPersonalizedAds: true,
        ));

    try {
      setState(() {
        isLoading = true;
      });
      resultList = await MultiImagePicker.pickImages(
        maxImages: 300,
        enableCamera: true,
        // selectedAssets: images,
        materialOptions: MaterialOptions(
          actionBarColor: "#2339FF",
          actionBarTitle: "Selecione fotos com placas",
          allViewTitle: "Suas imagens",
          useDetailsView: false,
          selectCircleStrokeColor: "#000000",
        ),
      );
    } on Exception catch (e) {
      print(e.toString());
      setState(() {
        isLoading = false;
      });
    }

    if (!mounted || resultList.isEmpty) return;

    classifier = Classifier('plate256.tflite');
    await classifier.init();

    RewardedVideoAd.instance.show();

    final List<img.Image> blurredImages =
        await Future.wait(resultList.map((e) async {
      ByteData imageBytes = (await e.getByteData());
      Uint8List input = imageBytes.buffer
          .asUint8List(imageBytes.offsetInBytes, imageBytes.lengthInBytes);

      final result = await classifier.single(input);

      return result;
    }));

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SliderScreen(blurredImages)),
    ).then((value) {
      final snackBar = SnackBar(
          content: Text('Imagens salvas na sua galeria!',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black);

      if (value == true) {
        _scaffoldKey.currentState.showSnackBar(snackBar);
      }

      setState(() {
        fetchAlbum();
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Borrador de Placas"),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (value) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutScreen()),
              );
            },
            itemBuilder: (BuildContext context) {
              return {'Sobre'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
        backgroundColor: primaryColor,
      ),
      floatingActionButton: Opacity(
        opacity: isLoading ? 0.25 : 1.0,
        child: FloatingActionButton.extended(
            onPressed: isLoading ? null : selectImages,
            icon: Icon(Icons.add),
            backgroundColor: Colors.black,
            label: Text("Selecionar fotos",
                style: TextStyle(
                    fontWeight: FontWeight.bold, letterSpacing: 0.0))),
      ),
      body: Stack(
        children: [
          Opacity(
              opacity: isLoading ? 0.25 : 1.0,
              child: images.isNotEmpty
                  ? GridView.builder(
                      itemCount: images.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3),
                      itemBuilder: (BuildContext context, int index) {
                        return images[index];
                      })
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                              child: SizedBox(
                                  child: Image.asset('assets/images/logo.png'),
                                  height: 150.0),
                              opacity: 0.25),
                          SizedBox(height: 8.0),
                          Text("Você não possui nenhuma\n foto recente.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey))
                        ],
                      ),
                    )),
          isLoading
              ? Center(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                        backgroundColor: Colors.white,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(primaryColor)),
                    SizedBox(height: 8.0),
                    Container(
                      margin: EdgeInsets.all(48.0),
                      child: Html(data: """
          <b>Essa etapa pode demorar alguns instantes</b>, dependendo da quantidade de fotos e suas resoluções.
        """, style: {
                        "b": Style(color: primaryColor),
                        "html": Style(textAlign: TextAlign.center)
                      }),
                    )
                  ],
                ))
              : Container(),
        ],
      ),
    );
  }
}
