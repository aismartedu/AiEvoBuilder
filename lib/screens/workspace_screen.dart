import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

const String baseUrl = "https://app.aismartedu.my.id";
const storage = FlutterSecureStorage();

class WorkspaceScreen extends StatefulWidget {
  final int projectId;
  final String projectName;
  const WorkspaceScreen({super.key, required this.projectId, required this.projectName});
  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  int _currentTab = 0;
  String _previewHtml = '<h3>Preview akan muncul di sini</h3>';
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_previewHtml);
  }

  Future<void> _saveProject() async {
    await storage.write(key: 'project_${widget.projectId}', value: jsonEncode({
      'messages': _messages,
      'preview': _previewHtml,
    }));
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('💾 Proyek tersimpan!')));
  }

  Future<void> _exportZip() async {
    try {
      final archive = Archive();
      final content = utf8.encode('// Placeholder code');
      archive.addFile(ArchiveFile('lib/main.dart', content.length, content));
      
      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}/${widget.projectName}.zip';
      final outputStream = File(zipPath).openWrite();
      final encoder = ZipEncoder();
      
      outputStream.add(encoder.encode(archive)!);
      await outputStream.close();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('📦 ZIP berhasil dibuat di: $zipPath')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Gagal ekspor: $e')));
    }
  }

  Future<void> _sendMessage(String prompt) async {
    if (prompt.isEmpty) return;
    setState(() {
      _isLoading = true;
      _messages.add({'role': 'user', 'content': prompt});
    });
    _controller.clear();

    // Memastikan token dan userId tidak null dengan ?? ''
    final String token = await storage.read(key: 'auth_token') ?? '';
    final String userId = await storage.read(key: 'user_id') ?? '';

    try {
      final List<Map<String, String>> history = _messages.map((m) => {
        'role': m['role'] ?? '', 
        'content': m['content'] ?? ''
      }).toList();
      
      final Map<String, dynamic> payload = {
        "user_id": userId,
        "messages": history,
        "target_platform": "flutter"
      };
      
      final response = await _httpPost(payload, token);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String resultMessage = "✅ Aplikasi berhasil dibuat!\n\n";
        setState(() {
          _previewHtml = data['ui_preview_html'] ?? '<h3>Preview tidak tersedia</h3>';
          _messages.removeWhere((m) => m['role'] == 'ai');
          _messages.add({'role': 'ai', 'content': resultMessage});
          _webViewController.loadHtmlString(_previewHtml);
        });
      } else {
        setState(() {
          _messages.add({'role': 'ai', 'content': '❌ Error: ${response.statusCode}'});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'content': '❌ Koneksi error: $e'});
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<http.Response> _httpPost(Map<String, dynamic> payload, String token) async {
    final url = Uri.parse('$baseUrl/v1/chat/completions');
    final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
    final body = jsonEncode(payload);
    return await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 45));
  }

  void _refreshPreview() {
    _webViewController.loadHtmlString(_previewHtml);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveProject),
          IconButton(icon: const Icon(Icons.archive), onPressed: _exportZip),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshPreview),
        ],
      ),
      body: Column(children: [
        Container(color: Colors.grey[900], child: Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => setState(() => _currentTab = 0),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(border: _currentTab == 0 ? const Border(bottom: BorderSide(color: Colors.blue, width: 2)) : null), child: const Center(child: Text('Chat', style: TextStyle(color: Colors.white))))),
          ),
          Expanded(child: GestureDetector(
            onTap: () => setState(() => _currentTab = 1),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(border: _currentTab == 1 ? const Border(bottom: BorderSide(color: Colors.blue, width: 2)) : null), child: const Center(child: Text('Preview', style: TextStyle(color: Colors.white))))),
          ),
        ])),
        Expanded(child: _currentTab == 0 ? _buildChatPanel() : _buildPreviewPanel()),
      ]),
    );
  }

  Widget _buildChatPanel() {
    return Padding(padding: const EdgeInsets.all(16.0),
      child: Column(children: [
        Expanded(child: ListView.builder(
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final msg = _messages[index];
            final isUser = msg['role'] == 'user';
            return Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4), 
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUser ? Colors.blue[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Text(
                  msg['content'] ?? "",
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            );
          },
        )),
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0, top: 8.0),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Ubah, hapus, atau tambah fitur...',
              filled: true, 
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              suffixIcon: _isLoading 
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SpinKitFadingCircle(color: Colors.white, size: 24.0),
                  )
                : IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildPreviewPanel() {
    return Container(
      margin: const EdgeInsets.all(16), 
      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
      child: WebViewWidget(controller: _webViewController),
    );
  }
}
