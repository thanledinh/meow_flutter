import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # 1. Navigator.pushNamed(context, '/foo') -> context.push('/foo')
    content = re.sub(r"Navigator\.pushNamed\(\s*context\s*,\s*'([^']+)'\s*\)", r"context.push('\1')", content)
    
    # 2. Navigator.pushNamed(context, '/foo', arguments: args) -> context.push('/foo', extra: args)
    content = re.sub(r"Navigator\.pushNamed\(\s*context\s*,\s*'([^']+)'\s*,\s*arguments:\s*(.+?)\s*\)", r"context.push('\1', extra: \2)", content)

    # 3. Navigator.pop(context) -> context.pop()
    content = re.sub(r"Navigator\.pop\(\s*context\s*\)", r"context.pop()", content)

    # 4. Navigator.pushNamedAndRemoveUntil(context, '/foo', (_) => false) -> context.go('/foo')
    content = re.sub(r"Navigator\.pushNamedAndRemoveUntil\(\s*context\s*,\s*'([^']+)'\s*,\s*\([^\)]+\)\s*=>\s*false\s*\)", r"context.go('\1')", content)
    content = re.sub(r"Navigator\.pushNamedAndRemoveUntil\(\s*context\s*,\s*'([^']+)'\s*,\s*_\s*=>\s*false\s*\)", r"context.go('\1')", content)

    # 5. Navigator.pushReplacementNamed(context, '/foo') -> context.replace('/foo')
    content = re.sub(r"Navigator\.pushReplacementNamed\(\s*context\s*,\s*'([^']+)'\s*\)", r"context.replace('\1')", content)

    if content != original:
        if "import 'package:go_router/go_router.dart';" not in content:
            content = re.sub(r"(import\s+[^;]+;)", r"\1\nimport 'package:go_router/go_router.dart';", content, count=1)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Updated {filepath}')

for root, _, files in os.walk('lib/'):
    for f in files:
        if f.endswith('.dart') and 'router.dart' not in f and 'replace_nav.py' not in f:
            filepath = os.path.join(root, f)
            try:
                process_file(filepath)
            except Exception as e:
                print(f'Error on {filepath}: {e}')
