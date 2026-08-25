# AWAvenue-Ads-Rule-srs

自动跟踪 [AWAvenue-Ads-Rule](https://github.com/TG-Twilight/AWAvenue-Ads-Rule) 上游的 sing-box 规则源，并编译为 `.srs` 二进制规则集。

- ⏱ 每 6 小时自动同步一次上游（也可在 Actions 页面手动触发）
- 🛠 始终使用**最新 sing-box pre-release** 版本编译
- 🔍 每次同步的 commit message 中带有上游 commit SHA，可溯源

## 可用规则

| 文件 | 说明 |
|---|---|
| [`srs/AWAvenue-Ads-Rule.srs`](srs/AWAvenue-Ads-Rule.srs) | 主规则集（上游默认版本） |
| [`srs/AWAvenue-Ads-Rule-Only.Ads.srs`](srs/AWAvenue-Ads-Rule-Only.Ads.srs) | 仅含广告规则 |
| [`srs/AWAvenue-Ads-Rule-No.Privacy.srs`](srs/AWAvenue-Ads-Rule-No.Privacy.srs) | 去隐私类变体 |
| [`srs/AWAvenue-Ads-Rule-No.Unwelcome.srs`](srs/AWAvenue-Ads-Rule-No.Unwelcome.srs) | 去 Unwelcome 变体 |

各变体的具体差异见[上游仓库](https://github.com/TG-Twilight/AWAvenue-Ads-Rule/tree/main/Filters)。

## 使用方法

以 sing-box 配置为例（`<OWNER>` 替换为本仓库所有者）：

```json
{
  "route": {
    "rule_set": [
      {
        "tag": "AWAvenue-Ads-Rule",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/qlenlen/AWAvenue-Ads-Rule-srs/main/srs/AWAvenue-Ads-Rule.srs",
        "download_detour": "direct"
      }
    ],
    "rules": [
      {
        "rule_set": ["AWAvenue-Ads-Rule"],
        "outbound": "block"
      }
    ]
  }
}
```

也可以使用 jsDelivr 镜像加速（有约 24 小时缓存）：

```text
https://cdn.jsdelivr.net/gh/qlenlen/AWAvenue-Ads-Rule-srs@main/srs/AWAvenue-Ads-Rule.srs
```

## 兼容性提示

`.srs` 由**最新 pre-release 版本**的 sing-box 编译。如果你的客户端加载失败或提示版本不支持，请升级 sing-box 至较新版本。

## 许可与致谢

规则内容全部来自 [TG-Twilight/AWAvenue-Ads-Rule](https://github.com/TG-Twilight/AWAvenue-Ads-Rule)（GPL-3.0），本仓库仅做格式转换与分发，同样以 GPL-3.0 发布。感谢上游维护者。
