#!/usr/bin/env node
/**
 * Flutter VM Service MCP Server
 * Supports: hot reload, navigation, button taps, text input, scrolling, widget tree
 *
 * App setup required in main.dart:
 *   import 'package:flutter_driver/driver_extension.dart';
 *   void main() { enableFlutterDriverExtension(); runApp(MyApp()); }
 *
 * Run app:
 *   flutter run --observe --observatory-port=8181 --disable-service-auth-codes
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListToolsRequestSchema } from "@modelcontextprotocol/sdk/types.js";
import WebSocket from "ws";

const VM_SERVICE_URL = process.env.FLUTTER_VM_URL || "ws://localhost:8181/ws";

// ─── VM WebSocket Client ──────────────────────────────────────────────────────

let ws = null, wsReady = false, msgId = 1, isolateId = null;
const pending = new Map();

function connectVM() {
    return new Promise((resolve, reject) => {
        ws = new WebSocket(VM_SERVICE_URL);
        ws.on("open", () => { wsReady = true; resolve(); });
        ws.on("error", reject);
        ws.on("message", (raw) => {
            const msg = JSON.parse(raw);
            if (msg.id && pending.has(msg.id)) {
                const { resolve, reject } = pending.get(msg.id);
                pending.delete(msg.id);
                msg.error ? reject(new Error(msg.error.message)) : resolve(msg.result);
            }
        });
        ws.on("close", () => { wsReady = false; });
    });
}

async function vmCall(method, params = {}) {
    if (!wsReady) await connectVM();
    return new Promise((resolve, reject) => {
        const id = msgId++;
        pending.set(id, { resolve, reject });
        ws.send(JSON.stringify({ jsonrpc: "2.0", id, method, params }));
    });
}

async function getIsolateId() {
    if (isolateId) return isolateId;
    const vm = await vmCall("getVM");
    isolateId = vm.isolates[0].id;
    return isolateId;
}

// ─── Core VM Helpers ──────────────────────────────────────────────────────────

async function hotReload() {
    return vmCall("reloadSources", { isolateId: await getIsolateId() });
}

async function evalDart(expression) {
    const isoId = await getIsolateId();
    const isolate = await vmCall("getIsolate", { isolateId: isoId });
    return vmCall("evaluate", {
        isolateId: isoId,
        targetId: isolate.rootLib.id,
        expression,
    });
}

// ─── ext.mcptest.* — custom extensions registered in main.dart ───────────────

async function mcpTap(key) {
    const isoId = await getIsolateId();
    return vmCall("ext.mcptest.tap", { isolateId: isoId, key });
}

async function mcpSetText(key, text) {
    const isoId = await getIsolateId();
    return vmCall("ext.mcptest.setText", { isolateId: isoId, key, text });
}

async function mcpGetText(key) {
    const isoId = await getIsolateId();
    return vmCall("ext.mcptest.getText", { isolateId: isoId, key });
}

async function mcpNavigate(route) {
    const isoId = await getIsolateId();
    return vmCall("ext.mcptest.navigate", { isolateId: isoId, route });
}

async function mcpBack() {
    const isoId = await getIsolateId();
    return vmCall("ext.mcptest.back", { isolateId: isoId });
}
// Sends commands through ext.flutter.driver — requires enableFlutterDriverExtension()

async function driverCmd(command, extraParams = {}) {
    const isoId = await getIsolateId();
    // Call ext.flutter.driver directly as the RPC method (not via callServiceExtension)
    return vmCall("ext.flutter.driver", {
        isolateId: isoId,
        command,
        timeout: "10000",
        ...extraParams,
    });
}

// Finder serializers — mirrors Flutter Driver's SerializableFinder
function byKey(key) { return { finderType: "ByValueKey", keyValueString: key, keyValueType: "String" }; }
function byText(text) { return { finderType: "ByText", text }; }
function byTooltip(tip) { return { finderType: "ByTooltipMessage", text: tip }; }
function byType(type) { return { finderType: "ByType", type }; }
function bySemanticsLabel(l) { return { finderType: "BySemanticsLabel", label: l }; }

// Flatten finder into flat params (driver expects flat key-value params)
function flatFinder(finder) {
    return Object.fromEntries(
        Object.entries(finder).map(([k, v]) => [`finder_${k}`, v])
    );
}

// ─── Interaction Actions ──────────────────────────────────────────────────────

// ─── Eval-based UI interactions (reliable, no flutter_driver needed) ─────────

async function tap(finder) {
    const expr = finderToEvalExpr(finder);
    return evalDart(`
    (() async {
      final element = ${expr};
      if (element == null) throw Exception('Widget not found');
      final binding = WidgetsBinding.instance;
      await binding.pump();
      final renderObj = element.renderObject;
      if (renderObj is RenderBox) {
        final center = renderObj.localToGlobal(renderObj.size.center(Offset.zero));
        final gesture = binding.platformDispatcher.implicitView;
        await WidgetController(binding).tapAt(center);
      }
    })()
  `);
}

// Direct approach — use WidgetTester-style hit test via eval
async function tapByKey(key) {
    return evalDart(`
    (() {
      final element = WidgetsBinding.instance.renderViewElement?.findDescendants()
        .whereType<StatefulElement>()
        .firstWhere((e) => e.widget.key?.toString().contains('${key}') ?? false,
          orElse: () => throw Exception('Key not found: ${key}'));
      final box = element.renderObject as RenderBox;
      final pos = box.localToGlobal(box.size.center(Offset.zero));
      WidgetsBinding.instance.handlePointerEvent(PointerDownEvent(position: pos));
      WidgetsBinding.instance.handlePointerEvent(PointerUpEvent(position: pos));
    })()
  `);
}

async function enterText(finder, text) {
    // Most reliable: find the EditableText and set value directly via TextEditingController
    const key = finder.keyValueString || finder.text || '';
    return evalDart(`
    (() {
      // Find all EditableText elements and match by key or proximity
      void findAndSetText(Element element) {
        if (element.widget is EditableText) {
          final et = element.widget as EditableText;
          et.controller.text = '${text}';
          et.controller.selection = TextSelection.collapsed(offset: ${text.length});
          return;
        }
        if (element.widget.key?.toString().contains('${key}') ?? false) {
          element.visitChildren((child) => findAndSetText(child));
          return;
        }
        element.visitChildren((child) => findAndSetText(child));
      }
      final root = WidgetsBinding.instance.renderViewElement;
      if (root != null) findAndSetText(root);
    })()
  `);
}

async function getText(finder) {
    return driverCmd("getText", flatFinder(finder));
}

async function scroll(finder, dx, dy, durationMs = 300) {
    return driverCmd("scroll", {
        ...flatFinder(finder),
        dx: String(dx), dy: String(dy),
        duration: String(durationMs * 1000000),
        frequency: "60",
    });
}

async function scrollIntoView(finder) {
    return driverCmd("scrollIntoView", flatFinder(finder));
}

async function waitFor(finder, timeoutMs = 5000) {
    return driverCmd("waitFor", { ...flatFinder(finder), timeout: String(timeoutMs) });
}

async function waitForAbsent(finder, timeoutMs = 5000) {
    return driverCmd("waitForAbsent", { ...flatFinder(finder), timeout: String(timeoutMs) });
}

function finderToEvalExpr(finder) {
    if (finder.finderType === 'ByValueKey')
        return `WidgetsBinding.instance.renderViewElement?.findDescendants().firstWhere((e) => e.widget.key?.toString().contains('${finder.keyValueString}') ?? false)`;
    if (finder.finderType === 'ByText')
        return `WidgetsBinding.instance.renderViewElement?.findDescendants().firstWhere((e) => e.widget is Text && (e.widget as Text).data == '${finder.text}')`;
    return 'null';
}

// ─── Navigation ───────────────────────────────────────────────────────────────

async function navigateTo(routeName) {
    // Uses eval to call Navigator — works without flutter_driver
    return evalDart(`
    (() {
      final ctx = WidgetsBinding.instance.focusManager.rootScope.context;
      Navigator.of(ctx).pushNamed('${routeName}');
    })()
  `);
}

async function navigateBack() {
    return evalDart(`
    (() {
      final ctx = WidgetsBinding.instance.focusManager.rootScope.context;
      Navigator.of(ctx).pop();
    })()
  `);
}

async function getWidgetTree() {
    // Call extension directly as method name (correct VM Service Protocol)
    const isoId = await getIsolateId();
    return vmCall("ext.flutter.inspector.getRootWidgetTree", {
        isolateId: isoId,
        groupName: "mcp",
        isSummaryTree: "true",
    });
}

async function toggleDebugPaint(enable) {
    const isoId = await getIsolateId();
    return vmCall("ext.flutter.debugPaint", {
        isolateId: isoId,
        enabled: enable ? "true" : "false",
    });
}

async function setTimeDilation(factor) {
    const isoId = await getIsolateId();
    return vmCall("ext.flutter.timeDilation", {
        isolateId: isoId,
        timeDilation: String(factor),
    });
}

// ─── MCP Tool Definitions ─────────────────────────────────────────────────────

const TOOLS = [
    // Reload
    { name: "flutter_hot_reload", description: "Hot reload the Flutter app (preserves state)", inputSchema: { type: "object", properties: {} } },

    // Navigation
    {
        name: "flutter_navigate_to",
        description: "Navigate to a named route, e.g. '/home', '/settings', '/login'",
        inputSchema: { type: "object", properties: { route: { type: "string", description: "Named route, e.g. '/profile'" } }, required: ["route"] },
    },
    { name: "flutter_navigate_back", description: "Go back to the previous screen (Navigator.pop)", inputSchema: { type: "object", properties: {} } },

    // Tap
    {
        name: "flutter_tap",
        description: "Tap a widget. Find it by: key (ValueKey), text label, tooltip, widget type, or semantics label.",
        inputSchema: {
            type: "object",
            properties: {
                by: { type: "string", enum: ["key", "text", "tooltip", "type", "semantics"], description: "How to find the widget" },
                value: { type: "string", description: "The key name, text content, tooltip, type name, or semantics label" },
            },
            required: ["by", "value"],
        },
    },

    // Long press
    {
        name: "flutter_long_press",
        description: "Long-press a widget (triggers context menus, hold actions, etc.)",
        inputSchema: {
            type: "object",
            properties: {
                by: { type: "string", enum: ["key", "text", "tooltip", "type", "semantics"] },
                value: { type: "string" },
            },
            required: ["by", "value"],
        },
    },

    // Text input
    {
        name: "flutter_enter_text",
        description: "Tap a text field and type text into it",
        inputSchema: {
            type: "object",
            properties: {
                by: { type: "string", enum: ["key", "text", "tooltip", "type", "semantics"] },
                value: { type: "string", description: "How to locate the text field" },
                text: { type: "string", description: "Text to type" },
            },
            required: ["by", "value", "text"],
        },
    },

    // Get text
    {
        name: "flutter_get_text",
        description: "Read the text content of a widget (e.g. a Text or TextField)",
        inputSchema: {
            type: "object",
            properties: {
                by: { type: "string", enum: ["key", "text", "tooltip", "type", "semantics"] },
                value: { type: "string" },
            },
            required: ["by", "value"],
        },
    },

    // Scroll
    {
        name: "flutter_scroll",
        description: "Scroll a scrollable widget by dx/dy pixels",
        inputSchema: {
            type: "object",
            properties: {
                by: { type: "string", enum: ["key", "text", "tooltip", "type", "semantics"] },
                value: { type: "string" },
                dx: { type: "number", description: "Horizontal scroll (negative = left)" },
                dy: { type: "number", description: "Vertical scroll (negative = up)" },
                durationMs: { type: "number", description: "Scroll duration in ms (default 300)" },
            },
            required: ["by", "value", "dx", "dy"],
        },
    },

    // Scroll into view
    {
        name: "flutter_scroll_into_view",
        description: "Scroll until a widget is visible on screen",
        inputSchema: {
            type: "object",
            properties: {
                by: { type: "string", enum: ["key", "text", "tooltip", "type", "semantics"] },
                value: { type: "string" },
            },
            required: ["by", "value"],
        },
    },

    // Wait
    {
        name: "flutter_wait_for",
        description: "Wait until a widget appears on screen (useful after navigation or async operations)",
        inputSchema: {
            type: "object",
            properties: {
                by: { type: "string", enum: ["key", "text", "tooltip", "type", "semantics"] },
                value: { type: "string" },
                timeoutMs: { type: "number", description: "Max wait time in ms (default 5000)" },
            },
            required: ["by", "value"],
        },
    },

    // Eval
    {
        name: "flutter_eval",
        description: "Evaluate any Dart expression in the live app context",
        inputSchema: {
            type: "object",
            properties: { expression: { type: "string" } },
            required: ["expression"],
        },
    },

    // Debug helpers
    { name: "flutter_get_widget_tree", description: "Get the current widget tree", inputSchema: { type: "object", properties: {} } },
    {
        name: "flutter_toggle_debug_paint",
        description: "Show/hide widget boundary outlines",
        inputSchema: { type: "object", properties: { enable: { type: "boolean" } }, required: ["enable"] },
    },
    {
        name: "flutter_set_time_dilation",
        description: "Slow down animations (1.0 = normal, 5.0 = 5x slower)",
        inputSchema: { type: "object", properties: { factor: { type: "number" } }, required: ["factor"] },
    },
];

// ─── MCP Server ───────────────────────────────────────────────────────────────

const server = new Server(
    { name: "flutter-vm-service", version: "2.0.0" },
    { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: TOOLS }));

server.setRequestHandler(CallToolRequestSchema, async (req) => {
    const { name, arguments: args } = req.params;

    const finderFor = (by, value) => {
        switch (by) {
            case "key": return byKey(value);
            case "text": return byText(value);
            case "tooltip": return byTooltip(value);
            case "type": return byType(value);
            case "semantics": return bySemanticsLabel(value);
            default: throw new Error(`Unknown finder type: ${by}`);
        }
    };

    try {
        let result;
        switch (name) {
            case "flutter_hot_reload":
                result = await hotReload();
                return { content: [{ type: "text", text: `✅ Hot reload complete.` }] };

            case "flutter_navigate_to":
                result = await mcpNavigate(args.route);
                return { content: [{ type: "text", text: `🧭 Navigated to ${args.route}: ${JSON.stringify(result)}` }] };

            case "flutter_navigate_back":
                result = await mcpBack();
                return { content: [{ type: "text", text: `⬅️ Navigated back.` }] };

            case "flutter_tap":
                result = await mcpTap(args.value);
                return { content: [{ type: "text", text: `👆 Tapped [${args.value}]: ${JSON.stringify(result)}` }] };

            case "flutter_enter_text":
                result = await mcpSetText(args.value, args.text);
                return { content: [{ type: "text", text: `⌨️ Set text "${args.text}" in [${args.value}]: ${JSON.stringify(result)}` }] };

            case "flutter_get_text":
                result = await mcpGetText(args.value);
                return { content: [{ type: "text", text: `📖 Text: ${JSON.stringify(result)}` }] };

            case "flutter_scroll":
                await scroll(finderFor(args.by, args.value), args.dx, args.dy, args.durationMs);
                return { content: [{ type: "text", text: `🖱️ Scrolled (dx:${args.dx}, dy:${args.dy})` }] };

            case "flutter_scroll_into_view":
                await scrollIntoView(finderFor(args.by, args.value));
                return { content: [{ type: "text", text: `📜 Scrolled widget into view.` }] };

            case "flutter_wait_for":
                await waitFor(finderFor(args.by, args.value), args.timeoutMs);
                return { content: [{ type: "text", text: `⏳ Widget found.` }] };

            case "flutter_eval":
                result = await evalDart(args.expression);
                return { content: [{ type: "text", text: `🎯 Result: ${JSON.stringify(result)}` }] };

            case "flutter_get_widget_tree":
                result = await getWidgetTree();
                return { content: [{ type: "text", text: `🌲 Widget Tree:\n${JSON.stringify(result, null, 2)}` }] };

            case "flutter_toggle_debug_paint":
                await toggleDebugPaint(args.enable);
                return { content: [{ type: "text", text: `🖊️ Debug paint ${args.enable ? "on" : "off"}` }] };

            case "flutter_set_time_dilation":
                await setTimeDilation(args.factor);
                return { content: [{ type: "text", text: `⏱️ Animations at ${args.factor}x speed` }] };

            default:
                throw new Error(`Unknown tool: ${name}`);
        }
    } catch (err) {
        return { content: [{ type: "text", text: `❌ Error: ${err.message}` }], isError: true };
    }
});

const transport = new StdioServerTransport();
await server.connect(transport);
console.error("Flutter MCP Server v2 running...");