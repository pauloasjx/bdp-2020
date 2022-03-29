import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:opencv/core/imgproc.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class Classifier {
  Classifier(this.name);

  String name;
  Interpreter interpreter;

  init() async {
    interpreter = await Interpreter.fromAsset(this.name);
  }

  Future<img.Image> single(Uint8List pimage) async {
    img.Image image = img.decodeImage(pimage);

    var t = min(image.height, image.width)~/12;
    if(t.isEven) {
      t += 1;
    }
    final filterSize = t.toDouble();

    img.Image imageBlur = img.decodeImage(await ImgProc.gaussianBlur(pimage, [filterSize, filterSize], 0));

    img.Image rImage = img.copyResize(image, width: 256, height: 256);
    final input = toList(rImage).reshape([1, 256, 256, 3]);
    final output = List(1 * 256 * 256 * 1).reshape([1, 256, 256, 1]);

    interpreter.run(input, output);

    final mask = output[0];

    final hs = 256 / image.height;
    final ws = 256 / image.width;

    for (var i = 0; i < image.height; i++) {
      for (var j = 0; j < image.width; j++) {
        final ph = (i * hs).toInt();
        final pw = (j * ws).toInt();
        if (mask[ph][pw][0] > 0.5) {
          var shw = 0.0;
          var shh = 0;
          for(var mi = -1; mi<2; mi++) {
            for(var mj = -1; mj<2; mj++) {
              shw += mask[max(ph+mi, 0)][min(pw+mj, 255)][0];
              shh += 1;
            }
          }
          shw = shw/shh;
          final imagePixel = image.getPixel(j, i);
          final imageBlurPixel = imageBlur.getPixel(j, i);

          final rr = (shw * img.getRed(imageBlurPixel) + (1-shw) * img.getRed(imagePixel)).toInt();
          final gg = (shw * img.getGreen(imageBlurPixel) + (1-shw) * img.getGreen(imagePixel)).toInt();
          final bb = (shw * img.getBlue(imageBlurPixel) + (1-shw) * img.getBlue(imagePixel)).toInt();

          image.setPixel(j, i, img.getColor(rr, gg, bb));
        }
      }
    }

    return image;
  }

  batch() {
    //TODO
  }

  Float32List toList(img.Image image, { channels = 3}) {
    var convertedBytes = Float32List(1 * 256 * 256 * channels);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < 256; i++) {
      for (var j = 0; j < 256; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = img.getRed(pixel) / 255.0;
        buffer[pixelIndex++] = img.getGreen(pixel) / 255.0;
        buffer[pixelIndex++] = img.getBlue(pixel) / 255.0;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }
}
