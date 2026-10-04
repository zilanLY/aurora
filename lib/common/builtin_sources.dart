class BuiltInSource {
  const BuiltInSource(this.label, this.url);

  final String label;
  final String url;
}

const builtInGroupName = '极光线路';
const builtInAutoGroupName = '自动选择';

const _staticSources = <BuiltInSource>[
  BuiltInSource(
    'v2rayfree',
    'https://raw.githubusercontent.com/free-nodes/v2rayfree/main/sub',
  ),
  BuiltInSource(
    'pawdroid',
    'https://raw.githubusercontent.com/Pawdroid/Free-servers/main/sub',
  ),
  BuiltInSource(
    'shaoyou',
    'https://raw.githubusercontent.com/shaoyouvip/free/main/base64.txt',
  ),
  BuiltInSource(
    'clashfree',
    'https://raw.githubusercontent.com/free-nodes/clashfree/main/sub.yml',
  ),
];

/// 内置订阅源。v2rayfree/pawdroid/shaoyou 为固定 base64 地址，由 mihomo
/// provider 自动转换并每日更新；clashfree 与米贝的每日文件带日期，因此额外
/// 回退到最近几天，缺失的日期只会让该 provider 为空，不影响整份配置。
List<BuiltInSource> builtInSources([DateTime? now]) {
  final base = (now ?? DateTime.now()).toUtc().add(const Duration(hours: 8));
  final sources = <BuiltInSource>[..._staticSources];
  for (var back = 0; back < 4; back++) {
    final day = base.subtract(Duration(days: back));
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    sources
      ..add(
        BuiltInSource(
          'clashfree_$back',
          'https://raw.githubusercontent.com/free-nodes/clashfree/main/'
              'clash$y$m$d.yml',
        ),
      )
      ..add(
        BuiltInSource(
          'mibei_$back',
          'https://node.mibeifenxiang.com/uploads/$y/$m/$y$m$d.txt',
        ),
      );
  }
  return sources;
}

String buildBuiltInProfile([DateTime? now]) {
  final sources = builtInSources(now);
  final buffer = StringBuffer()
    ..writeln('mixed-port: 7890')
    ..writeln('allow-lan: false')
    ..writeln('mode: rule')
    ..writeln('log-level: info')
    ..writeln('proxies: []')
    ..writeln('proxy-providers:');
  for (final source in sources) {
    buffer
      ..writeln('  ${source.label}:')
      ..writeln('    type: http')
      ..writeln('    url: ${source.url}')
      ..writeln('    path: ./providers/${source.label}.yaml')
      ..writeln('    interval: 86400');
  }
  final use = sources.map((source) => '      - ${source.label}').join('\n');
  buffer
    ..writeln('proxy-groups:')
    ..writeln('  - name: $builtInGroupName')
    ..writeln('    type: select')
    ..writeln('    use:')
    ..writeln(use)
    ..writeln('    proxies:')
    ..writeln('      - DIRECT')
    ..writeln('  - name: $builtInAutoGroupName')
    ..writeln('    type: url-test')
    ..writeln('    use:')
    ..writeln(use)
    ..writeln('    url: https://www.gstatic.com/generate_204')
    ..writeln('    interval: 300')
    ..writeln('rules:')
    ..writeln('  - GEOIP,CN,DIRECT')
    ..writeln('  - MATCH,$builtInGroupName');
  return buffer.toString();
}
