# 🤖 Flutter VM MCP Server

Control a live Flutter app with AI. This MCP (Model Context Protocol) server bridges **Claude AI** to a running Flutter application via the **Dart VM Service Protocol** — letting Claude navigate screens, tap buttons, enter text, read widget state, and run full QA flows in real time.

---

## 📁 Repository Structure

```
flutter-mcp-tester/
├── flutter-mcp-server/         # Node.js MCP server
│   ├── flutter_mcp_server.js
│   ├── package.json
│   └── README.md
└── (your-flutter-app)/         # Flutter app
    ├── lib/
    │   └── main.dart
    └── pubspec.yaml
```

---

## ✨ What It Does

| Claude says... | What happens on the emulator |
|---|---|
| *"Log in with test@mcp.com / 1234"* | Types credentials and taps the login button |
| *"Go to the counter screen and increment 5 times"* | Navigates and taps live |
| *"Read the counter value"* | Returns the live value from the running app |
| *"Toggle dark mode on in settings"* | Flips the switch visually |
| *"Run a full end-to-end QA test"* | Executes multi-step flows with PASS/FAIL report |

---

## 🏗️ Architecture

```
Claude Code (Terminal)
        ↕  MCP Protocol (stdio)
   MCP Server (Node.js)  ← flutter-mcp-server/
        ↕  WebSocket — Dart VM Service Protocol
   Flutter App (running on emulator/device)
        ↕
   dart:developer extensions (ext.mcptest.*)
```

---

## 📋 Prerequisites

- [Node.js](https://nodejs.org/) v18 or higher
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.0+
- [Claude Code CLI](https://docs.claude.ai/claude-code) installed and authenticated
- An Android/iOS emulator or physical device

---

## 🚀 Local Setup Guide

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/flutter-mcp-tester.git
cd flutter-mcp-tester
```

### 2. Setup the MCP Server

```bash
cd flutter-mcp-server
npm install
```

**Test the server starts correctly:**
```bash
node flutter_mcp_server.js
# Expected output: Flutter MCP Server v2 running...
```
Press `Ctrl+C` to stop — this just confirms it works.

### 3. Setup the Flutter App

```bash
cd ../your-flutter-app    # replace with your actual flutter app folder name
flutter pub get
```

---

## 📱 Flutter App Setup

### 1. Add the MCP bridge to `main.dart`

Your Flutter app needs to register custom VM service extensions so Claude can interact with it. Add the following to your `main.dart`:

```dart
import 'dart:developer' as dev;
import 'dart:convert';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final Map<String, TextEditingController> textControllers = {};
final Map<String, VoidCallback> tapCallbacks = {};
final Map<String, String Function()> textGetters = {};

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _registerExtensions();
  runApp(const MyApp());
}

void _registerExtensions() {
  dev.registerExtension('ext.mcptest.navigate', (method, params) async {
    final route = params['route'] ?? '/home';
    navigatorKey.currentState?.pushNamed(route);
    return dev.ServiceExtensionResponse.result(
        jsonEncode({'status': 'ok', 'route': route}));
  });

  dev.registerExtension('ext.mcptest.back', (method, params) async {
    navigatorKey.currentState?.pop();
    return dev.ServiceExtensionResponse.result(jsonEncode({'status': 'ok'}));
  });

  dev.registerExtension('ext.mcptest.setText', (method, params) async {
    final key = params['key'] ?? '';
    final text = params['text'] ?? '';
    final ctrl = textControllers[key];
    if (ctrl == null) return dev.ServiceExtensionResponse.result(
        jsonEncode({'status': 'error', 'msg': 'No controller for: $key'}));
    ctrl.text = text;
    ctrl.selection = TextSelection.collapsed(offset: text.length);
    return dev.ServiceExtensionResponse.result(
        jsonEncode({'status': 'ok', 'key': key, 'text': text}));
  });

  dev.registerExtension('ext.mcptest.tap', (method, params) async {
    final key = params['key'] ?? '';
    final cb = tapCallbacks[key];
    if (cb == null) return dev.ServiceExtensionResponse.result(
        jsonEncode({'status': 'error', 'msg': 'No callback for: $key'}));
    cb();
    return dev.ServiceExtensionResponse.result(
        jsonEncode({'status': 'ok', 'key': key}));
  });

  dev.registerExtension('ext.mcptest.getText', (method, params) async {
    final key = params['key'] ?? '';
    final getter = textGetters[key];
    if (getter != null) return dev.ServiceExtensionResponse.result(
        jsonEncode({'status': 'ok', 'text': getter()}));
    final ctrl = textControllers[key];
    if (ctrl != null) return dev.ServiceExtensionResponse.result(
        jsonEncode({'status': 'ok', 'text': ctrl.text}));
    return dev.ServiceExtensionResponse.result(
        jsonEncode({'status': 'error', 'msg': 'No getter for: $key'}));
  });

  dev.registerExtension('ext.mcptest.listKeys', (method, params) async {
    return dev.ServiceExtensionResponse.result(jsonEncode({
      'textControllers': textControllers.keys.toList(),
      'tapCallbacks': tapCallbacks.keys.toList(),
      'textGetters': textGetters.keys.toList(),
    }));
  });
}
```

### 2. Register Widgets in Each Screen

In every screen's `initState`, register its interactive widgets:

```dart
@override
void initState() {
  super.initState();
  // TextFields
  textControllers['email_field']    = _emailController;
  textControllers['password_field'] = _passwordController;

  // Buttons
  tapCallbacks['login_btn'] = _handleLogin;
  tapCallbacks['skip_btn']  = _handleSkip;

  // Readable values
  textGetters['counter_value'] = () => '$_count';
}

@override
void dispose() {
  textControllers.remove('email_field');
  textControllers.remove('password_field');
  tapCallbacks.remove('login_btn');
  super.dispose();
}
```

> **Rule:** always clean up in `dispose()` to avoid stale callbacks.

### 3. Use `navigatorKey` in `MaterialApp`

```dart
MaterialApp(
  navigatorKey: navigatorKey, // 👈 required for MCP navigation
  initialRoute: '/login',
  routes: { ... },
)
```

### 4. Run the Flutter App with VM Service Exposed

```bash
# from inside your flutter app folder
flutter run --observe --observatory-port=8181 --disable-service-auth-codes
```

Wait for this line:
```
A Dart VM Service is available at: http://127.0.0.1:8181/ws
```

---

## 🔧 Register the MCP Server with Claude Code

> Make sure you use the **absolute path** to `flutter_mcp_server.js` inside the `flutter-mcp-server` folder.

**Windows:**
```bash
claude mcp add flutter-vm node C:\path\to\flutter-mcp-tester\flutter-mcp-server\flutter_mcp_server.js \
  -s user \
  -e FLUTTER_VM_URL=ws://127.0.0.1:8181/ws
```

**Mac/Linux:**
```bash
claude mcp add flutter-vm node /absolute/path/to/flutter-mcp-tester/flutter-mcp-server/flutter_mcp_server.js \
  -s user \
  -e FLUTTER_VM_URL=ws://127.0.0.1:8181/ws
```

Verify it was added:
```bash
claude mcp list
# flutter-vm: node /path/to/flutter-mcp-server/flutter_mcp_server.js
```

---

## 🎮 Running Claude Code

Open Claude Code in a **new terminal**:

```bash
claude
```

Check MCP is connected:
```
/mcp
# flutter-vm should show ✅
```

Then start testing:
```
Use flutter_get_widget_tree to show me what's currently on screen
```

---

## 🛠️ Available MCP Tools

| Tool | Description |
|---|---|
| `flutter_get_widget_tree` | Returns the full live widget tree |
| `flutter_navigate_to` | Navigate to a named route e.g. `'/home'` |
| `flutter_navigate_back` | Go back to previous screen |
| `flutter_tap` | Tap any registered widget by key |
| `flutter_long_press` | Long-press a widget by key |
| `flutter_enter_text` | Type text into a registered TextField |
| `flutter_get_text` | Read text value from any registered widget |
| `flutter_scroll` | Scroll a widget by dx/dy |
| `flutter_scroll_into_view` | Scroll until a widget is visible |
| `flutter_wait_for` | Wait until a widget appears |
| `flutter_eval` | Evaluate a raw Dart expression |
| `flutter_hot_reload` | Trigger a hot reload |
| `flutter_toggle_debug_paint` | Show/hide widget boundary outlines |
| `flutter_set_time_dilation` | Slow down animations (1.0 = normal) |

---

## 🧪 Example QA Prompts

**Happy path login:**
```
Using flutter MCP tools: enter 'test@mcp.com' in email_field,
'1234' in password_field, tap login_btn, then confirm we are on HomeScreen.
Report PASS or FAIL.
```

**Counter stress test:**
```
Using flutter MCP tools: skip login, go to counter screen,
tap increment_btn 10 times, confirm value is 10,
tap reset_btn, confirm value is 0. Report PASS or FAIL.
```

**Full end-to-end run:**
```
Run a complete QA journey: login → counter (increment/reset) →
settings (toggle dark mode, change language, save) →
profile (edit name, save). After each screen assert the action
succeeded. Print a final PASS/FAIL report.
```

---

## ⚙️ Environment Variables

| Variable | Default | Description |
|---|---|---|
| `FLUTTER_VM_URL` | `ws://localhost:8181/ws` | WebSocket URL of the Dart VM Service |

Override when using a custom port or a physical device:
```bash
FLUTTER_VM_URL=ws://127.0.0.1:9999/ws node flutter_mcp_server.js
```

---

## 🧹 Removing the MCP Server

```bash
# Remove from Claude Code
claude mcp remove flutter-vm

# Or temporarily disable without removing
claude mcp disable flutter-vm
claude mcp enable flutter-vm   # re-enable later
```

---

## 🐛 Troubleshooting

**`Unknown method "callServiceExtension"`**
→ Extensions must be called directly as the method name (e.g. `ext.mcptest.tap`), not wrapped in `callServiceExtension`. This is already handled in the server.

**`No tap callback for key: xyz`**
→ The widget hasn't registered its callback yet. Make sure `initState` registers it and `dispose` cleans it up.

**`Connection refused` on WebSocket**
→ Flutter app is not running, or was started without `--observe`. Restart with:
```bash
flutter run --observe --observatory-port=8181 --disable-service-auth-codes
```

**Claude says "I can't interact with UIs"**
→ The MCP server isn't registered or not connected. Run `claude mcp list` and `/mcp` inside Claude Code to verify.

---

## 📄 License

MIT — use freely in personal and commercial projects.

---

## 🙌 Credits

Built using:
- [Model Context Protocol SDK](https://github.com/modelcontextprotocol/typescript-sdk)
- [Dart VM Service Protocol](https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md)
- [Flutter](https://flutter.dev)
- [Claude Code](https://docs.claude.ai/claude-code)
