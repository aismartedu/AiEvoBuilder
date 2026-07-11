import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'services/api_service.dart';

void main() {
  runApp(const AiEvoBuilderApp());
}

class AiEvoBuilderApp extends StatelessWidget {
  const AiEvoBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Evo Builder',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

// ================= DASHBOARD =================
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Evo Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Prompts & Apps',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kelola, uji, dan kembangkan aplikasi Anda.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Buat Aplikasi Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B5EFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text('Pembaruan otomatis aktif'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Cari prompt atau deskripsi...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Card(
                    color: const Color(0xFF1E1E1E),
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.smartphone, color: Colors.white),
                      ),
                      title: const Text('Live Weather Widget'),
                      subtitle: const Text('A gorgeous weather forecasting dashboard'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_circle_fill, color: Color(0xFF4B5EFF)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WorkspaceScreen(projectName: 'Live Weather Widget'),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= WORKSPACE (CHAT + PREVIEW) =================
class WorkspaceScreen extends StatefulWidget {
  final String projectName;
  const WorkspaceScreen({super.key, required this.projectName});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  int _currentTab = 0;
  String _previewHtml = '<h3>Preview akan muncul di sini</h3>';
  final TextEditingController _controller = TextEditingController();

  void _sendMessage(String prompt) async {
    if (prompt.isEmpty) return;
    try {
      // Ganti "TOKEN_ANDA" dengan token JWT asli dari login (misal disimpan di storage)
      final response = await ApiService.chat(prompt, "TOKEN_ANDA");
      setState(() {
        _previewHtml = response['ui_preview_html'] ?? '<h3>Preview tidak tersedia</h3>';
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: () {}),
          IconButton(icon: const Icon(Icons.archive), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: _currentTab == 0
                            ? const Border(bottom: BorderSide(color: Colors.blue, width: 2))
                            : null,
                      ),
                      child: const Center(child: Text('Chat', style: TextStyle(color: Colors.white))),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: _currentTab == 1
                            ? const Border(bottom: BorderSide(color: Colors.blue, width: 2))
                            : null,
                      ),
                      child: const Center(child: Text('Preview', style: TextStyle(color: Colors.white))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _currentTab == 0
                ? _buildChatPanel()
                : _buildPreviewPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  title: Text('AI: Aplikasi berhasil dibuat!'),
                  subtitle: Text('Silakan lihat di tab Preview'),
                ),
              ],
            ),
          ),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Ubah, hapus, atau tambah fitur...',
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _sendMessage(_controller.text),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadHtmlString(_previewHtml),
      ),
    );
  }
}
