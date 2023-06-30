import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration:
        BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4.0)),
        padding: const EdgeInsets.all(16.0),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      ),
    );
  }
}
