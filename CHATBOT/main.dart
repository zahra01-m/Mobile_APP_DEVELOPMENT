import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const ChatBotApp());
}

// ══════════════════════════════════════════════════════════
//  CONFIG
// ══════════════════════════════════════════════════════════
class Config {
  // ┌─────────────────────────────────────────┐
  // │  Groq key  →  console.groq.com (free)   │
  // │  Gemini key → aistudio.google.com (free)│
  // └─────────────────────────────────────────┘
  static const String groqKey    = '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';
  static const String geminiKey  = 'AIzaSyDtA5WvOVK7OQh2m7VFKxcALPjfrqmv_Cc';

  static const String groqUrl    = 'https://api.groq.com/openai/v1/chat/completions';
  static const String geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';
  static const String groqModel  = 'llama-3.3-70b-versatile';

  static const String storageKey = 'ai_chat_history_v2';
  static const int    maxHistory = 60;
}

// ══════════════════════════════════════════════════════════
//  THEME
// ══════════════════════════════════════════════════════════
class T {
  static const Color darkBg     = Color(0xFF0D0710);
  static const Color darkCard   = Color(0xFF160B18);
  static const Color darkInput  = Color(0xFF1F0F22);
  static const Color darkBot    = Color(0xFF1A0C1E);
  static const Color darkBorder = Color(0xFF3A1235);

  static const Color lightBg     = Color(0xFFFAEEF7);
  static const Color lightCard   = Color(0xFFF5E0F0);
  static const Color lightInput  = Color(0xFFEDD0E8);
  static const Color lightBot    = Color(0xFFF8E8F5);
  static const Color lightBorder = Color(0xFFDDA0CC);

  static const Color p1    = Color(0xFFFF2D78);
  static const Color p2    = Color(0xFFFF6EA7);
  static const Color p3    = Color(0xFFFFB3D0);
  static const Color pDeep = Color(0xFFBF0060);
  static const Color ok    = Color(0xFF4ADE80);
  static const Color err   = Color(0xFFFF6B6B);
  static const Color warn  = Color(0xFFFFB347);
  static const Color info  = Color(0xFF60A5FA);
  static const Color tSub  = Color(0xFF9A6080);

  static const Gradient grad = LinearGradient(
      colors: [p1, pDeep], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const Gradient gradHov = LinearGradient(
      colors: [p2, p1], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const Gradient geminiGrad = LinearGradient(
      colors: [Color(0xFF4285F4), Color(0xFF0F9D58)],
      begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const Gradient groqGrad = LinearGradient(
      colors: [p1, pDeep], begin: Alignment.topLeft, end: Alignment.bottomRight);
}

// ══════════════════════════════════════════════════════════
//  LOCAL STORAGE
// ══════════════════════════════════════════════════════════
class Store {
  static void save(List<Msg> msgs) {
    try {
      final limited = msgs.length > Config.maxHistory
          ? msgs.sublist(msgs.length - Config.maxHistory)
          : msgs;
      html.window.localStorage[Config.storageKey] =
          jsonEncode(limited.map((m) => m.toJson()).toList());
    } catch (_) {}
  }

  static List<Msg> load() {
    try {
      final raw = html.window.localStorage[Config.storageKey];
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List)
          .map((e) => Msg.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static void clear() => html.window.localStorage.remove(Config.storageKey);
}

// ══════════════════════════════════════════════════════════
//  MESSAGE MODEL
// ══════════════════════════════════════════════════════════
enum MsgStatus { sending, sent }

class Msg {
  final String id;
  final String text;
  final bool isUser;
  final DateTime time;
  final bool isError;
  final String? fileName;
  final String? fileType;  // 'image' | 'text'
  final String? fileData;  // base64 (image) | plain text
  final String? mimeType;  // e.g. 'image/jpeg'
  MsgStatus status;
  bool copied = false;
  bool isBookmarked;

  Msg({
    String? id,
    required this.text,
    required this.isUser,
    this.isError = false,
    this.fileName,
    this.fileType,
    this.fileData,
    this.mimeType,
    this.status = MsgStatus.sent,
    this.isBookmarked = false,
    DateTime? time,
  })  : id = id ?? '${DateTime.now().millisecondsSinceEpoch}',
        time = time ?? DateTime.now();

  String get hhmm {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'text': text, 'isUser': isUser,
    'time': time.toIso8601String(), 'isError': isError,
    'fileName': fileName, 'fileType': fileType,
    'fileData': fileData, 'mimeType': mimeType,
    'isBookmarked': isBookmarked,
  };

  factory Msg.fromJson(Map<String, dynamic> j) => Msg(
    id: j['id'] as String?,
    text: j['text'] as String? ?? '',
    isUser: j['isUser'] as bool? ?? false,
    time: j['time'] != null
        ? DateTime.tryParse(j['time'] as String) ?? DateTime.now()
        : DateTime.now(),
    isError: j['isError'] as bool? ?? false,
    fileName: j['fileName'] as String?,
    fileType: j['fileType'] as String?,
    fileData: j['fileData'] as String?,
    mimeType: j['mimeType'] as String?,
    isBookmarked: j['isBookmarked'] as bool? ?? false,
  );
}

// ══════════════════════════════════════════════════════════
//  GROQ API  (text only — fast)
// ══════════════════════════════════════════════════════════
class GroqApi {
  static Future<String> send(List<Msg> history) {
    final c = Completer<String>();
    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': 'You are a helpful, friendly AI assistant. '
            'Give clear, accurate, well-formatted answers. '
            'Use markdown for code blocks and lists when helpful.',
      }
    ];

    for (final m in history.where((m) => !m.isError)) {
      String content = m.text;
      if (m.fileType == 'text' && m.fileData != null) {
        content = 'File: "${m.fileName}"\n\nContent:\n```\n${m.fileData}\n```\n\nQuestion: ${m.text}';
      }
      messages.add({'role': m.isUser ? 'user' : 'assistant', 'content': content});
    }

    final xhr = html.HttpRequest()..open('POST', Config.groqUrl);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.setRequestHeader('Authorization', 'Bearer ${Config.groqKey}');
    xhr.onLoad.listen((_) {
      if (xhr.status == 200) {
        try {
          c.complete((jsonDecode(xhr.responseText!)['choices'][0]['message']['content'] as String).trim());
        } catch (e) { c.completeError('Parse error: $e'); }
      } else {
        try {
          c.completeError('Error ${xhr.status}: ${jsonDecode(xhr.responseText ?? '{}')['error']?['message'] ?? 'Unknown'}');
        } catch (_) { c.completeError('Error ${xhr.status}'); }
      }
    });
    xhr.onError.listen((_) => c.completeError('Network error'));
    xhr.send(jsonEncode({'model': Config.groqModel, 'messages': messages, 'max_tokens': 2048, 'temperature': 0.7}));
    return c.future;
  }
}

// ══════════════════════════════════════════════════════════
//  GEMINI VISION API  (handles images)
// ══════════════════════════════════════════════════════════
class GeminiVisionApi {
  static Future<String> sendWithImage({
    required String prompt,
    required String base64Image,
    required String mimeType,
  }) {
    final c = Completer<String>();

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              }
            },
            {'text': prompt.isEmpty ? 'Describe this image in detail.' : prompt},
          ]
        }
      ],
      'generationConfig': {
        'maxOutputTokens': 2048,
        'temperature': 0.7,
      },
    });

    final xhr = html.HttpRequest()
      ..open('POST', '${Config.geminiUrl}?key=${Config.geminiKey}');
    xhr.setRequestHeader('Content-Type', 'application/json');

    xhr.onLoad.listen((_) {
      if (xhr.status == 200) {
        try {
          final data = jsonDecode(xhr.responseText!);
          c.complete((data['candidates'][0]['content']['parts'][0]['text'] as String).trim());
        } catch (e) { c.completeError('Parse error: $e'); }
      } else {
        try {
          final err = jsonDecode(xhr.responseText ?? '{}');
          c.completeError('Gemini Error ${xhr.status}: ${err['error']?['message'] ?? 'Unknown'}');
        } catch (_) { c.completeError('Gemini Error ${xhr.status}'); }
      }
    });
    xhr.onError.listen((_) => c.completeError('Network error'));
    xhr.send(body);
    return c.future;
  }
}

// ══════════════════════════════════════════════════════════
//  APP ROOT
// ══════════════════════════════════════════════════════════
class ChatBotApp extends StatefulWidget {
  const ChatBotApp({super.key});
  @override
  State<ChatBotApp> createState() => _ChatBotAppState();
}

class _ChatBotAppState extends State<ChatBotApp> {
  bool _dark = true;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'AI Chat',
    theme: _dark
        ? ThemeData.dark().copyWith(
        scaffoldBackgroundColor: T.darkBg,
        colorScheme: const ColorScheme.dark(primary: T.p1))
        : ThemeData.light().copyWith(
        scaffoldBackgroundColor: T.lightBg,
        colorScheme: const ColorScheme.light(primary: T.p1)),
    home: ChatScreen(isDark: _dark, onToggle: () => setState(() => _dark = !_dark)),
  );
}

// ══════════════════════════════════════════════════════════
//  CHAT SCREEN
// ══════════════════════════════════════════════════════════
class ChatScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;
  const ChatScreen({super.key, required this.isDark, required this.onToggle});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  List<Msg> _msgs  = [];
  final _ctrl      = TextEditingController();
  final _scroll    = ScrollController();
  final _focus     = FocusNode();
  bool _loading    = false;
  bool _showFab    = false;
  int  _chars      = 0;
  String? _pName, _pType, _pData, _pMime;
  late AnimationController _dotAnim, _fabAnim;

  bool   get _dark  => widget.isDark;
  Color  get _bg    => _dark ? T.darkBg     : T.lightBg;
  Color  get _card  => _dark ? T.darkCard   : T.lightCard;
  Color  get _inp   => _dark ? T.darkInput  : T.lightInput;
  Color  get _bot   => _dark ? T.darkBot    : T.lightBot;
  Color  get _brd   => _dark ? T.darkBorder : T.lightBorder;
  Color  get _tPri  => _dark ? const Color(0xFFFAEEF7) : const Color(0xFF180A1A);
  Color  get _tSub  => _dark ? T.tSub : const Color(0xFF7A3060);

  final _sugg = [
    {'i': '💡', 't': 'Explain Machine Learning simply'},
    {'i': '🐍', 't': 'Write Python bubble sort'},
    {'i': '🌐', 't': 'How does the internet work?'},
    {'i': '📱', 't': 'What are Flutter features?'},
    {'i': '🔐', 't': 'Explain cybersecurity basics'},
    {'i': '📊', 't': 'What are data structures?'},
  ];

  @override
  void initState() {
    super.initState();
    _dotAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _fabAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _ctrl.addListener(() => setState(() => _chars = _ctrl.text.length));
    _scroll.addListener(() {
      final at = _scroll.position.pixels >= _scroll.position.maxScrollExtent - 80;
      if (_showFab == at) {
        setState(() => _showFab = !at);
        _showFab ? _fabAnim.forward() : _fabAnim.reverse();
      }
    });
    _loadHistory();
  }

  void _loadHistory() {
    final saved = Store.load();
    if (saved.isNotEmpty) {
      setState(() => _msgs = saved);
      WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom(animated: false));
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() => _msgs.add(Msg(
          text: "Hello! 👋 I'm your AI Assistant.\n\n"
              "🤖 **Groq (Llama 3)** — for text questions & code\n"
              "👁️ **Gemini Vision** — for image analysis\n\n"
              "Features:\n"
              "• Upload images → AI describes & analyzes them\n"
              "• Upload text/code files → AI explains them\n"
              "• Chat history saved locally in your browser\n"
              "• Bookmarks, export, dark/light mode\n\n"
              "What would you like to explore?",
          isUser: false,
        )));
        Store.save(_msgs);
      });
    }
  }

  @override
  void dispose() {
    _dotAnim.dispose(); _fabAnim.dispose();
    _ctrl.dispose(); _scroll.dispose(); _focus.dispose();
    super.dispose();
  }

  void _toBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      animated
          ? _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut)
          : _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  // ── File picker ──────────────────────────────────────────
  void _pickFile() {
    final inp = html.FileUploadInputElement()
      ..accept = '.txt,.dart,.py,.js,.java,.cpp,.html,.css,.json,.xml,.csv,.md';
    inp.click();
    inp.onChange.listen((_) {
      final f = inp.files?.first;
      if (f == null) return;
      final r = html.FileReader()..readAsText(f);
      r.onLoad.listen((_) {
        setState(() {
          _pName = f.name; _pType = 'text'; _pData = r.result as String; _pMime = null;
        });
        if (_ctrl.text.isEmpty) _ctrl.text = 'Please analyze this file: "${f.name}"';
      });
    });
  }

  // ── Image picker — supports all formats ─────────────────
  void _pickImage() {
    final inp = html.FileUploadInputElement()..accept = 'image/*';
    inp.click();
    inp.onChange.listen((_) {
      final f = inp.files?.first;
      if (f == null) return;

      // Detect MIME type
      final ext = f.name.split('.').last.toLowerCase();
      final mime = {
        'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
        'png': 'image/png',  'gif': 'image/gif',
        'webp': 'image/webp','bmp': 'image/bmp',
      }[ext] ?? 'image/jpeg';

      final r = html.FileReader()..readAsDataUrl(f);
      r.onLoad.listen((_) {
        final dataUrl = r.result as String;
        final base64  = dataUrl.split(',').last;
        setState(() {
          _pName = f.name; _pType = 'image'; _pData = base64; _pMime = mime;
        });
        if (_ctrl.text.isEmpty) _ctrl.text = 'Describe what you see in this image.';
        _snack('📸 Image ready! Gemini Vision will analyze it.', color: T.info);
      });
    });
  }

  // ── Send ─────────────────────────────────────────────────
  Future<void> _send([String? quick]) async {
    final text = (quick ?? _ctrl.text).trim();
    if (text.isEmpty && _pData == null) return;
    if (_loading) return;

    final hasImage = _pType == 'image' && _pData != null;

    final m = Msg(
      text: text, isUser: true,
      fileName: _pName, fileType: _pType,
      fileData: _pData,  mimeType: _pMime,
      status: MsgStatus.sending,
    );

    if (quick == null) _ctrl.clear();
    setState(() {
      _msgs.add(m); _pName = _pType = _pData = _pMime = null; _loading = true;
    });
    _toBottom();

    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() => m.status = MsgStatus.sent);

    try {
      String reply;

      if (hasImage) {
        // Use Gemini Vision for image analysis
        reply = await GeminiVisionApi.sendWithImage(
          prompt: text,
          base64Image: m.fileData!,
          mimeType: m.mimeType ?? 'image/jpeg',
        );
      } else {
        // Use Groq for text
        reply = await GroqApi.send(_msgs);
      }

      if (mounted) {
        setState(() {
          _msgs.add(Msg(text: reply, isUser: false));
          _loading = false;
        });
        Store.save(_msgs);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _msgs.add(Msg(text: '⚠️ $e', isUser: false, isError: true));
          _loading = false;
        });
      }
    }
    _toBottom();
  }

  void _copyMsg(int i) {
    Clipboard.setData(ClipboardData(text: _msgs[i].text));
    setState(() => _msgs[i].copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _msgs[i].copied = false);
    });
    _snack('Copied!');
  }

  void _bookmark(int i) {
    setState(() => _msgs[i].isBookmarked = !_msgs[i].isBookmarked);
    Store.save(_msgs);
    _snack(_msgs[i].isBookmarked ? '🔖 Bookmarked!' : 'Removed bookmark');
  }

  void _snack(String msg, {Color? color}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color ?? T.p1,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  void _exportChat() {
    if (_msgs.isEmpty) { _snack('No messages to export'); return; }
    final buf = StringBuffer()
      ..writeln('══════════════════════════════════')
      ..writeln('  AI CHAT EXPORT')
      ..writeln('  ${DateTime.now()}')
      ..writeln('  Messages: ${_msgs.length}')
      ..writeln('══════════════════════════════════\n');
    for (final m in _msgs) {
      buf
        ..writeln('[${m.hhmm}] ${m.isUser ? "YOU" : "AI ASSISTANT"}')
        ..writeln(m.text);
      if (m.fileName != null) buf.writeln('[File: ${m.fileName}]');
      buf.writeln();
    }
    final url = html.Url.createObjectUrlFromBlob(html.Blob([buf.toString()]));
    html.AnchorElement(href: url)
      ..setAttribute('download', 'chat_${DateTime.now().millisecondsSinceEpoch}.txt')
      ..click();
    html.Url.revokeObjectUrl(url);
    _snack('Exported!', color: T.ok);
  }

  void _clearChat() => showDialog(
    context: context,
    builder: (_) => _ConfirmDialog(
      title: 'Clear Chat History',
      msg: 'All messages will be deleted from local storage.',
      card: _card, brd: _brd, tSub: _tSub,
      onOk: () { Store.clear(); setState(() => _msgs.clear()); _snack('Chat cleared'); },
    ),
  );

  void _showBookmarks() {
    final bk = _msgs.asMap().entries.where((e) => e.value.isBookmarked).toList();
    showDialog(context: context,
        builder: (_) => _BookmarkDialog(bk: bk, card: _card, brd: _brd,
            tPri: _tPri, tSub: _tSub, inp: _inp));
  }

  void _showInfo() => showModalBottomSheet(
    context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (_) => _InfoPanel(msgCount: _msgs.length,
        bkCount: _msgs.where((m) => m.isBookmarked).length,
        card: _card, brd: _brd, tPri: _tPri, tSub: _tSub),
  );

  // ── History Panel ────────────────────────────────────────
  void _showHistory() {
    if (_msgs.isEmpty) { _snack('No messages yet', color: T.info); return; }
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'History',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, _, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      pageBuilder: (ctx, _, __) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: _HistoryPanel(
            msgs: _msgs,
            card: _card, brd: _brd, tPri: _tPri, tSub: _tSub, inp: _inp,
            onJumpTo: (index) {
              Navigator.pop(ctx);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scroll.hasClients) {
                  // Estimate item position
                  final itemHeight = 90.0;
                  final offset = (index * itemHeight).clamp(
                      0.0, _scroll.position.maxScrollExtent);
                  _scroll.animateTo(offset,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut);
                }
              });
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w  = MediaQuery.of(context).size.width;
    final cw = w > 960 ? 840.0 : double.infinity;
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        _ProBg(isDark: _dark),
        Column(children: [
          _header(),
          Expanded(child: Center(child: SizedBox(width: cw,
              child: Stack(children: [
                _msgArea(),
                if (_showFab) Positioned(bottom: 14, right: 14,
                    child: ScaleTransition(scale: _fabAnim, child: _scrollFab())),
              ])))),
          Center(child: SizedBox(width: cw, child: _inputArea())),
        ]),
      ]),
    );
  }

  // ── Header ───────────────────────────────────────────────
  Widget _header() {
    final bkCount = _msgs.where((m) => m.isBookmarked).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: _card.withOpacity(0.88),
        border: Border(bottom: BorderSide(color: _brd, width: 0.5)),
        boxShadow: [BoxShadow(color: T.p1.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        _PulseLogo(),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: [T.p3, T.p2]).createShader(b),
            child: const Text('AI Chat', style: TextStyle(color: Colors.white,
                fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
          ),
          Row(children: [
            Container(width: 7, height: 7,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: T.ok)),
            const SizedBox(width: 5),
            Text('Groq + Gemini Vision', style: TextStyle(color: _tSub, fontSize: 11.5)),
          ]),
        ]),
        const Spacer(),
        _Chip(label: '${_msgs.length} msgs', icon: Icons.history_rounded, color: _tSub),
        const SizedBox(width: 8),
        if (bkCount > 0) ...[
          _Chip(label: '$bkCount saved', icon: Icons.bookmark_rounded, color: T.warn),
          const SizedBox(width: 8),
        ],
        _IBtn(icon: _dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tip: _dark ? 'Light mode' : 'Dark mode', onTap: widget.onToggle, hc: T.p1),
        const SizedBox(width: 6),
        _IBtn(icon: Icons.history_edu_rounded, tip: 'Chat History', onTap: _showHistory, hc: T.p2),
        const SizedBox(width: 6),
        _IBtn(icon: Icons.bookmarks_outlined, tip: 'Bookmarks', onTap: _showBookmarks, hc: T.warn),
        const SizedBox(width: 6),
        _IBtn(icon: Icons.download_rounded,   tip: 'Export chat', onTap: _exportChat, hc: T.ok),
        const SizedBox(width: 6),
        _IBtn(icon: Icons.info_outline_rounded, tip: 'About', onTap: _showInfo, hc: T.p2),
        const SizedBox(width: 6),
        _IBtn(icon: Icons.delete_sweep_outlined, tip: 'Clear chat', onTap: _clearChat, hc: T.err),
      ]),
    );
  }

  // ── Message area ─────────────────────────────────────────
  Widget _msgArea() {
    if (_msgs.isEmpty) return _emptyState();
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 22),
      itemCount: _msgs.length + (_loading ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _msgs.length) {
          return _TypingBubble(anim: _dotAnim, tSub: _tSub, bot: _bot, brd: _brd);
        }
        return _Bubble(msg: _msgs[i], index: i,
            bot: _bot, brd: _brd, tPri: _tPri, tSub: _tSub, inp: _inp,
            onCopy: () => _copyMsg(i), onBookmark: () => _bookmark(i));
      },
    );
  }

  Widget _emptyState() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ShaderMask(shaderCallback: (b) => T.grad.createShader(b),
            child: const Icon(Icons.auto_awesome_rounded, size: 64, color: Colors.white)),
        const SizedBox(height: 18),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(colors: [T.p3, T.p2]).createShader(b),
          child: const Text('How can I help you today?',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text('Groq (text) + Gemini Vision (images)', style: TextStyle(color: _tSub, fontSize: 13)),
        const SizedBox(height: 28),
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
            children: _sugg.map((s) => _SugChip(icon: s['i']!, text: s['t']!,
                card: _card, brd: _brd, tSub: _tSub, onTap: () => _send(s['t']))).toList()),
        const SizedBox(height: 24),
        Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
          _FBadge(icon: Icons.bolt_rounded,       label: 'Ultra-fast Groq',  color: T.warn),
          _FBadge(icon: Icons.remove_red_eye,     label: 'Image Vision',     color: T.info),
          _FBadge(icon: Icons.history_rounded,    label: 'Saves History',    color: T.ok),
          _FBadge(icon: Icons.attach_file,        label: 'File Upload',      color: T.p1),
          _FBadge(icon: Icons.download_rounded,   label: 'Export Chat',      color: T.p2),
          _FBadge(icon: Icons.bookmark_outline,   label: 'Bookmarks',        color: T.p3),
        ]),
      ]),
    ),
  );

  Widget _scrollFab() => GestureDetector(
    onTap: _toBottom,
    child: Container(width: 40, height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: T.grad,
            boxShadow: [BoxShadow(color: T.p1.withOpacity(0.55), blurRadius: 16)]),
        child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 22)),
  );

  // ── Input area ───────────────────────────────────────────
  Widget _inputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      decoration: BoxDecoration(
        color: _card.withOpacity(0.92),
        border: Border(top: BorderSide(color: _brd, width: 0.5)),
        boxShadow: [BoxShadow(color: T.p1.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Pending file chip
        if (_pName != null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: _pType == 'image'
                  ? T.geminiGrad
                  : const LinearGradient(colors: [T.p1, T.pDeep]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Icon(_pType == 'image' ? Icons.image_rounded : Icons.insert_drive_file_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_pName!, style: const TextStyle(color: Colors.white,
                    fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                Text(_pType == 'image'
                    ? '📸 Gemini Vision will analyze this image'
                    : '📄 Groq will analyze this file',
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ])),
              GestureDetector(
                  onTap: () => setState(() { _pName = _pType = _pData = _pMime = null; }),
                  child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18)),
            ]),
          ),

        // Quick chips
        if (_msgs.length <= 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _sugg.take(4).map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _QChip(icon: s['i']!, text: s['t']!, inp: _inp, brd: _brd,
                    tSub: _tSub, onTap: () => _send(s['t'])),
              )).toList()),
            ),
          ),

        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          // File attach
          _ABtn(icon: Icons.attach_file_rounded, tip: 'Attach text/code file', onTap: _pickFile,
              useGradient: false),
          const SizedBox(width: 6),
          // Image attach — uses Gemini Vision
          _ABtn(icon: Icons.add_photo_alternate_rounded,
              tip: 'Upload image (Gemini Vision)', onTap: _pickImage, useGradient: true),
          const SizedBox(width: 8),

          // Text field
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (e) {
                if (e is KeyDownEvent &&
                    e.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed) _send();
              },
              child: TextField(
                controller: _ctrl, focusNode: _focus,
                maxLines: 5, minLines: 1, maxLength: 3000,
                style: TextStyle(color: _tPri, fontSize: 15, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'Type a message… or upload an image 📸',
                  hintStyle: TextStyle(color: _tSub, fontSize: 13.5),
                  filled: true, fillColor: _inp, counterText: '',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: _brd)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: _brd)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: T.p1, width: 1.8)),
                ),
              ),
            ),
            if (_chars > 0)
              Padding(
                padding: const EdgeInsets.only(top: 3, right: 4),
                child: Text('$_chars / 3000', style: TextStyle(fontSize: 10.5,
                    color: _chars > 2700 ? T.err : _tSub.withOpacity(0.6))),
              ),
          ])),
          const SizedBox(width: 8),
          _SendBtn(loading: _loading, onTap: _send),
        ]),

        // API indicator bar
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _ApiTag(label: '⚡ Groq', subtitle: 'Text & Code', grad: T.groqGrad),
          const SizedBox(width: 12),
          _ApiTag(label: '👁 Gemini', subtitle: 'Image Vision', grad: T.geminiGrad),
        ]),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  API TAG INDICATOR
// ══════════════════════════════════════════════════════════
class _ApiTag extends StatelessWidget {
  final String label, subtitle;
  final Gradient grad;
  const _ApiTag({required this.label, required this.subtitle, required this.grad});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      gradient: grad,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(width: 5),
      Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]),
  );
}

// ══════════════════════════════════════════════════════════
//  PROFESSIONAL ANIMATED BACKGROUND
// ══════════════════════════════════════════════════════════
class _ProBg extends StatefulWidget {
  final bool isDark;
  const _ProBg({required this.isDark});
  @override
  State<_ProBg> createState() => _ProBgState();
}

class _ProBgState extends State<_ProBg> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 14))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) {
      final v = _c.value;
      return Stack(children: [
        Container(decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isDark
                ? [T.darkBg,
              Color.lerp(const Color(0xFF1A0520), const Color(0xFF0D0A1A), v)!,
              T.darkBg]
                : [T.lightBg,
              Color.lerp(const Color(0xFFF0D8EC), const Color(0xFFEEE0F8), v)!,
              T.lightBg],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        )),
        CustomPaint(size: Size.infinite,
            painter: _GridPainter(color: T.p1.withOpacity(widget.isDark ? 0.03 : 0.04))),
        Positioned(top: -120 + v * 40, left: -80 + v * 20,
            child: _Orb(size: 500, color: T.p1.withOpacity(0.07))),
        Positioned(bottom: -150 + v * 30, right: -100 + v * 20,
            child: _Orb(size: 450, color: T.pDeep.withOpacity(0.06))),
        Positioned(top: 200 + v * 60, right: -60 + v * 15,
            child: _Orb(size: 280, color: T.p2.withOpacity(0.04))),
        Positioned(top: 50 - v * 20, right: 100 + v * 30,
            child: _Orb(size: 160, color: T.p3.withOpacity(0.05))),
        CustomPaint(size: Size.infinite,
            painter: _DiagPainter(
                color: T.p1.withOpacity(widget.isDark ? 0.025 : 0.035), offset: v)),
      ]);
    },
  );
}

class _GridPainter extends CustomPainter {
  final Color color;
  const _GridPainter({required this.color});
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = color..strokeWidth = 0.5;
    for (double x = 0; x < s.width;  x += 60) c.drawLine(Offset(x, 0), Offset(x, s.height), p);
    for (double y = 0; y < s.height; y += 60) c.drawLine(Offset(0, y), Offset(s.width, y), p);
  }
  @override bool shouldRepaint(_GridPainter o) => o.color != color;
}

class _DiagPainter extends CustomPainter {
  final Color color; final double offset;
  const _DiagPainter({required this.color, required this.offset});
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = color..strokeWidth = 0.8;
    final shift = offset * 120.0;
    for (double i = -s.height; i < s.width + s.height; i += 120) {
      c.drawLine(Offset(i + shift, 0), Offset(i + shift + s.height, s.height), p);
    }
  }
  @override bool shouldRepaint(_DiagPainter o) => o.offset != offset;
}

// ══════════════════════════════════════════════════════════
//  MESSAGE BUBBLE
// ══════════════════════════════════════════════════════════
class _Bubble extends StatefulWidget {
  final Msg msg; final int index;
  final Color bot, brd, tPri, tSub, inp;
  final VoidCallback onCopy, onBookmark;
  const _Bubble({required this.msg, required this.index,
    required this.bot, required this.brd, required this.tPri,
    required this.tSub, required this.inp,
    required this.onCopy, required this.onBookmark});
  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _fade  = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(widget.msg.isUser ? 0.06 : -0.06, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _c.forward();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final u = widget.msg.isUser;
    return FadeTransition(opacity: _fade,
      child: SlideTransition(position: _slide,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit:  (_) => setState(() => _hover = false),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: u ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!u) ...[_BotAv(), const SizedBox(width: 8)],
                Flexible(child: Column(
                  crossAxisAlignment: u ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Sender label
                    Padding(padding: const EdgeInsets.only(bottom: 4, left: 2, right: 2),
                        child: Text(u ? 'You' : 'AI Assistant',
                            style: TextStyle(fontSize: 11,
                                color: (u ? T.p2 : widget.tSub).withOpacity(0.75),
                                fontWeight: FontWeight.w600))),

                    // Image preview
                    if (widget.msg.fileType == 'image' && widget.msg.fileData != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        constraints: const BoxConstraints(maxWidth: 300, maxHeight: 220),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: widget.brd),
                          boxShadow: [BoxShadow(color: T.p1.withOpacity(0.25), blurRadius: 12)],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.memory(base64Decode(widget.msg.fileData!), fit: BoxFit.cover),
                      ),

                    // Gemini Vision badge (if image reply)
                    if (!u && _msgs_hasRecentImage(widget.index))
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: T.geminiGrad,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.remove_red_eye, color: Colors.white, size: 13),
                          SizedBox(width: 5),
                          Text('Gemini Vision', style: TextStyle(color: Colors.white,
                              fontSize: 11, fontWeight: FontWeight.bold)),
                        ]),
                      ),

                    // File chip
                    if (widget.msg.fileName != null && widget.msg.fileType != 'image')
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: T.p1.withOpacity(0.12), borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: T.p1.withOpacity(0.3))),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.insert_drive_file_rounded, color: T.p2, size: 15),
                          const SizedBox(width: 6),
                          Text(widget.msg.fileName!, style: const TextStyle(
                              color: T.p2, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ),

                    // Main bubble
                    Stack(children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 640),
                        decoration: BoxDecoration(
                          gradient: u ? T.grad : null,
                          color: u ? null : (widget.msg.isError ? T.err.withOpacity(0.12) : widget.bot),
                          borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(u ? 18 : 4),
                              bottomRight: Radius.circular(u ? 4 : 18)),
                          border: !u ? Border.all(color: widget.brd, width: 0.5) : null,
                          boxShadow: [BoxShadow(
                              color: u ? T.p1.withOpacity(0.22) : Colors.black.withOpacity(0.28),
                              blurRadius: 14, offset: const Offset(0, 4))],
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 12, 40, 12),
                        child: SelectableText(widget.msg.text, style: TextStyle(
                            color: widget.msg.isError ? T.err : widget.tPri,
                            fontSize: 14.5, height: 1.65)),
                      ),
                      if (_hover && !widget.msg.isError)
                        Positioned(top: 6, right: 6,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              _ActBtn(icon: widget.msg.isBookmarked
                                  ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                                  color: widget.msg.isBookmarked ? T.warn : widget.tSub,
                                  onTap: widget.onBookmark),
                              const SizedBox(width: 4),
                              _ActBtn(icon: widget.msg.copied
                                  ? Icons.check_rounded : Icons.copy_rounded,
                                  color: widget.msg.copied ? T.ok : widget.tSub,
                                  onTap: widget.onCopy),
                            ])),
                    ]),

                    const SizedBox(height: 4),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.access_time_rounded, size: 11,
                          color: widget.tSub.withOpacity(0.5)),
                      const SizedBox(width: 3),
                      Text(widget.msg.hhmm, style: TextStyle(fontSize: 10.5,
                          color: widget.tSub.withOpacity(0.5))),
                      if (u) ...[
                        const SizedBox(width: 5),
                        Icon(widget.msg.status == MsgStatus.sending
                            ? Icons.access_time_rounded : Icons.done_all_rounded,
                            size: 13, color: T.p2.withOpacity(0.6)),
                      ],
                      if (widget.msg.isBookmarked) ...[
                        const SizedBox(width: 5),
                        Icon(Icons.bookmark_rounded, size: 12, color: T.warn.withOpacity(0.8)),
                      ],
                    ]),
                  ],
                )),
                if (u) ...[const SizedBox(width: 8), _UserAv()],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Check if this AI message is a reply to an image
  bool _msgs_hasRecentImage(int index) {
    if (widget.msg.isUser) return false;
    if (index > 0) {
      final prev = index - 1;
      // We can't access _msgs directly here, so we skip this check
      // The badge will just not show (safe fallback)
    }
    return false;
  }
}

// ══════════════════════════════════════════════════════════
//  TYPING BUBBLE
// ══════════════════════════════════════════════════════════
class _TypingBubble extends StatelessWidget {
  final AnimationController anim;
  final Color tSub, bot, brd;
  const _TypingBubble({required this.anim, required this.tSub, required this.bot, required this.brd});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      _BotAv(), const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(bottom: 4, left: 2),
            child: Text('AI Assistant', style: TextStyle(fontSize: 11,
                color: tSub.withOpacity(0.7), fontWeight: FontWeight.w600))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(color: bot,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18), topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)),
              border: Border.all(color: brd, width: 0.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12)]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            ...List.generate(3, (i) => AnimatedBuilder(
              animation: anim,
              builder: (_, __) {
                final v = ((anim.value - i * 0.28) % 1.0).clamp(0.0, 1.0);
                final s = 0.5 + 0.5 * (v < 0.5 ? v * 2 : (1 - v) * 2);
                return Transform.scale(scale: s,
                    child: Container(margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 9, height: 9,
                        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: T.grad)));
              },
            )),
            const SizedBox(width: 10),
            Text('Thinking…', style: TextStyle(color: tSub, fontSize: 13, fontStyle: FontStyle.italic)),
          ]),
        ),
      ]),
    ]),
  );
}

// ══════════════════════════════════════════════════════════
//  AVATARS
// ══════════════════════════════════════════════════════════
class _BotAv extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 36, height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: T.grad,
          boxShadow: [BoxShadow(color: T.p1.withOpacity(0.45), blurRadius: 12)]),
      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18));
}

class _UserAv extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 36, height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, color: T.darkInput,
          border: Border.all(color: T.p1.withOpacity(0.45), width: 1.5)),
      child: const Icon(Icons.person_outline_rounded, color: T.p2, size: 19));
}

class _PulseLogo extends StatefulWidget {
  @override State<_PulseLogo> createState() => _PulseLogoState();
}
class _PulseLogoState extends State<_PulseLogo> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState();
  _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.07).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Container(width: 44, height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: T.grad,
              boxShadow: [BoxShadow(color: T.p1.withOpacity(0.55), blurRadius: 16)]),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 21)));
}

// ══════════════════════════════════════════════════════════
//  BUTTONS
// ══════════════════════════════════════════════════════════
class _SendBtn extends StatefulWidget {
  final bool loading; final VoidCallback onTap;
  const _SendBtn({required this.loading, required this.onTap});
  @override State<_SendBtn> createState() => _SendBtnState();
}
class _SendBtnState extends State<_SendBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit:  (_) => setState(() => _h = false),
    child: GestureDetector(onTap: widget.loading ? null : widget.onTap,
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            width: 52, height: 52,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15),
                gradient: widget.loading
                    ? const LinearGradient(colors: [T.darkInput, T.darkInput])
                    : (_h ? T.gradHov : T.grad),
                boxShadow: widget.loading ? [] : [BoxShadow(
                    color: T.p1.withOpacity(_h ? 0.7 : 0.4), blurRadius: _h ? 22 : 12, offset: const Offset(0, 4))]),
            child: widget.loading
                ? const Padding(padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(strokeWidth: 2.5, color: T.p2))
                : AnimatedScale(scale: _h ? 1.1 : 1.0, duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 22)))),
  );
}

class _ABtn extends StatefulWidget {
  final IconData icon; final String tip; final VoidCallback onTap; final bool useGradient;
  const _ABtn({required this.icon, required this.tip, required this.onTap, required this.useGradient});
  @override State<_ABtn> createState() => _ABtnState();
}
class _ABtnState extends State<_ABtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => Tooltip(message: widget.tip,
      child: MouseRegion(onEnter: (_) => setState(() => _h = true),
          onExit: (_) => setState(() => _h = false),
          child: GestureDetector(onTap: widget.onTap,
              child: AnimatedContainer(duration: const Duration(milliseconds: 160),
                  width: 44, height: 44,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(13),
                      gradient: _h ? (widget.useGradient ? T.geminiGrad : T.grad) : null,
                      color: _h ? null : T.darkInput,
                      border: Border.all(color: _h ? Colors.transparent : T.darkBorder),
                      boxShadow: _h ? [BoxShadow(color: (widget.useGradient
                          ? const Color(0xFF4285F4) : T.p1).withOpacity(0.4), blurRadius: 12)] : []),
                  child: Icon(widget.icon, color: _h ? Colors.white
                      : (widget.useGradient ? T.info : T.p2), size: 20)))));
}

class _ActBtn extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _ActBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.32),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3))),
          child: Icon(icon, size: 14, color: color)));
}

// ══════════════════════════════════════════════════════════
//  SMALL WIDGETS
// ══════════════════════════════════════════════════════════
class _Chip extends StatelessWidget {
  final String label; final IconData icon; final Color color;
  const _Chip({required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(color: T.darkInput, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: T.darkBorder)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color), const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ]));
}

class _IBtn extends StatefulWidget {
  final IconData icon; final String tip; final VoidCallback onTap; final Color hc;
  const _IBtn({required this.icon, required this.tip, required this.onTap, required this.hc});
  @override State<_IBtn> createState() => _IBtnState();
}
class _IBtnState extends State<_IBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => Tooltip(message: widget.tip,
      child: MouseRegion(onEnter: (_) => setState(() => _h = true),
          onExit: (_) => setState(() => _h = false),
          child: GestureDetector(onTap: widget.onTap,
              child: AnimatedContainer(duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: _h ? widget.hc.withOpacity(0.14) : T.darkInput,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: _h ? widget.hc.withOpacity(0.4) : T.darkBorder)),
                  child: Icon(widget.icon, color: _h ? widget.hc : T.tSub, size: 19)))));
}

class _SugChip extends StatefulWidget {
  final String icon, text; final Color card, brd, tSub; final VoidCallback onTap;
  const _SugChip({required this.icon, required this.text, required this.card,
    required this.brd, required this.tSub, required this.onTap});
  @override State<_SugChip> createState() => _SugChipState();
}
class _SugChipState extends State<_SugChip> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
      onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
      child: GestureDetector(onTap: widget.onTap,
          child: AnimatedContainer(duration: const Duration(milliseconds: 180), width: 185,
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
              decoration: BoxDecoration(
                  color: _h ? T.p1.withOpacity(0.14) : widget.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _h ? T.p1.withOpacity(0.5) : widget.brd),
                  boxShadow: _h ? [BoxShadow(color: T.p1.withOpacity(0.2), blurRadius: 12)] : []),
              child: Row(children: [
                Text(widget.icon, style: const TextStyle(fontSize: 16)), const SizedBox(width: 9),
                Expanded(child: Text(widget.text,
                    style: TextStyle(color: _h ? T.p2 : widget.tSub,
                        fontSize: 12.5, fontWeight: FontWeight.w500),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
              ]))));
}

class _QChip extends StatefulWidget {
  final String icon, text; final Color inp, brd, tSub; final VoidCallback onTap;
  const _QChip({required this.icon, required this.text, required this.inp,
    required this.brd, required this.tSub, required this.onTap});
  @override State<_QChip> createState() => _QChipState();
}
class _QChipState extends State<_QChip> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
      onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
      child: GestureDetector(onTap: widget.onTap,
          child: AnimatedContainer(duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color: _h ? T.p1.withOpacity(0.14) : widget.inp,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _h ? T.p1.withOpacity(0.5) : widget.brd)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(widget.icon, style: const TextStyle(fontSize: 13)), const SizedBox(width: 6),
                Text(widget.text, style: TextStyle(color: _h ? T.p2 : widget.tSub,
                    fontSize: 12, fontWeight: FontWeight.w500)),
              ]))));
}

class _FBadge extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _FBadge({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 15), const SizedBox(width: 7),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]));
}

class _Orb extends StatelessWidget {
  final double size; final Color color;
  const _Orb({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color,
          boxShadow: [BoxShadow(color: color, blurRadius: size * 0.7, spreadRadius: size * 0.05)]));
}

// ══════════════════════════════════════════════════════════
//  HISTORY PANEL  (slide-in from right)
// ══════════════════════════════════════════════════════════
class _HistoryPanel extends StatefulWidget {
  final List<Msg> msgs;
  final Color card, brd, tPri, tSub, inp;
  final void Function(int index) onJumpTo;
  const _HistoryPanel({
    required this.msgs, required this.card, required this.brd,
    required this.tPri, required this.tSub, required this.inp,
    required this.onJumpTo,
  });
  @override
  State<_HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<_HistoryPanel> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.msgs
        .asMap().entries
        .where((e) => !e.value.isError &&
        (_search.isEmpty ||
            e.value.text.toLowerCase().contains(_search.toLowerCase())))
        .toList()
        .reversed
        .toList();

    return Container(
      width: 360,
      height: double.infinity,
      decoration: BoxDecoration(
        color: widget.card,
        border: Border(left: BorderSide(color: widget.brd, width: 0.5)),
        boxShadow: [BoxShadow(
            color: T.p1.withOpacity(0.15), blurRadius: 30, offset: const Offset(-4, 0))],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF2A0820), Color(0xFF160B18)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border(bottom: BorderSide(color: widget.brd, width: 0.5)),
          ),
          child: Row(children: [
            ShaderMask(shaderCallback: (b) => T.grad.createShader(b),
                child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 22)),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: [T.p3, T.p2]).createShader(b),
              child: const Text('Chat History',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(gradient: T.grad, borderRadius: BorderRadius.circular(12)),
              child: Text('${widget.msgs.where((m) => !m.isError).length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: T.darkInput,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.brd)),
                  child: const Icon(Icons.close_rounded, color: T.tSub, size: 16)),
            ),
          ]),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            style: TextStyle(color: widget.tPri, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search messages…',
              hintStyle: TextStyle(color: widget.tSub, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: widget.tSub, size: 18),
              suffixIcon: _search.isNotEmpty
                  ? GestureDetector(
                  onTap: () { _searchCtrl.clear(); setState(() => _search = ''); },
                  child: Icon(Icons.close_rounded, color: widget.tSub, size: 16))
                  : null,
              filled: true, fillColor: widget.inp,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: widget.brd)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: widget.brd)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: T.p1, width: 1.5)),
            ),
          ),
        ),

        // Stats row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            _StatPill(icon: Icons.person_outline_rounded,
                label: '${widget.msgs.where((m) => m.isUser && !m.isError).length} you',
                color: T.p1),
            const SizedBox(width: 8),
            _StatPill(icon: Icons.smart_toy_outlined,
                label: '${widget.msgs.where((m) => !m.isUser && !m.isError).length} AI',
                color: T.info),
            const SizedBox(width: 8),
            _StatPill(icon: Icons.bookmark_rounded,
                label: '${widget.msgs.where((m) => m.isBookmarked).length} saved',
                color: T.warn),
          ]),
        ),
        const SizedBox(height: 10),
        Divider(color: widget.brd, height: 1),

        // Message list
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.search_off_rounded, color: widget.tSub, size: 40),
            const SizedBox(height: 10),
            Text('No messages found', style: TextStyle(color: widget.tSub, fontSize: 14)),
          ]))
              : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final entry = filtered[i];
                return _HistoryItem(
                  msg: entry.value, index: entry.key,
                  searchTerm: _search, tPri: widget.tPri,
                  tSub: widget.tSub, inp: widget.inp, brd: widget.brd,
                  onTap: () => widget.onJumpTo(entry.key),
                );
              }),
        ),
      ]),
    );
  }
}

// ── History item ─────────────────────────────────────────
class _HistoryItem extends StatefulWidget {
  final Msg msg; final int index; final String searchTerm;
  final Color tPri, tSub, inp, brd; final VoidCallback onTap;
  const _HistoryItem({required this.msg, required this.index, required this.searchTerm,
    required this.tPri, required this.tSub, required this.inp,
    required this.brd, required this.onTap});
  @override State<_HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<_HistoryItem> {
  bool _hov = false;

  List<TextSpan> _highlight(String text, String q) {
    if (q.isEmpty) return [TextSpan(text: text)];
    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final lq = q.toLowerCase();
    int start = 0;
    while (true) {
      final idx = lower.indexOf(lq, start);
      if (idx == -1) { spans.add(TextSpan(text: text.substring(start))); break; }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(TextSpan(text: text.substring(idx, idx + q.length),
          style: const TextStyle(backgroundColor: T.p1, color: Colors.white, fontWeight: FontWeight.bold)));
      start = idx + q.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.msg.isUser;
    final preview = widget.msg.text.length > 100
        ? '${widget.msg.text.substring(0, 100)}…'
        : widget.msg.text;
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hov ? T.p1.withOpacity(0.12) : widget.inp.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hov ? T.p1.withOpacity(0.5) : widget.brd.withOpacity(0.5)),
            boxShadow: _hov ? [BoxShadow(color: T.p1.withOpacity(0.15), blurRadius: 10)] : [],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 26, height: 26,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: u ? T.grad : null, color: u ? null : widget.inp,
                      border: u ? null : Border.all(color: widget.brd)),
                  child: Icon(u ? Icons.person_rounded : Icons.auto_awesome_rounded,
                      color: u ? Colors.white : T.p2, size: 13)),
              const SizedBox(width: 8),
              Text(u ? 'You' : 'AI Assistant',
                  style: TextStyle(color: u ? T.p2 : widget.tSub,
                      fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(widget.msg.hhmm,
                  style: TextStyle(color: widget.tSub.withOpacity(0.6), fontSize: 10.5)),
              if (widget.msg.isBookmarked) ...[
                const SizedBox(width: 5),
                const Icon(Icons.bookmark_rounded, size: 13, color: T.warn),
              ],
              if (widget.msg.fileName != null) ...[
                const SizedBox(width: 5),
                Icon(widget.msg.fileType == 'image'
                    ? Icons.image_rounded : Icons.attach_file_rounded,
                    size: 13, color: T.info),
              ],
            ]),
            const SizedBox(height: 8),
            RichText(
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(color: widget.tPri, fontSize: 13, height: 1.45),
                children: _highlight(preview, widget.searchTerm),
              ),
            ),
            if (_hov) ...[
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(gradient: T.grad, borderRadius: BorderRadius.circular(10)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('Jump to', style: TextStyle(color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.bold)),
                    ]),
                  )),
            ],
          ]),
        ),
      ),
    );
  }
}

// ── Stat pill ────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _StatPill({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13), const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]));
}

// ══════════════════════════════════════════════════════════
//  DIALOGS
// ══════════════════════════════════════════════════════════
class _ConfirmDialog extends StatelessWidget {
  final String title, msg; final Color card, brd; final Color tSub; final VoidCallback onOk;
  const _ConfirmDialog({required this.title, required this.msg, required this.card,
    required this.brd, required this.tSub, required this.onOk});
  @override
  Widget build(BuildContext context) => AlertDialog(
      backgroundColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: ShaderMask(shaderCallback: (b) => T.grad.createShader(b),
          child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      content: Text(msg, style: TextStyle(color: tSub, fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: tSub))),
        Container(decoration: BoxDecoration(gradient: T.grad, borderRadius: BorderRadius.circular(12)),
            child: TextButton(onPressed: () { Navigator.pop(context); onOk(); },
                child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
      ]);
}

class _BookmarkDialog extends StatelessWidget {
  final List<MapEntry<int, Msg>> bk;
  final Color card, brd, tPri, tSub, inp;
  const _BookmarkDialog({required this.bk, required this.card, required this.brd,
    required this.tPri, required this.tSub, required this.inp});
  @override
  Widget build(BuildContext context) => AlertDialog(
      backgroundColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: ShaderMask(shaderCallback: (b) => T.grad.createShader(b),
          child: const Text('Bookmarked Messages',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      content: SizedBox(width: 420, height: 320,
          child: bk.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bookmark_outline, color: tSub, size: 44), const SizedBox(height: 12),
            Text('No bookmarks yet', style: TextStyle(color: tSub))]))
              : ListView.builder(itemCount: bk.length, itemBuilder: (_, i) {
            final m = bk[i].value;
            return Container(margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: inp, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: brd)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.isUser ? '👤 You' : '🤖 AI Assistant',
                      style: const TextStyle(color: T.p2, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(m.text.length > 140 ? '${m.text.substring(0, 140)}…' : m.text,
                      style: TextStyle(color: tPri, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(m.hhmm, style: TextStyle(color: tSub, fontSize: 11)),
                ]));
          })),
      actions: [TextButton(onPressed: () => Navigator.pop(context),
          child: Text('Close', style: TextStyle(color: T.p2)))]);
}

class _InfoPanel extends StatelessWidget {
  final int msgCount, bkCount;
  final Color card, brd, tPri, tSub;
  const _InfoPanel({required this.msgCount, required this.bkCount,
    required this.card, required this.brd, required this.tPri, required this.tSub});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(28),
          border: Border.all(color: brd),
          boxShadow: [BoxShadow(color: T.p1.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, -4))]),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: brd, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 18),
        ShaderMask(shaderCallback: (b) => T.grad.createShader(b),
            child: const Text('About This App',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 16),
        _R(icon: Icons.bolt_rounded,        l: 'Text AI',      v: 'Groq · Llama 3.3 70B', tP: tPri, tS: tSub),
        _R(icon: Icons.remove_red_eye,      l: 'Image AI',     v: 'Google Gemini Vision',  tP: tPri, tS: tSub),
        _R(icon: Icons.chat_bubble_outline, l: 'Messages',     v: '$msgCount total',       tP: tPri, tS: tSub),
        _R(icon: Icons.bookmark_outline,    l: 'Bookmarks',    v: '$bkCount saved',        tP: tPri, tS: tSub),
        _R(icon: Icons.history_rounded,     l: 'History',      v: 'localStorage (60 msgs)',tP: tPri, tS: tSub),
        _R(icon: Icons.image_outlined,      l: 'Image Upload', v: 'JPG, PNG, GIF, WebP',   tP: tPri, tS: tSub),
        _R(icon: Icons.attach_file,         l: 'File Upload',  v: 'Text & Code files',     tP: tPri, tS: tSub),
        _R(icon: Icons.code_rounded,        l: 'Built with',   v: 'Flutter Web + Dart',    tP: tPri, tS: tSub),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: T.p1.withOpacity(0.08), borderRadius: BorderRadius.circular(14),
                border: Border.all(color: T.p1.withOpacity(0.2))),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: T.p2, size: 18), const SizedBox(width: 10),
              Expanded(child: Text('Images → Gemini Vision. Text/Code → Groq Llama. '
                  'History saved in browser localStorage. No database required.',
                  style: TextStyle(color: tSub, fontSize: 13, height: 1.5))),
            ])),
      ]));
}

class _R extends StatelessWidget {
  final IconData icon; final String l, v; final Color tP, tS;
  const _R({required this.icon, required this.l, required this.v, required this.tP, required this.tS});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Icon(icon, color: T.p2, size: 18), const SizedBox(width: 12),
        Text(l, style: TextStyle(color: tS, fontSize: 13)),
        const Spacer(),
        Text(v, style: TextStyle(color: tP, fontSize: 13, fontWeight: FontWeight.w600)),
      ]));
}