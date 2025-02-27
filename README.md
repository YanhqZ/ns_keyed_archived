## Features

A Flutter plugin for Apple's Binary Plist and the NSKeyedArchiver/NSKeyedUnarchiver format. 
Inspired by the [bpylist2](https://github.com/parabolala/bpylist2) package.

These types are supported to archive and unarchive back:
* int
* double
* bool
* String
* List
* Map
* Set

## Getting started

Run this command
```bash
 flutter pub add ns_keyed_archived
```
This will add a line like this to your package's pubspec.yaml
```yaml
dependencies:
  ....
  ns_keyed_archiver: ^0.0.2
```

## Usage

```dart
import 'package:ns_keyed_archived/ns_keyed_archived.dart';

void main() {
  final data = {
    'key': 'value',
    'key2': 123,
    'key3': [1, 2, 3],
    'key4': {'key': 'value'}
  };

  // archive the data to a byte array
  final bytes = NSKeyedArchiver.archive(data);
  
  // unarchive the byte array back to the original data
  // 
  // You can use NSKeyedArchiver.unarchive(file.readAsBytesSync()) to unarchive from a file
  final decoded = NSKeyedArchiver.unarchive(bytes);
  
  assert(data == decoded);
}
```

## Additional information

issues: https://github.com/YanhqZ/ns_keyed_archived/issues

Please feel free to open an issue if you have any questions or suggestions.