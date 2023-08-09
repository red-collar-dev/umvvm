import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'generators.dart';

Builder generateInstanceCollector(BuilderOptions options) => SharedPartBuilder(
      [InstancesCollectorGenerator()],
      'instances_collector_generator',
      allowSyntaxErrors: true,
    );
Builder generateMainApp(BuilderOptions options) => SharedPartBuilder(
      [MainAppGenerator()],
      'main_app_generator',
      allowSyntaxErrors: true,
    );
Builder generateMainApi(BuilderOptions options) => SharedPartBuilder(
      [MainApiGenerator()],
      'main_api_generator',
      allowSyntaxErrors: true,
    );
