# Codex 项目交接：MATLAB V1.3 → V1.4

项目已按可直接编辑的文件树上传，而不是仅提供压缩包。

- 阅读 [AGENTS.md](AGENTS.md) 获取工作约束。
- 阅读 [V1.4 开发任务书](Codex_地震正演观测系统优化_V1.4_任务书.md) 获取全部需求与验收标准。
- V1.3 原始 MATLAB 源码位于 [matlab_survey_fd_v1_3/](matlab_survey_fd_v1_3/)。
- 原工程的 `figures/complex_velocity_model_reference.png` 是可再生成的参考图，未上传；不影响 MATLAB 源码与运行入口。
- 保留 V1.3 作为基线。建议 Codex 新建 `codex/v1.4-dev` 分支开发，提交 V1.4 的完整源码、测试、文档和运行说明。
- MATLAB R2025b 优先；若执行环境没有 MATLAB，请区分静态审查与实机测试，避免虚报。

注意：当前仓库中的 V1.3 是待修正基线，不是已实现 V1.4 的最终工程。