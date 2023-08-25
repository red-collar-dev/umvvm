import 'package:flutter/material.dart';
import 'package:sample_database/domain/global/global_store.dart';

class TestBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      color: Colors.white,
      child: Column(
        children: [
          const Text('Test bottom sheet'),
          TextButton(
              onPressed: () {
                app.navigation.pop();
              },
              child: const Text('Close'))
        ],
      ),
    );
  }
}
