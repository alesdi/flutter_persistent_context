import 'package:flutter/material.dart';
import 'package:persistent_context/persistent_context.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PersistentContext Demo',
      home: Scaffold(
        appBar: AppBar(
          title: Text('PersistentContext Demo'),
        ),
        body: Center(
          child: CustomPersistentContext(
            child: CounterWidget(),
          ),
        ),
      ),
    );
  }
}

class CounterWidget extends StatelessWidget {
  void _increment(BuildContext context) {
    CustomPersistentContext.of(context).counter++;
  }

  void _reset(BuildContext context) {
    CustomPersistentContext.of(context).counter = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'This counter will persist after restarting the app:',
        ),
        Text(
          '${CustomPersistentContext.of(context).counter}',
          style: Theme.of(context).textTheme.headline4,
        ),
        ButtonBar(
          alignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _increment(context),
              icon: Icon(Icons.add),
              label: Text('Increment'),
            ),
            ElevatedButton.icon(
              onPressed: () => _reset(context),
              icon: Icon(Icons.refresh),
              label: Text('Reset'),
            ),
          ],
        ),
      ],
    );
  }
}

class CustomPersistentContext extends PersistentContext {
  // Default values
  static final _counterDefault = 0;

  // Constructor
  CustomPersistentContext({
    Key? key,
    required Widget child,
  }) : super(
          key: key,
          child: child,
          defaultValues: {
            'counter': _counterDefault,
          },
        );

  // Getters and setters
  int get counter => get('counter') ?? _counterDefault;

  set counter(int value) {
    set('counter', value);
  }

  // This is needed for `of` method to work
  static CustomPersistentContext of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CustomPersistentContext>()!;
  }
}
