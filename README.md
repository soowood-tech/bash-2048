# 🎮 Bash 2048

> A feature-packed, beautifully styled implementation of the classic **2048** puzzle game written in **pure Bash** with zero external dependencies.

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## ✨ Features

- ⚡ **Zero dependencies:** Runs natively on any Linux/macOS terminal with Bash 4+.
- 🎨 **Rich ANSI Colors:** Authentic tile color progression (2, 4, 8 ... up to 2048 and beyond).
- 🤖 **AI Auto-Play Solver:** Press `Tab` or `T` at any time to watch the built-in bot solve the puzzle.
- ↩️ **Undo Feature:** Press `U` to revert the last move if you made a mistake.
- 📐 **Compact & Centered:** Perfectly fits small terminal windows (like tiling window managers, splits, and foot/kitty).
- 🏆 **High Score Persistence:** Automatically saves your record to `~/.bash_2048_highscore`.

---

## 🕹️ Controls

| Action | Primary Key | Alternative | Russian Layout |
| :--- | :---: | :---: | :---: |
| **Move Up** | `W` | `↑` | `Ц` |
| **Move Down** | `S` | `↓` | `Ы` |
| **Move Left** | `A` | `←` | `Ф` |
| **Move Right** | `D` | `→` | `В` |
| **Undo Move** | `U` | - | `Г` |
| **Toggle AI Solver** | `Tab` | `T` | `Е` |
| **Restart Game** | `R` | - | `К` |
| **Quit** | `Q` | - | `Й` |

---

## 🚀 Quick Start

```bash
cd ~/bash-2048
./2048.sh
```

*(Optional) Create a global shortcut in `~/.local/bin`:*
```bash
mkdir -p ~/.local/bin
ln -sf "$(pwd)/2048.sh" ~/.local/bin/2048
```
Now simply type `2048` from anywhere!

---

## 📄 License

MIT License. Free to use, modify, and distribute.
