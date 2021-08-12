# PersistentContext

A Flutter widget that provides a simple and synchronous interface to store
persistent variables, relying on shared preferences under the hood.

## Basic Usage

To start using persistent variables in one of your widgets simply wrap it inside
a `PersistentContext` widget. You can access the instance of PersistentContext
and its methods through `PersistentContext.of(context)` from any descendant
widget.

Simply call the method `set(key, value)` to set a persistent variable named
`key` with value `value` and `get(key)` to access the value. Be aware that
`value` can only have the following types, due to shared preferences
limitations:

- `int`
- `double`
- `bool`
- `String`

Every time a value is set, it will be reflected immediately on the UI, and made
persistent asynchronously in background.

When your app is first started, however, data will be loaded asynchronously from
local storage, so the `get` method may return `null` (or the default value, if
specified) if called before PersistentContext is initialized.

You can check the `ready` future to wait for initialization completion and avoid
any inconvenience.

The following example illustrates how to use PersistentContext to build a simple
counter app that holds the count persistently. Note that no stateful widget is
required, as PersistentContext acts also as a simple state manager.

```dart
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
          child: PersistentContext(
            child: CounterWidget(),
          ),
        ),
      ),
    );
  }
}

class CounterWidget extends StatelessWidget {
  void _increment(BuildContext context) {
    final currentCount = PersistentContext.of(context).get('counter') ?? 0;
    PersistentContext.of(context).set(
      'counter',
      currentCount + 1,
    );
  }

  void _reset(BuildContext context) {
    PersistentContext.of(context).set('counter', 0);
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
          '${PersistentContext.of(context).get('counter') ?? 0}',
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
```

## Advanced features

PersistentContext constructor features the following optional arguments, that
may be useful in advanced use cases:

- `defaultValues`: a map of keys and values that define default values for
  persistent records. Note that if a default value has been defined, a variable
  can only be set to values of the same type.

- `prefix`: a string prefix that will be added to all keys in shared
  preferences. It should be used in case of multiple instances of
  PersistentContext to avoid collisions.

- `sharedPreferencesInstance`: an instance of `SharedPreferences` that can be
  used immediately, if already available. If not provided, the constructor will
  instantiate a new `SharedPreferences` object asynchronously, resulting in a
  small delay.

The following snippet illustrates how to use such arguments in the previous
example:

```dart
PersistentContext(
    child: CounterWidget(),
    prefix: 'counterContext',
    defaultValues: {
        'counter': 0,
    },
    sharedPreferencesInstance: sharedPrefs,
)
```

## Extending

To keep your code as clean and robust as possible, it is recommended that you
don't use PersistentContext directly, but rather extend it with a custom class
that calls `get` and `set` methods through dedicated getters and setters for
each persistent variable, and also defines statically the default values.

Consider for example the following implementation for the counter app example:

```dart
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
```

The methods `_increment` and `_reset` from `CounterWidget` can then be
simplified as follows:

```dart
void _increment(BuildContext context) {
  CustomPersistentContext.of(context).counter++;
}

void _reset(BuildContext context) {
  CustomPersistentContext.of(context).counter = 0;
}
```
