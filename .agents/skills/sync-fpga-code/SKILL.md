---
name: sync-fpga-code
description: 安全同步基于 FPGA-Project-Template 的 Git/GitHub FPGA 工程。用户要求开始工作、拉取最新代码、检查多电脑同步状态、保存工作、提交全部改动、推送或确认本地与远程一致时使用；优先调用 project-control/scripts/Start-Work.ps1 和 Save-Work.ps1，并保护 Vivado 工程、Git LFS 文件及未提交修改。
---

# FPGA 代码同步

将 GitHub 中已提交并推送的内容作为可信源。百度同步盘或其他云盘只作为辅助备份，不用于合并代码或解决冲突。

## 判断操作

- 用户只问状态时，执行只读检查并报告，不拉取、不暂存、不提交。
- 用户要求开始工作或获取最新代码时，执行“同步到本地”。
- 用户要求保存、提交或推送时，执行“同步到 GitHub”。
- 用户只说“同步代码”时，先检查状态：工作区干净则同步到本地；存在改动则展示待提交内容，并取得 Vivado 状态确认和提交说明后同步到 GitHub。

## 通用检查

1. 使用 `git rev-parse --show-toplevel` 确认仓库根目录。
2. 检查当前分支、上游分支、`origin` 地址和 `git status --short`。
3. 存在 `project-control/config/project-config.json` 时读取项目名、Vivado 版本和工程入口。
4. 保留用户现有改动。禁止自动执行 `git reset --hard`、`git checkout --`、强制推送、变基或自动暂存到 stash。
5. 发现分支分叉、合并冲突、意外远程地址或 detached HEAD 时停止，并清楚报告状态。

## 同步到本地

1. 要求工作区干净；有改动时不要拉取，也不要隐藏改动。
2. 存在 `project-control/scripts/Start-Work.ps1` 时，在仓库根目录运行：

   ```powershell
   .\project-control\scripts\Start-Work.ps1
   ```

3. 没有项目脚本时，运行 `git fetch origin --prune`，然后运行 `git pull --ff-only`。
4. 验证当前 `HEAD` 与上游分支一致，并报告分支、提交哈希、Vivado 版本和工程入口。

## 同步到 GitHub

1. 展示 `git status --short`，检查待提交文件是否属于当前工程。
2. 检查大文件是否由 Git LFS 管理；发现凭据、密钥、机器私有配置或明显误生成文件时停止。
3. 必须确认用户已在 Vivado 中执行 Save All，并且综合、实现和仿真任务均已停止。用户在当前请求中已明确确认时无需重复询问。
4. 用户未提供提交说明时，询问一个简短的中文提交说明。
5. 存在 `project-control/scripts/Save-Work.ps1` 时运行：

   ```powershell
   .\project-control\scripts\Save-Work.ps1 -Yes -Message "<中文提交说明>"
   ```

6. 没有项目脚本时，依次执行 `git add -A`、检查暂存差异、创建提交并推送当前分支。不得跳过暂存差异检查。
7. 网络命令失败时最多重试三次；认证、权限或冲突错误不要盲目重试。

## 完成验证

1. 确认工作区是否干净；如仍有文件，逐项报告，不能声称同步完成。
2. 获取远程分支状态，确认本地 `HEAD` 与上游提交一致。
3. 对使用 Git LFS 的仓库运行 `git lfs status`；必要时运行 `git lfs fsck`。
4. 用中文报告仓库、分支、提交哈希、推送目标、验证结果和任何保留文件。
