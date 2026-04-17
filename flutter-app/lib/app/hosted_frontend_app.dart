import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'theme.dart';

typedef HostedFrontendViewBuilder = Widget Function();

class HostedFrontendApp extends StatelessWidget {
  const HostedFrontendApp({
    required this.initialUrl,
    this.webViewBuilder,
    super.key,
  });

  final String initialUrl;
  final HostedFrontendViewBuilder? webViewBuilder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GravAção',
      debugShowCheckedModeBanner: false,
      theme: buildGravacaoTheme(),
      home: HostedFrontendScreen(
        initialUrl: initialUrl,
        webViewBuilder: webViewBuilder,
      ),
    );
  }
}

class HostedFrontendScreen extends StatefulWidget {
  const HostedFrontendScreen({
    required this.initialUrl,
    this.webViewBuilder,
    super.key,
  });

  final String initialUrl;
  final HostedFrontendViewBuilder? webViewBuilder;

  @override
  State<HostedFrontendScreen> createState() => _HostedFrontendScreenState();
}

class _HostedFrontendScreenState extends State<HostedFrontendScreen> {
  late final Uri _initialUri;
  WebViewController? _controller;
  int _progress = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialUri = Uri.parse(widget.initialUrl);
    if (widget.webViewBuilder == null) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (!mounted) {
                return;
              }
              setState(() {
                _progress = 0;
                _errorMessage = null;
              });
            },
            onProgress: (progress) {
              if (!mounted) {
                return;
              }
              setState(() {
                _progress = progress;
              });
            },
            onPageFinished: (_) {
              if (!mounted) {
                return;
              }
              setState(() {
                _progress = 100;
              });
            },
            onWebResourceError: (error) {
              if (!mounted || !_isMainFrameError(error)) {
                return;
              }
              setState(() {
                _errorMessage = error.description;
              });
            },
          ),
        )
        ..loadRequest(_initialUri);
    } else {
      _progress = 100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final webView =
        widget.webViewBuilder?.call() ??
        WebViewWidget(controller: controller!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GravAção'),
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          webView,
          if (_progress < 100)
            Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(value: _progress / 100),
            ),
          if (_errorMessage != null)
            ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 44,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Não foi possível carregar o frontend hospedado.',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _reload() {
    setState(() {
      _errorMessage = null;
      _progress = 0;
    });
    _controller?.loadRequest(_initialUri);
  }

  bool _isMainFrameError(WebResourceError error) {
    final isMainFrame = error.isForMainFrame ?? true;
    return isMainFrame;
  }
}
