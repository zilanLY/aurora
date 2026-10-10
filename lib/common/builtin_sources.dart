class BuiltInSource {
  const BuiltInSource(this.label, this.url);

  final String label;
  final String url;
}

const builtInGroupName = '极光线路';
const _builtInLineGroupPrefix = '线路';

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

/// 每个内置源按家族拆成带编号的独立选择组，顶层极光线路组只在线路之间切换，
/// 不与具体节点合并；provider 以 exclude-type 按类型剔除 ss 节点，比按名称的
/// exclude-filter 可靠。同家族的每日回退源（clashfree_0、mibei_0 等）并入该组。
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
      ..writeln('    interval: 86400')
      ..writeln('    exclude-type: ss');
  }
  final families = <String, List<String>>{};
  for (final source in sources) {
    final family = source.label.split('_').first;
    families.putIfAbsent(family, () => <String>[]).add(source.label);
  }
  buffer
    ..writeln('proxy-groups:')
    ..writeln('  - name: $builtInGroupName')
    ..writeln('    type: select')
    ..writeln('    proxies:')
    ..writeln('      - DIRECT');
  for (var index = 1; index <= families.length; index++) {
    buffer.writeln('      - $_builtInLineGroupPrefix$index');
  }
  var index = 0;
  for (final entry in families.entries) {
    index++;
    buffer
      ..writeln('  - name: $_builtInLineGroupPrefix$index')
      ..writeln('    type: select')
      ..writeln('    use:');
    for (final label in entry.value) {
      buffer.writeln('      - $label');
    }
  }
  buffer
    ..writeln('rules:')
    ..writeln('  - GEOIP,CN,DIRECT')
    ..writeln('  - MATCH,$builtInGroupName');
  return buffer.toString();
}
