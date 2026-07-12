import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = const FlutterSecureStorage();

class SyncGitHubScreen extends StatefulWidget {
  const SyncGitHubScreen({super.key});
  @override
  State<SyncGitHubScreen> createState() => _SyncGitHubScreenState();
}

class _SyncGitHubScreenState extends State<SyncGitHubScreen> {
  List<String> _pendingFiles = ['lib/main.dart', 'pubspec.yaml', 'android/app/build.gradle'];
  bool _isLoading = false;

  Future<void> _syncToGitHub() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
      _pendingFiles.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Berhasil push ke GitHub!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync ke GitHub')),
      body: Padding(padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('File yang akan dipush:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(child: _pendingFiles.isEmpty 
            ? const Center(child: Text('Tidak ada file yang perlu dipush', style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                itemCount: _pendingFiles.length,
                itemBuilder: (context, index) {
                  return Card(color: const Color(0xFF1E1E1E), margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.description, color: Colors.white),
                      title: Text(_pendingFiles[index]),
                      trailing: const Icon(Icons.check_circle, color: Colors.green),
                    ),
                  );
                },
              )),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _pendingFiles.isEmpty || _isLoading ? null : _syncToGitHub,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: _isLoading ? const CircularProgressIndicator() : const Text('Push ke GitHub'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                // Buka GitHub Actions di browser
              },
              child: const Text('Lihat Proses Build di GitHub Actions'),
            ),
          ),
        ]),
      ),
    );
  }
}
