# Development Workflow

## 开始工作

```powershell
.\project-control\scripts\Start-Work.ps1
```

小而明确的修改可以直接提交到 `main`。较大修改使用 `work/功能名` 分支：

```powershell
.\project-control\scripts\New-WorkBranch.ps1 -Name feature-name
```

## 保存工作

Vivado 可以保持打开，但必须先执行 Save All，并确认综合、实现和仿真任务停止：

```powershell
.\project-control\scripts\Save-Work.ps1
```

提交前，脚本会使用临时 Git 索引对全部待提交内容进行两次快照；只有前后树哈希一致时才继续。该检查不解析文件名，因此兼容中文路径以及 VS Code 中的 Windows PowerShell 终端。临时索引不会改变当前暂存区，并会在检查结束后自动删除。

在 Codex 中单独调用 `$sync-fpga-code` 可以完整部署仓库：Agent 自动检查全部改动并生成中文提交说明，只在提交推送前确认一次 Vivado 状态和部署范围。

GitHub 中已提交并推送的内容是可信源。云盘只作为辅助备份，不用于解决 Git 冲突。
