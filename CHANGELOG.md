# Changelog

## v1.4.2-rc.1 (2026-11-13)

- 全局标点符号统一为英文半角
- 升级全部依赖链并升级 Go 工具链到 1.27.4, govulncheck 符号级扫描可达漏洞 2 -> 0
- github.com/google/nftables v0.1.0 -> v0.3.0, 修复 IP 地址字节序编码错误 (GO-2024-2977)
- golang.org/x/net v0.22.0 -> v0.62.0, 修复 HTTP/1 MaxBytesReader 竞态崩溃 (GO-2026-6859)
- 将模块路径, 源码导入和文档链接中的仓库地址统一迁移到 git.ovh.im/yeqing
