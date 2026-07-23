import 'package:flutter/material.dart';

<<<<<<< HEAD
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
=======
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
>>>>>>> 304f44ac267fdc5fbf67c1fa9366cff48e153fd7
    );
  }
}

<<<<<<< HEAD
class ApiConnectionPage extends StatefulWidget {
  const ApiConnectionPage({super.key, required api});

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
      if (mounted) setState(() => _isLoading = false);
    }
=======
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
>>>>>>> 304f44ac267fdc5fbf67c1fa9366cff48e153fd7
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
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
                          health: health, baseUrl: widget.api.baseUrl)
                    else
                      _ConnectionError(
                          error: _error, baseUrl: widget.api.baseUrl),
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
=======
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
>>>>>>> 304f44ac267fdc5fbf67c1fa9366cff48e153fd7
    );
  }
}
