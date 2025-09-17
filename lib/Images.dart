import 'package:flutter/material.dart';

class Images extends StatelessWidget{

  const Images({super.key});

  @override
  Widget build(BuildContext context) {
    AssetImage assetImage = AssetImage("images/tooth_icon.png");
    Image image = Image(image: assetImage, width: 200.0, height: 200.0);
    return Container(child: image);
  }

  static Widget getIconImage(){
    AssetImage assetImage = AssetImage("images/tooth_icon.png");
    Image image = Image(image: assetImage, width: 200.0, height: 200.0);
    return Container(child: image);
  }

}