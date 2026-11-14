import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_chain_report.dart';
import 'package:torn_pda/models/chat/chat_past_chains.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chat/chat_chain_report_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

Future<void> openPastChains(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PastChainsPage()));

AppBar _appBar(String title, {List<Widget> actions = const []}) => AppBar(
  iconTheme: const IconThemeData(color: Colors.white),
  elevation: 2,
  title: Text(title, style: const TextStyle(color: Colors.white)),
  actions: actions,
);

class _Problem extends StatelessWidget {
  const _Problem({required this.title, this.detail, required this.onRetry});

  final String title;
  final String? detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class PastChainsPage extends StatefulWidget {
  const PastChainsPage({super.key});

  @override
  State<PastChainsPage> createState() => _PastChainsPageState();
}

class _PastChainsPageState extends State<PastChainsPage> {
  final _chains = NativeChat.pastChains;

  @override
  void initState() {
    super.initState();
    unawaited(_chains.refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.read<ThemeProvider>().canvas,
      appBar: _appBar(
        'Past chains',
        actions: [
          ListenableBuilder(
            listenable: _chains,
            builder: (context, _) => IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _chains.loading ? null : _chains.refresh,
            ),
          ),
        ],
      ),
      body: ChatTheme(
        touch: false,
        child: SafeArea(
          child: ListenableBuilder(listenable: _chains, builder: (context, _) => _body(context)),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final chains = _chains.chains;
    final problem = _chains.problem;
    if (chains.isEmpty) {
      if (_chains.loading) {
        return const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading past chains'));
      }
      if (problem != null) {
        return Center(
          child: _Problem(title: problem, detail: _chains.problemDetail, onRetry: _chains.refresh),
        );
      }
      return const Center(child: Text('No finished chains yet'));
    }
    return ListView(
      children: [
        if (problem != null) _Problem(title: problem, detail: _chains.problemDetail, onRetry: _chains.refresh),
        for (final chain in chains) _ChainRow(chain: chain),
        if (_chains.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _chains.loadingMore
                  ? const CircularProgressIndicator(semanticsLabel: 'Loading more chains')
                  : OutlinedButton(onPressed: _chains.loadMore, child: const Text('Load more')),
            ),
          ),
      ],
    );
  }
}

class _ChainRow extends StatelessWidget {
  const _ChainRow({required this.chain});

  final ChatPastChain chain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PastChainReportPage(chain: chain))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatPastChainHits(chain),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(chatPastChainWhen(chain), style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${chatRespect(chain.respect)} respect',
              style: theme.textTheme.bodyMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    );
  }
}

class PastChainReportPage extends StatefulWidget {
  const PastChainReportPage({super.key, required this.chain});

  final ChatPastChain chain;

  @override
  State<PastChainReportPage> createState() => _PastChainReportPageState();
}

class _PastChainReportPageState extends State<PastChainReportPage> {
  late Future<ChatChainReport?> _report = NativeChat.pastChains.report(widget.chain.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.read<ThemeProvider>().canvas,
      appBar: _appBar('Chain report'),
      body: ChatTheme(
        touch: false,
        child: SafeArea(
          child: FutureBuilder<ChatChainReport?>(
            future: _report,
            initialData: NativeChat.pastChains.cachedReport(widget.chain.id),
            builder: (context, snapshot) {
              final report = snapshot.data;
              if (report != null) return SingleChildScrollView(child: ChatChainReportBody(report: report));
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading chain report'));
              }
              return Center(
                child: _Problem(
                  title: "Couldn't load the report",
                  detail: 'Check your connection and try again',
                  onRetry: () => setState(() => _report = NativeChat.pastChains.report(widget.chain.id)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
