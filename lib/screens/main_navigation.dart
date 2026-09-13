import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_router.dart';
import 'providers_screen.dart';
class MainNavigation extends StatefulWidget{const MainNavigation({super.key});@override State<MainNavigation> createState()=>_MainNavigationState();}
class _MainNavigationState extends State<MainNavigation>{int currentIndex=0;late final List<Widget> pages=const[HomeScreen(),ProvidersScreen(),ProfileRouter()];@override Widget build(BuildContext context)=>Scaffold(body:IndexedStack(index:currentIndex,children:pages),bottomNavigationBar:NavigationBar(selectedIndex:currentIndex,onDestinationSelected:(index)=>setState(()=>currentIndex=index),destinations:const[NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded),label:'Home'),NavigationDestination(icon:Icon(Icons.storefront_outlined),selectedIcon:Icon(Icons.storefront_rounded),label:'Providers'),NavigationDestination(icon:Icon(Icons.person_outline_rounded),selectedIcon:Icon(Icons.person_rounded),label:'Profile')]));}
