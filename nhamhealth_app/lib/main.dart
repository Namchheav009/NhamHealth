import 'package:flutter/material.dart';

import 'models/api_health.dart';
import 'services/api_service.dart';
import 'services/health_api.dart';

void main() {
  runApp(const NhamHealthApp());
}

class NhamHealthApp extends StatelessWidget {
  const NhamHealthApp({super.key, this.api});

  final HealthApi? api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NhamHealth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF147D64),
        ),
        useMaterial3: true,
      ),
      home: ApiConnectionPage(api: api ?? ApiService()),
    );
  }
}

class ApiConnectionPage extends StatefulWidget {
  const ApiConnectionPage({super.key, required this.api});

  final HealthApi api;

  @override
  State<ApiConnectionPage> createState() => _ApiConnectionPageState();
}

class _ApiConnectionPageState extends State<ApiConnectionPage> {
  ApiHealth? _health;
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHealth();
  }

  Future<void> _loadHealth() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final health = await widget.api.getHealth();
      if (!mounted) return;
      setState(() => _health = health);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _health = null;
        _error = error;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NhamHealth')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _error == null ? Icons.cloud_done : Icons.cloud_off,
                      size: 56,
                      color: _error == null
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isLoading
                          ? 'Connecting to Spring API…'
                          : _error == null
                              ? 'Connected to Spring API'
                              : 'Could not reach Spring API',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else if (_health case final health?)
                      _ConnectionDetails(
                        health: health,
                        baseUrl: widget.api.baseUrl,
                      )
                    else
                      _ConnectionError(
                        error: _error,
                        baseUrl: widget.api.baseUrl,
                      ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _loadHealth,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Test again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionDetails extends StatelessWidget {
  const _ConnectionDetails({required this.health, required this.baseUrl});

  final ApiHealth health;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Status: ${health.status}'),
        Text('Service: ${health.service}'),
        const SizedBox(height: 8),
        SelectableText(baseUrl, textAlign: TextAlign.center),
      ],
    );
  }
}

class _ConnectionError extends StatelessWidget {
  const _ConnectionError({required this.error, required this.baseUrl});

  final Object? error;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          error.toString(),
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 8),
        Text(
          'Start Spring Boot and check this URL:',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SelectableText(baseUrl, textAlign: TextAlign.center),
      ],
    );
  }
}
