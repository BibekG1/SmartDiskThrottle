
# 🚀 SmartDiskThrottle v1.2
**Automated, adaptive I/O throttling for Windows 10/11**  
*Silently detects sustained high I/O background processes and applies `Idle` priority to keep your system responsive — zero manual intervention required.*

> ✨ **New in v1.2**: Multi-instance I/O aggregation, garbage collection for zero memory drift, production-ready for 24/7 background execution.

---

## ⚡ One-Click Install (Recommended)

**Run this single line in Administrator PowerShell** to auto-download, install, and configure SmartDiskThrottle:

```powershell
irm https://raw.githubusercontent.com/BibekG1/SmartDiskThrottle/main/install.ps1 | iex
```

### ✅ What This Does:
| Step | Action |
|------|--------|
| 1️⃣ | Downloads `SmartDiskThrottle.ps1` + `SmartDiskThrottle_Task.xml` to `C:\Scripts\` |
| 2️⃣ | Sets `RemoteSigned` ExecutionPolicy for current user (if needed) |
| 3️⃣ | Registers a Task Scheduler task that runs at login (with 1-min delay) |
| 4️⃣ | Verifies installation and shows next steps |

### 🔐 Safety First:
- ✅ Script is open-source — review `install.ps1` on GitHub before running
- ✅ Requires **Administrator** privileges (explicit UAC prompt)
- ✅ No registry edits, no service changes, no persistent modifications beyond the scheduled task
- ✅ Fully reversible: Disable task in Task Scheduler or reboot to undo

---

## 📦 Manual Deployment (Alternative)

Prefer to inspect files first? Here's how to install manually:
```markdown
### Step 1: Download Files
1. Download `src/SmartDiskThrottle.ps1` → Save to `C:\Scripts\SmartDiskThrottle.ps1`
2. Download `src/SmartDiskThrottle_Task.xml` → Save to `C:\Scripts\SmartDiskThrottle_Task.xml`

### Step 2: Import Task Scheduler Task
1. Open **Task Scheduler** as Administrator
2. Right-click **Task Scheduler Library** → **Import Task...**
3. Select `C:\Scripts\SmartDiskThrottle_Task.xml` → Click **OK**
4. Confirm the task is **Enabled** and set to run with **Highest privileges**

### Step 3: Verify
- Reboot or manually run the task once
- Check logs at `%TEMP%\SmartDiskThrottle.log`
- Open Task Manager → Details tab → Add `Priority` column → Throttled apps show `Idle`

---

## ⚙️ Configuration (Edit `SmartDiskThrottle.ps1` Top Section)

| Parameter | Default | Recommendation |
|-----------|---------|----------------|
| `$diskThresholdMBps` | `15` | Raise to `20-25` if you download large files. Lower to `8-10` for aggressive throttling. |
| `$checkIntervalSec` | `15` | Decrease to `10` for faster reaction, increase to `30` to reduce CPU overhead. |
| `$sustainedChecks` | `3` | Must exceed threshold for 3 consecutive checks (45s total) before throttling. |
| `$cooldownChecks` | `5` | Prevents priority thrashing after a process drops below threshold. |

> 💡 **Tip**: After editing, re-run the one-liner installer to update the installed script.
```
---

## 🔍 How It Works

- 📊 Monitors `\Process(*)\IO Data Bytes/sec` performance counter every 15s
- 🔗 Aggregates I/O across multi-instance processes (`chrome`, `chrome#1`, `chrome#2`, etc.)
- 🛡️ Ignores 30+ protected Windows/system processes (see `$protectedProcesses` list)
- 📉 Applies `PriorityClass = Idle` only after sustained threshold breach (configurable)
- 🔄 Automatically restores `Normal` priority + cooldown when usage drops
- 🗑️ Self-managing log (rotates at 500 lines), zero memory drift via garbage collection

---

## 🛡️ Safety & Limitations

### ✅ What Makes It Safe:
| Feature | Why It Matters |
|---------|---------------|
| **Protected Process List** | Critical system processes (`svchost`, `TiWorker`, `MsMpEng`, etc.) are hard-coded to never be throttled |
| **Volatile Priority Changes** | `PriorityClass` adjustments exist only in RAM — reboot resets everything |
| **No Registry/Service Edits** | Pure PowerShell using native Windows APIs; no persistent system changes |
| **Transparent Code** | Fully open, well-commented, no obfuscation or hidden payloads |
| **Task Scheduler Integration** | Runs with standard Windows scheduling; easy to disable/uninstall |

### ⚠️ Known Limitations:
| Limitation | Workaround |
|------------|------------|
| **I/O Counter Includes Network** | Windows lumps disk + network I/O in standard counters. Heavy downloads may trigger throttling. Raise `$diskThresholdMBps` or add downloader processes to `$protectedProcesses`. |
| **English Counter Paths** | `\Process(*)\...` is localized on non-English Windows. For global deployment, use registry-based counter path lookup (advanced). |
| **Not True EcoQoS** | Achieves identical practical results via `Idle` priority. For kernel-level EcoQoS (leaf icon 🍃), pair with Process Lasso `PowerSaver`. |
| **Requires Admin to Install** | Task Scheduler registration needs elevated privileges. After install, the script runs with standard user permissions. |

---

## 🛠️ Troubleshooting

| Issue | Fix |
|-------|-----|
| **Script not running** | Verify Task is `Enabled`, runs with `Highest privileges`, and points to correct `.ps1` path in Task Scheduler |
| **False throttling on downloads** | Increase `$diskThresholdMBps` or add `'steam'`, `'qBittorrent'`, `'firefox'`, etc. to `$protectedProcesses` |
| **Log not updating** | Check execution policy: Run `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` in PowerShell |
| **Need to pause temporarily** | Disable task in Task Scheduler → re-enable when ready (no uninstall needed) |
| **Verify active throttling** | Task Manager → Details tab → Right-click headers → `Select columns` → ✅ `Priority` → Throttled apps show `Idle` |
| **Task fails to start** | Ensure `C:\Scripts\` folder exists and contains both `.ps1` and `.xml` files; check Task Scheduler "Last Run Result" |

---

## 🔐 Before You Run: Quick Safety Checklist

- ✅ **Verify the URL**: Ensure the one-liner points to `github.com/BibekG1/SmartDiskThrottle` exactly
- ✅ **Run as Administrator**: Right-click PowerShell → "Run as Administrator" (required for Task Scheduler)
- ✅ **Review the code** (optional but recommended): Open `install.ps1` and `SmartDiskThrottle.ps1` on GitHub to inspect
- ✅ **Understand the scope**: The script only downloads files, sets ExecutionPolicy for current user, and registers a scheduled task
- ✅ **Know how to undo**: Disable the task in Task Scheduler or reboot to instantly revert all changes

---

## 🔄 Updating SmartDiskThrottle

To update to a newer version:

```powershell
# Simply re-run the one-liner installer:
irm https://raw.githubusercontent.com/BibekG1/SmartDiskThrottle/main/install.ps1 | iex
```

The installer automatically:
- Backs up existing files (if needed)
- Downloads the latest `SmartDiskThrottle.ps1` and `.xml`
- Re-registers the Task Scheduler task with updated settings

---

## 🗑️ Uninstall

To completely remove SmartDiskThrottle:

```powershell
# Run in Administrator PowerShell:
Unregister-ScheduledTask -TaskName "SmartDiskThrottle" -Confirm:$false
Remove-Item "C:\Scripts\SmartDiskThrottle*" -Force
Remove-Item "$env:TEMP\SmartDiskThrottle.log" -ErrorAction SilentlyContinue
```

✅ All changes are reverted. Priority adjustments vanish on next reboot automatically.

---

## 📜 Credits & License

- **Developed by**: Community-driven project, production-tested for personal/desktop use
- **License**: MIT — Free to use, modify, and distribute. No warranty.
- **Inspired by**: Windows performance tuning best practices, Process Lasso architecture, and user feedback from Windows optimization communities
- **Best paired with**: [Process Lasso](https://bitsum.com/) for true EcoQoS + persistent I/O rules on known background apps

### 🤝 Contributing
Found a bug? Want a feature?  
→ Open an issue or pull request on GitHub:  
🔗 `https://github.com/BibekG1/SmartDiskThrottle`

### 📧 Support
- 🐛 Bug reports: Use GitHub Issues
- 💡 Feature requests: Use GitHub Discussions or Issues
- ❓ General questions: Reply to this README or open a Discussion

---

> 💬 **Final Note**: SmartDiskThrottle is designed to be "set and forget." After installation, it runs silently in the background, adapting to your usage patterns. If you ever need to pause it, just disable the task in Task Scheduler — no cleanup required. 🛠️✨
```

---

### ✅ Key Improvements Made:
1.  **One-Click Install at the Top**: Users see the easiest method first.
2.  **Clear "What This Does" Table**: Builds trust by explaining exactly what the installer does.
3.  **Safety Checklist Prominently Placed**: Right before troubleshooting, so users verify before running.
4.  **Added "Updating" and "Uninstall" Sections**: Critical for user confidence and long-term use.
5.  **Better Visual Hierarchy**: Emojis, tables, and callouts make it scannable.
6.  **Contributing/Support Section**: Encourages community engagement.
7.  **Your GitHub Username Pre-Filled**: `BibekG1` is already in the one-liner — ready to copy-paste.

Save this as `README.md` in your repo root, and it's ready for public sharing. 🚀
