# FPGA Project Template

适用于单人、多台 Windows 电脑开发的 Vivado FPGA 工程模板。模板提供 Git/Git LFS 管理、工作分支、环境检查、Vivado GUI 结果检查和 GitHub Release 自动发布流程。

## 创建项目

1. 在 GitHub 点击 **Use this template**，仓库命名为 `Prj_<项目名>`，实际项目默认设为私有。
2. 克隆新仓库并运行 `.\scripts\Setup-Computer.ps1`。
3. 在 `M1/` 中创建 Vivado 工程，源码尽量使用仓库内相对路径。
4. 将 RTL、IP、约束、SDK 和文档分别放入对应目录。
5. 修改 `config/project-config.json` 和 `config/release-files.json`。
6. 运行 `.\scripts\Start-Work.ps1` 开始开发。

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
config/         项目版本、工程路径和发布文件配置
scripts/        工作、检查和发布脚本
releases/       GitHub Release 索引
```

## 常用命令

```powershell
.\scripts\Setup-Computer.ps1
.\scripts\Start-Work.ps1
.\scripts\New-WorkBranch.ps1 -Name feature-name
.\scripts\Save-Work.ps1
.\scripts\Check-Project.ps1
.\scripts\Publish-Release.ps1
```

发布版本采用 `vYYYY.MM.DD.N`，例如 `v2026.07.14.1`。正式 ZIP 永久保存在 GitHub Releases，仓库只保存发布索引与校验值。
