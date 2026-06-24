import 'dart:io';

void main() {
  final dir = Directory('C:/xampp/htdocs/SON/FLUTTER/rotarehber_app/lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (var file in files) {
    String content = file.readAsStringSync();
    if (content.contains("Localizations.localeOf(context).languageCode == 'en'")) {
      content = content.replaceAll(
          "Localizations.localeOf(context).languageCode == 'en'",
          "context.watch<LanguageProvider>().isEn");

      if (!content.contains("import 'package:provider/provider.dart';")) {
        content = "import 'package:provider/provider.dart';\n" + content;
      }
      
      // Calculate relative path to lib/providers/language_provider.dart
      String relativePath = '';
      final pathParts = file.path.replaceAll(r'\', '/').split('/lib/');
      if (pathParts.length > 1) {
        final subDirParts = pathParts[1].split('/');
        final depth = subDirParts.length - 1;
        if (depth == 0) {
          relativePath = 'providers/language_provider.dart';
        } else {
          relativePath = ('../' * depth) + 'providers/language_provider.dart';
        }
      }
      
      if (!content.contains("/language_provider.dart")) {
        content = "import '$relativePath';\n" + content;
      }

      file.writeAsStringSync(content);
      print("Updated ${file.path}");
    }
  }
}
