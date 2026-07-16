# FPGA Project Template

适用于单人、多台 Windows 电脑开发的 Vivado FPGA 工程模板。模板提供 Git/Git LFS 管理、工作分支、环境检查、Vivado GUI 结果检查和 GitHub Release 自动发布流程。

## 创建项目

1. 在 GitHub 点击 **Use this template**，仓库命名为 `Prj_<项目名>`，实际项目默认设为私有。
2. 克隆新仓库并运行 `.\project-control\scripts\Setup-Computer.ps1`。
3. 在 `M1/` 中创建 Vivado 工程，源码尽量使用仓库内相对路径。
4. 将 RTL、IP、约束、SDK 和文档分别放入对应目录。
5. 修改 `project-control/config/project-config.json` 和 `project-control/config/release-files.json`。
6. 运行 `.\project-control\scripts\Start-Work.ps1` 开始开发。

## 目录

```text
M1/             Vivado 工程与必要的 .srcs 内容
rtl/            RTL 源码和 testbench
ip/             手动创建、可复用的 IP
constraints/    XDC 约束
sdk/            SDK/Vitis 应用源码和工程配置
docs/           项目文档，二进制文档使用 Git LFS
output/config/  BIF 模板等生成配置
output/generated/ 本地生成及发布暂存，不提交
.agents/skills/ 仓库级 Codex Agent 技能
project-control/ 版本控制与发布管理
  config/       项目版本、工程路径和发布文件配置
  scripts/      工作、检查和发布脚本
  releases/     GitHub Release 索引
```

## 模板必需文件

使用 **Use this template** 创建项目时，以下基础设施会随仓库一起复制：

- `.agents/skills/sync-fpga-code/`：一键完整同步和部署 Agent。
- `project-control/scripts/`：电脑配置、开始工作、分支、保存提交、工程检查和发布脚本。
- `project-control/config/`：项目参数和发布产物路径模板。
- `project-control/releases/`：GitHub Release 版本索引。
- `output/config/boot.bif.template`：可移植 BOOT 镜像配置模板。
- `.gitattributes`：换行规则和 Git LFS 跟踪规则。
- `.gitignore`：Vivado、SDK、仿真及发布生成文件忽略规则。
- `.github/workflows/check-template.yml`：必需文件、JSON 和 PowerShell 语法检查。

GitHub Actions 会阻止缺少上述必需文件的模板更新。

## 常用命令

```powershell
.\project-control\scripts\Setup-Computer.ps1
.\project-control\scripts\Start-Work.ps1
.\project-control\scripts\New-WorkBranch.ps1 -Name feature-name
.\project-control\scripts\Save-Work.ps1
.\project-control\scripts\Check-Project.ps1
.\project-control\scripts\Publish-Release.ps1
```

## Codex 同步 Agent

模板在 `.agents/skills/sync-fpga-code/` 中提供仓库级同步 Agent。使用 Codex 打开仓库后，可以这样调用：

```text
$sync-fpga-code
```

单独调用即表示完整部署当前仓库。Agent 会检查全部非忽略改动，自动生成中文提交说明；只询问一次 Vivado Save All、任务停止和推送确认，随后完成暂存、提交、推送及远程一致性验证。工作区干净时只安全拉取，不创建空提交。

它不会自动强推、重置、丢弃改动、stash 或使用云盘解决冲突。明确说“只检查”“只拉取”或“只提交不推送”可以限制操作范围。

发布版本采用 `vYYYY.MM.DD.N`，例如 `v2026.07.14.1`。正式 ZIP 永久保存在 GitHub Releases，仓库只保存发布索引与校验值。
