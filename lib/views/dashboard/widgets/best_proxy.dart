import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widget_metrics.dart';

class BestProxy extends ConsumerStatefulWidget {
  const BestProxy({super.key});

  @override
  ConsumerState<BestProxy> createState() => _BestProxyState();
}

class _BestProxyState extends ConsumerState<BestProxy> {
  bool _running = false;

  List<Group> _lines(List<Group> groups) {
    final top = groups.getGroup(builtInGroupName);
    final lines = <Group>[];
    for (final member in top?.all ?? const <Proxy>[]) {
      final group = groups.getGroup(member.name);
      if (group != null && group.all.isNotEmpty) {
        lines.add(group);
      }
    }
    return lines;
  }

  Future<void> _handle() async {
    if (_running) {
      return;
    }
    final lines = _lines(ref.read(visibleGroupsStateProvider).value);
    if (lines.isEmpty) {
      return;
    }
    setState(() => _running = true);
    try {
      if (!ref.read(isStartProvider)) {
        ref.read(commonActionProvider.notifier).toggleRunning();
      }
      final action = ref.read(proxiesActionProvider.notifier);
      await action.delayTest([for (final line in lines) ...line.all]);
      if (!mounted) {
        return;
      }
      final delayMap = ref.read(delayDataSourceProvider);
      String? bestLine;
      var bestDelay = -1;
      for (final line in lines) {
        final delays = delayMap[ref.read(realTestUrlProvider(line.testUrl))];
        if (delays == null) {
          continue;
        }
        for (final proxy in line.all) {
          final delay = delays[proxy.name];
          if (delay == null || delay <= 0) {
            continue;
          }
          if (bestDelay == -1 || delay < bestDelay) {
            bestDelay = delay;
            bestLine = line.name;
          }
        }
      }
      if (bestLine != null) {
        await action.changeProxy(
          groupName: builtInGroupName,
          proxyName: bestLine,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(visibleGroupsStateProvider).value;
    final current = groups.getGroup(builtInGroupName)?.now ?? '';
    final inset = DashboardWidgetMetrics.insetOf(context);
    return SizedBox(
      height: DashboardWidgetMetrics.heightOf(context, 1),
      child: CommonCard(
        radius: DashboardWidgetMetrics.radiusOf(context),
        infoPadding: DashboardWidgetMetrics.paddingOf(
          context,
        ).copyWith(bottom: 0),
        onPressed: _handle,
        info: Info(
          label: context.appLocalizations.bestProxy,
          glyph: AppGlyphs.bolt,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            inset,
            0,
            inset,
            DashboardWidgetMetrics.verticalInsetOf(context),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  current.isEmpty
                      ? context.appLocalizations.start
                      : current,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.adjustSize(-2).toLight,
                ),
              ),
              if (_running)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const GlyphIcon(AppGlyphs.bolt, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
