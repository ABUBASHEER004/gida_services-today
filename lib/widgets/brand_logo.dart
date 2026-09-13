import 'package:flutter/material.dart';
class BrandLogo extends StatelessWidget{final double size;final BoxFit fit;const BrandLogo({super.key,this.size=88,this.fit=BoxFit.contain});@override Widget build(BuildContext context)=>Image.asset('assets/logo.png',width:size,height:size,fit:fit,filterQuality:FilterQuality.high);}
