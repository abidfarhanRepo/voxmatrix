import 'package:flutter/material.dart';
import 'mesh_gradient_background.dart';

class GlassScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Widget? drawer;

  const GlassScaffold({
    super.key,
    this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBody = true, // Default to true for glass effect
    this.extendBodyBehindAppBar = true, // Default to true for glass effect
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Full-screen live background (slides under system elements)
        const Positioned.fill(
          child: MeshGradientBackground(),
        ),
        // 2. Transparent Scaffold for UI elements
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          // Wrap body in SafeArea if we want to protect it from notches/status bars
          // but let the background flow under.
          body: appBar == null 
            ? SafeArea(child: body ?? const SizedBox()) 
            : body,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          drawer: drawer,
        ),
      ],
    );
  }
}
