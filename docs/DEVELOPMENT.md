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

GitHub 中已提交并推送的内容是可信源。云盘只作为辅助备份，不用于解决 Git 冲突。
