import 'dart:io';

void main() async {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  // Nhan biet tat ca const nam tren cung 1 khoi voi MoewColors (k thay dau =, k thay dau ;)
  final r = RegExp(r'const\s+([^=;]*?MoewColors)');
  
  for (final file in files) {
    String content = await file.readAsString();
    if (content.contains('MoewColors') && content.contains('const')) {
       String newContent = content;
       int len;
       do {
         len = newContent.length;
         newContent = newContent.replaceAllMapped(r, (m) => m.group(1)!);
       } while (newContent.length != len); // Repeat until no more matches
       
       if (content != newContent) {
          await file.writeAsString(newContent);
          print('Fixed ${file.path}');
       }
    }
  }
}
