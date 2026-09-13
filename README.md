# Dynamic Flow HUD

A unified desktop notch HUD combining **9Router Token Telemetry** and **Hermes Multi-Agent Fleet Telemetry** into an Apple Dynamic Island interface.

Built with **PySide6 + QML (Qt Quick)**, running at a 165Hz target with custom spring physics.

---

## Architecture & Views

### 1. Min View (Side-by-Side Unified Capsule)
- **Divided Capsule Layout**:
  - **Left Half**: Fleet telemetry (`[●] @agent_name · tool` or `[●] Fleet Idle`).
  - **Center Divider**: 1px vertical separator line (`#262629`).
  - **Right Half**: 9Router spend & tokens (`XXk tok • $0.XX`, flying delta feedback, and hover peek).
- **Smooth Expansion**: 340px resting width, dynamically expanding to 380px on cursor hover.

### 2. Normal View
- Displays 9Router 3-card metric overview, active model pill, and token velocity ticker.

### 3. Detailed View (Tabbed Master Roster & Analytics)
- Unified header with interactive tab switcher:
  - **`9Router Analytics`**: Full timeline tabs (Today, Week, Month), 5-column primary stats card, provider/account management, latency, top models, and live API history.
  - **`Agent Fleet Roster`**: Complete 14-agent fleet roster, active tool verbs, last task descriptions, reasoning tokens, relative time ago, and click-to-copy agent handles.

---

## Installation & Launch

### Quick Launch (Windows)

Double-click `dynamic-flow.bat` or run:
```cmd
dynamic-flow.bat
```

### Manual Launch

```bash
python -m app.main
```

---

## License

MIT License.
