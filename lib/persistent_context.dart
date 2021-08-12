library persistent_context;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides persistent data from shared preferences to all the descending
/// widgets and allows to update it synchronously.
///
/// Variables are read and written as simple key-values pairs, where
/// the key is a generic [String] and the value has any of the following:
/// [String], [int], [double], [bool].
///
/// For a more robust implementation it is reccomended that you extend this
/// class and add getters and setters for variable, as needed by your
/// application.
class PersistentContext extends InheritedNotifier<PersistentContextNotifier> {
  /// A map of default values for each variable
  final Map<String, dynamic> defaultValues;

  /// A prefix for local preferences names, that can be used to have  variables
  /// with the same name in different contexts of the same app
  final String prefix;

  /// Creates a widget that provides persistent data from shared preferences
  /// to all the descending widgets and allows to update it synchronously.
  ///
  /// A `defaultValues` map can be provided to set the default values of the
  /// variables. A `prefix` string can also be provided, to be used for all
  /// the keys in shared preferences, for example to keep separated different
  /// contexts of your application.
  ///
  /// The [PersistentContext] widget can be accessed from any child as an
  /// [InheritedWidget], with the method `PersistentContext.of(context)`.
  ///
  /// If [sharedPreferencesInstance] is provided, the shared preferences will
  /// be imediately available. Otherwise they will be loaded asynchronously
  /// from storage only once, when the widget is created.
  ///
  /// Any modification requested from the children will be notified immediately
  /// to all the descendants, and automatically consolidated to storage
  /// asynchronously.
  @override
  PersistentContext({
    Key? key,
    required Widget child,
    this.defaultValues = const {},
    this.prefix = '',
    SharedPreferences? sharedPreferencesInstance,
  }) : super(
          key: key,
          notifier: sharedPreferencesInstance != null
              ? PersistentContextNotifier.preloaded(sharedPreferencesInstance)
              : PersistentContextNotifier(),
          child: child,
        ) {
    defaultValues.forEach((key, value) {
      if (!(value is String ||
          value is int ||
          value is double ||
          value is bool)) {
        throw Exception("Invalid default preferences data structure. "
            "The value provided for key '$key' has type "
            "'${value.runtimeType}'. Only 'String', 'int', 'double' and 'bool' "
            "are allowed.");
      }
    });
  }

  /// The [PersistentContext] instance for the given [BuildContext]
  static PersistentContext of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PersistentContext>()!;
  }

  /// Gets a persistent record value given its `key`.
  ///
  /// Returns default value indicated in `defaulValues` if the actual value
  /// doesn't exist or its runtime type value differs from the default one.
  ///
  /// If the key doesn't exists and its default value is not specified, returns
  /// `null`.
  dynamic get(String key) {
    final contextKey = '$prefix:$key';
    final notifierValue = notifier!.value;
    if (defaultValues.containsKey(key)) {
      if (!notifierValue.containsKey(contextKey) ||
          notifierValue[contextKey].runtimeType !=
              defaultValues[key].runtimeType) {
        return defaultValues[key];
      } else {
        return notifierValue[contextKey];
      }
    } else {
      if (notifierValue.containsKey(contextKey)) {
        return notifierValue[contextKey];
      } else {
        return null;
      }
    }
  }

  /// A future that completes with `true` when shared preferences are loaded and
  /// ready to be used. It will imediately complete if the optional
  /// [SharedPreferences] instance is passed to the constructor.
  Future<bool> get ready => notifier!.ready;

  /// Sets a persistent record given a `key` and `value`.
  ///
  /// If a default value is available for the given key, checks that the value
  /// type and the default type are the same, and throws an exception otherwise.
  /// This ensures that any key will always correspond to the same type, as
  /// specified in `defaultValues`.
  void set(String key, dynamic value) {
    final contextKey = '$prefix:$key';
    // Check if the value has an acceptable type
    if (!(value is String ||
        value is int ||
        value is double ||
        value is bool ||
        value == null)) {
      throw Exception("Invalid value type '${value.runtimeType}'. "
          "Only 'String', 'int', 'double' and 'bool' are allowed, "
          "or 'Null' to unset.");
    }

    // Check type consistency with defaults
    if (defaultValues.containsKey(contextKey) &&
        defaultValues[contextKey].runtimeType != value.runtimeType) {
      throw Exception("The shared preferences value '$contextKey' "
          "cannot be set to a value of type '{$value.runtimeType}', "
          "as its default value has type "
          "'${defaultValues[contextKey].runtimeType}'.");
    }

    // Update value notifier
    final newValue = Map<String, dynamic>.from(notifier!.value);
    newValue[contextKey] = value;
    notifier!.value = newValue;
  }
}

/// A [ValueNotifier] that holds the current value of the shared preferences
/// and handles its asynchronous reading and writing.
class PersistentContextNotifier extends ValueNotifier<Map<String, dynamic>> {
  final Future<SharedPreferences> _prefsFuture;
  final Completer<bool> readyCompleter = Completer();

  Future<bool> get ready => readyCompleter.future;

  PersistentContextNotifier()
      : _prefsFuture = SharedPreferences.getInstance(),
        super({}) {
    _prefsFuture.then((prefs) {
      final newValue = extractPreferencesMap(prefs);

      value = newValue;
      readyCompleter.complete(true);
    });
  }

  PersistentContextNotifier.preloaded(SharedPreferences sharedPreferences)
      : _prefsFuture = Future.value(sharedPreferences),
        super(extractPreferencesMap(sharedPreferences)) {
    readyCompleter.complete(true);
  }

  static Map<String, dynamic> extractPreferencesMap(SharedPreferences prefs) {
    return Map.fromEntries(
      prefs.getKeys().map(
            (e) => MapEntry(e, prefs.get(e)),
          ),
    );
  }

  // Override the value setter to provide transparent consolidation of the
  // persistent records
  @override
  set value(Map<String, dynamic> value) {
    super.value = value;

    // Update the preferences
    _prefsFuture.then((prefs) {
      value.forEach((key, value) {
        if (value is int) {
          prefs.setInt(key, value);
        } else if (value is bool) {
          prefs.setBool(key, value);
        } else if (value is String) {
          prefs.setString(key, value);
        } else if (value is double) {
          prefs.setDouble(key, value);
        }
      });
    });
  }
}
