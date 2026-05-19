# SmartDiskThrottle v1.2
**Automated, adaptive I/O throttling for Windows 10/11**  
*Silently detects sustained high I/O background processes and applies `Idle` priority to keep your system responsive.*

---

## 📦 Deployment
1. Place `SmartDiskThrottle.ps1` in `C:\Scripts\`
2. Open Task Scheduler as Administrator → Import `SmartDiskThrottle_Task.xml`
3. Reboot or manually run the task once to verify
4. Monitor logs at `%TEMP%\SmartDiskThrottle.log`

---

## ⚙️ Configuration (Edit `.ps1` top section)
| Parameter | Default | Recommendation |
|-----------|---------|----------------|
| `$diskThresholdMBps` | `15` | Raise to `20-25` if you download large files. Lower to `8-10` for aggressive throttling. |
| `$checkIntervalSec` | `15` | Decrease to `10` for faster reaction, increase to `30` to reduce CPU overhead. |
| `$sustainedChecks` | `3` | Must exceed threshold for `3` consecutive checks (45s total) before throttling. |
| `$cooldownChecks` | `5` | Prevents priority thrashing after a process drops below threshold. |

---

## 🔍 How It Works
- Monitors `\Process(*)\IO Data Bytes/sec` performance counter every 15s
- Aggregates I/O across multi-instance processes (`chrome`, `chrome#1`, etc.)
- Ignores 30+ protected Windows/system processes
- Applies `PriorityClass = Idle` only after sustained threshold breach
- Automatically restores `Normal` priority + cooldown when usage drops
- Self-managing log (rotates at 500 lines), zero memory drift via garbage collection

---

## 🛡️ Safety & Limitations
✅ **Safe**: Uses native Windows APIs, no registry edits, resets on reboot  
✅ **Transparent**: Fully open, well-commented PowerShell  
⚠️ **I/O Counter Limitation**: Windows lumps disk + network I/O in standard counters. Heavy downloads may trigger throttling. Raise threshold or exclude downloader processes if needed.  
⚠️ **English Counter Paths**: `\Process(*)\...` is localized on non-English Windows. Use registry fallback if deploying globally.  
⚠️ **Not True EcoQoS**: Achieves identical practical results via `Idle` priority. For kernel-level EcoQoS, pair with Process Lasso `PowerSaver`.

---

## 🛠️ Troubleshooting
| Issue | Fix |
|-------|-----|
| Script not running | Verify Task is `Enabled`, runs with `Highest privileges`, and points to correct `.ps1` path |
| False throttling on downloads | Increase `$diskThresholdMBps` or add `'steam'`, `'qBittorrent'`, etc. to `$protectedProcesses` |
| Log not updating | Check execution policy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| Need to pause temporarily | Disable task in Task Scheduler → re-enable when ready |
| Verify active throttling | Task Manager → Details → Add `Priority` column → Throttled apps show `Idle` |

---

## 🔐 Safety Checklist Before Running
- ✅ Verify the URL matches this repo exactly
- ✅ Run in **Administrator** PowerShell (required for Task Scheduler)
- ✅ Review `install.ps1` source on GitHub before executing (optional but recommended)
- ✅ The script only: downloads files, sets ExecutionPolicy for current user, registers a scheduled task
- ✅ No registry edits, no service changes, no persistent modifications beyond the task

### 🚀 One-Click Install
Run in **Administrator PowerShell**:
```powershell
irm https://raw.githubusercontent.com/BibekG1/SmartDiskThrottle/main/install.ps1 | iex

## 📜 Credits & License
- Community-developed, production-tested for personal/desktop use
- MIT-style: Free to use, modify, and distribute. No warranty.
- Best paired with Process Lasso for true EcoQoS + persistent I/O rules

📧 Report issues or request features via your distribution channel.
