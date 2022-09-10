import 'package:flutter/material.dart';
import 'package:sample_database/domain/global/global_store.dart';
import 'package:sample_database/domain/interactors/navigation/navigation_interactor.dart';

class TestDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 400,
        color: Colors.white,
        child: Column(
          children: [
            const Text('Test dialog'),
            TextButton(
              onPressed: () {
                app.interactors.get<NavigationInteractor>().pop();
              }, 
              child: const Text('Close')
            )
          ],
        ),
      ),
    );
  }
}
