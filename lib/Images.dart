import 'package:flutter/material.dart';

class Images extends StatelessWidget{

  const Images({super.key});

  @override
  Widget build(BuildContext context) {
    AssetImage assetImage = AssetImage("images/tooth_icon.png");
    Image image = Image(image: assetImage, width: 200.0, height: 200.0);
    return Container(child: image);
  }

  static Widget getImage(String name, double width, double height){
    AssetImage assetImage = AssetImage(name);
    Image image = Image(image: assetImage, width: width, height: height);
    return Container(child: image);
  }

}