import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AiEvoBuilderApp());
}

const String baseUrl = "https://app.aismartedu.my.id";
final storage = const FlutterSecureStorage();

class AiEvoBuilderApp extends StatelessWidget {
  const AiEvoBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Evo Builder',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E), foregroundColor: Colors.white),
      ),
      home: const AuthWrapper(),
    );
  }
}

// ================= AUTH WRAPPER =================
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false, _isLoading = true;
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }
  Future<void> _checkLoginStatus() async {
    final token = await storage.read(key: 'auth_token');
    setState(() { _isLoggedIn = token != null; _isLoading = false; });
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return _isLoggedIn ? const DashboardScreen() : const LoginScreen();
  }
}

// ================= LOGIN SCREEN =================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim(), 'password': _passwordController.text.trim()}),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'auth_token', value: data['access_token']);
        await storage.write(key: 'user_id', value: data['user_id'].toString());
        await storage.write(key: 'user_name', value: data['full_name']);
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      } else {
        final err = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err['detail'] ?? 'Login gagal')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Koneksi error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 20),
          TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _login, child: _isLoading ? const CircularProgressIndicator() : const Text('Login'))),
          TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('Belum punya akun? Daftar')),
          TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())), child: const Text('Lupa Password?')),
        ]),
      ),
    );
  }
}

// ================= REGISTER SCREEN =================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'), headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'full_name': _nameController.text.trim(), 'email': _emailController.text.trim(), 'password': _passwordController.text.trim()}),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registrasi berhasil, silakan login')));
        Navigator.pop(context);
      } else {
        final err = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err['detail'] ?? 'Registrasi gagal')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Koneksi error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Daftar Akun Baru')),
      body: Padding(padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
          const SizedBox(height: 20),
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 20),
          TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _register, child: _isLoading ? const CircularProgressIndicator() : const Text('Daftar'))),
        ]),
      ),
    );
  }
}

// ================= FORGOT PASSWORD SCREEN =================
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(Uri.parse('$baseUrl/auth/forgot-password'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': _emailController.text.trim()})).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email reset telah dikirim')));
        Navigator.pop(context);
      } else {
        final err = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err['detail'] ?? 'Gagal mengirim email')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Koneksi error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Lupa Password')),
      body: Padding(padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Masukkan email Anda untuk menerima link reset.'),
          const SizedBox(height: 20),
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _resetPassword, child: _isLoading ? const CircularProgressIndicator() : const Text('Kirim Email Reset'))),
        ]),
      ),
    );
  }
}

// ================= DASHBOARD =================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = 'User';
  List<Map<String, dynamic>> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadProjects();
  }

  Future<void> _loadUser() async {
    final name = await storage.read(key: 'user_name') ?? 'User';
    setState(() => _userName = name);
  }

  Future<void> _loadProjects() async {
    // Simulasi load data (di masa depan akan ambil dari VM)
    setState(() {
      _projects = [
        {'id': 1, 'name': 'Live Weather Widget', 'desc': 'A gorgeous weather forecasting dashboard'},
        {'id': 2, 'name': 'Browser Startpage', 'desc': 'Startpage with Google and GitHub links'},
      ];
    });
  }

  void _addNewProject() {
    setState(() {
      _projects.add({
        'id': Random().nextInt(1000),
        'name': 'New App ${_projects.length + 1}',
        'desc': 'A new AI-powered app'
      });
    });
  }

  void _deleteProject(int id) {
    setState(() {
      _projects.removeWhere((p) => p['id'] == id);
    });
  }

  Future<void> _logout() async {
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'user_name');
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthWrapper()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Evo Builder'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(child: Text('U')), const SizedBox(width: 12),
            Text('Halo, $_userName', style: const TextStyle(fontSize: 18))
          ]),
          const SizedBox(height: 24),
          const Text('My Prompts & Apps', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Kelola, uji, dan kembangkan aplikasi Anda.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Row(children: [
            ElevatedButton.icon(onPressed: _addNewProject, icon: const Icon(Icons.add), label: const Text('Buat Aplikasi Baru'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B5EFF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16))),
            const SizedBox(width: 16),
            ElevatedButton.icon(onPressed: _loadProjects, icon: const Icon(Icons.refresh), label: const Text('Refresh'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C2C2C), foregroundColor: Colors.white)),
          ]),
          const SizedBox(height: 24),
          const TextField(decoration: InputDecoration(hintText: 'Cari prompt atau deskripsi...', prefixIcon: Icon(Icons.search), filled: true, fillColor: Color(0xFF1E1E1E), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none))),
          const SizedBox(height: 24),
          Expanded(child: ListView.builder(
            itemCount: _projects.length,
            itemBuilder: (context, index) {
              final p = _projects[index];
              return Card(color: const Color(0xFF1E1E1E), elevation: 0, margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.smartphone, color: Colors.white)),
                  title: Text(p['name']),
                  subtitle: Text(p['desc']),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.play_circle_fill, color: Color(0xFF4B5EFF)), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => WorkspaceScreen(projectId: p['id'], projectName: p['name'])))),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProject(p['id'])),
                  ]),
                ),
              );
            },
          )),
        ]),
      ),
    );
  }
}

// ================= SETTINGS SCREEN =================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _tokenController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  Future<void> _loadSettings() async {
    final token = await storage.read(key: 'github_token');
    setState(() { _tokenController.text = token ?? ''; });
  }
  Future<void> _saveSettings() async {
    await storage.write(key: 'github_token', value: _tokenController.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Pengaturan tersimpan!')));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Settings')),
      body: Padding(padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Text('Konfigurasi koneksi dan integrasi Anda.'),
          const SizedBox(height: 20),
          TextField(controller: _tokenController, decoration: const InputDecoration(labelText: 'GitHub Token', border: OutlineInputBorder()), obscureText: true),
          const SizedBox(height: 40),
          ElevatedButton(onPressed: _saveSettings, child: const Text('Simpan Pengaturan')),
        ]),
      ),
    );
  }
}

// ================= WORKSPACE (CHAT + PREVIEW) =================
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
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  Future<void> _sendMessage(String prompt) async {
    if (prompt.isEmpty) return;
    setState(() {
      _isLoading = true;
      _messages.add({'role': 'user', 'content': prompt});
    });
    _controller.clear();

    final token = await storage.read(key: 'auth_token');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({"user_id": await storage.read(key: 'user_id'), "prompt": prompt, "target_platform": "flutter"}),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _previewHtml = data['ui_preview_html'] ?? '<h3>Preview tidak tersedia</h3>';
          _messages.add({'role': 'ai', 'content': '✅ Aplikasi berhasil dibuat!'});
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
            return Align(
              alignment: msg['role'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: msg['role'] == 'user' ? Colors.blue[100] : Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                child: Text(msg['content'] ?? ""),
              ),
            );
          },
        )),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Ubah, hapus, atau tambah fitur...',
            filled: true, fillColor: Colors.grey[900],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            suffixIcon: IconButton(icon: _isLoading ? const CircularProgressIndicator() : const Icon(Icons.send), onPressed: () => _sendMessage(_controller.text)),
          ),
        ),
      ]),
    );
  }

  Widget _buildPreviewPanel() {
    return Container(margin: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
      child: WebViewWidget(controller: WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)..loadHtmlString(_previewHtml)),
    );
  }
}
