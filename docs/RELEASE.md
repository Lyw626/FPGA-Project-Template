# Release Workflow

1. 在 Vivado GUI 中完成综合、实现和 bitstream 生成。
2. 更新 cfg 模块中的版本日期寄存器。
3. 完成板上功能验证。
4. 检查 `project-control/config/release-files.json` 中的产物路径。
5. 运行发布脚本：

```powershell
.\project-control\scripts\Publish-Release.ps1
```

脚本检查时序、DRC、布线状态和产物，自动创建 `vYYYY.MM.DD.N` 标签、ZIP、校验值、发布索引和 GitHub Release。
