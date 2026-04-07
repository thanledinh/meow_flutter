import 'dart:io';

void main() async {
  final dir = Directory('lib');
  if (!dir.existsSync()) {
    print('lib directory not found');
    return;
  }

  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    String content = await file.readAsString();
    if (content.contains('const ')) {
      // Remove all "const " occurrences (but watch out for const constructors that are required, wait, removing "const " is generally safe because Dart 2 has optional new/const)
      // Actually, be careful not to remove const from static const variables.
      // So we only replace 'const ' if it's before Widget names, like const Text, const Icon, const SizedBox, etc.
      
      final regex = RegExp(r'\bconst\s+(Text|Icon|SizedBox|Padding|Center|CircularProgressIndicator|EmptyState|BoxDecoration|BorderSide|LinearGradient|TextStyle|EdgeInsets|Color|Row|Column|Container|Align|Positioned)\b');
      
      final newContent = content.replaceAllMapped(regex, (match) {
        return match.group(1)!; // Return the word without const
      });
      
      if (content != newContent) {
        await file.writeAsString(newContent);
        print('Updated ${file.path}');
      }
    }
  }
}
