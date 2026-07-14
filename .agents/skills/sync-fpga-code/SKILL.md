---
name: sync-fpga-code
description: 一键完整同步和部署基于 FPGA-Project-Template 的 Git/GitHub FPGA 仓库。用户调用 $sync-fpga-code、要求部署整个仓库、同步代码、保存并推送全部改动或验证多电脑一致性时使用；自动检查全部非忽略文件、生成中文提交说明，并在一次 Vivado 状态确认后提交和推送，同时保护 Git LFS 文件及未提交修改。
---

# FPGA 仓库完整同步

将 GitHub 中已提交并推送的内容作为可信源。百度同步盘或其他云盘只作为辅助备份，不用于合并代码或解决冲突。

## 默认行为

- 用户仅调用 `$sync-fpga-code` 时，将其视为“完整部署当前仓库”，不要只报告状态。
- 工作区有改动时，检查整个仓库，自动生成中文提交说明，并在一次确认后提交全部非忽略改动并推送。
- 工作区干净时，安全拉取远程更新并验证一致性，不创建空提交。
- 用户明确要求“只检查”“只拉取”或“只提交不推送”时，严格采用该范围。

## 部署前检查

1. 使用 `git rev-parse --show-toplevel` 确认仓库根目录。
2. 检查当前分支、上游分支、`origin` 地址和 `git status --short`。
3. 存在 `project-control/config/project-config.json` 时读取项目名、Vivado 版本和工程入口。
4. 执行 `git fetch origin --prune`，确认上游没有待拉取提交。远程领先或分支分叉时停止，不在脏工作区上拉取或合并。
5. 检查全部待提交文件。大文件应由 Git LFS 管理；发现凭据、密钥、机器私有配置、仓库外绝对路径或明显放错位置的生成文件时停止并报告。
6. 保留用户现有改动。禁止自动执行 `git reset --hard`、`git checkout --`、强制推送、变基或 stash。

## 工作区干净

存在 `project-control/scripts/Start-Work.ps1` 时运行：

```powershell
.\project-control\scripts\Start-Work.ps1
```

没有项目脚本时运行 `git pull --ff-only`。随后执行完成验证。

## 工作区有改动

1. 展示将被部署的新增、修改、删除和重命名文件；`git add -A` 只包含非忽略文件。
2. 当 RTL、约束、IP、SDK、Vivado 工程或 `output/config` 发生变化时，存在 `Check-Project.ps1` 就先运行它。该检查读取已有 Vivado GUI 结果，不启动编译。
3. 根据主要改动自动生成简短中文提交说明，不再询问用户填写：
   - 仅文档：`文档：<变更摘要>`
   - 脚本或配置：`调整：<变更摘要>`
   - RTL、约束、IP 或 SDK：`修改：<变更摘要>`
   - 多类改动：`更新：同步工程改动`
4. 只询问一次：确认 Vivado 已执行 Save All、综合/实现/仿真任务已停止，并同意将列出的全部改动推送到当前 `origin`。只有用户明确确认后才继续。
5. 存在 `project-control/scripts/Save-Work.ps1` 时运行：

```powershell
.\project-control\scripts\Save-Work.ps1 -Yes -Message "<自动生成的中文提交说明>"
```

6. 没有项目脚本时，依次执行 `git add -A`、检查暂存差异、创建提交并推送当前分支。没有上游时使用 `git push -u origin <当前分支>`。
7. 网络命令失败时最多重试三次；认证、权限或冲突错误不要盲目重试。

## 完成验证

1. 确认工作区干净；如仍有文件，逐项报告，不能声称部署完成。
2. 获取 GitHub 远程分支状态，确认本地 `HEAD`、上游和远程提交完全一致。
3. 运行 `git lfs status`；使用 Git LFS 时运行 `git lfs fsck`。
4. 用中文报告仓库、分支、提交哈希、自动生成的提交说明、推送目标和验证结果。
