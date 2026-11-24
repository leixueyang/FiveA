# FiveA · 小A标

把 iPhone 状态栏上的 `5G+` 显示成 `5Gᴀ`。

只在系统真的上报了 NR 载波聚合时才替换。没连上 5G-A 的地方，状态栏还是老老实实显示 `5G`。

## 它干什么

系统准备把 `5G+` 画到状态栏的时候，把这个字符串换成 `5Gᴀ`。

字符串来自 `SystemStatusUI.framework` 的本地化表，`5G+` 这一条本来是给美国运营商的毫米波标识预留的。国内没有毫米波，正常情况下永远轮不到它显示，所以才要用运营商配置文件里的 `DataIndicatorOverrideForNRMmwave` 把 NRCA 上报映射过去。

## 它不干什么

- **不改网络能力。** 速率上限取决于基站的三载波配置和你的套餐，插件碰不到这两样。
- **不是无条件替换。** 市面上有几个直接改字形的插件，只要状态栏显示 5G 就给你改成 5GA，信号格旁边一直挂着。这个不一样，要运营商真上报了才换。
- **不读文件、不写沙盒、没有设置界面。** 删掉就恢复原样。

有人装完说网速变快了，那是刷 IPCC 的效果，跟这个插件无关。归因别搞错。

## 前置条件

缺一条就不出效果。

| 项 | 要求 |
|---|---|
| 机型 | iPhone 15 Pro 系列及更新。联通 65.0.3 和移动 65.0.4 的 IPCC 里，只有 D83/D84（15 Pro 组）和 D93/D94（16 Pro 组）的 override 带 `DataIndicatorOverrideForNRMmwave`，15 / 15 Plus 那组没有 |
| 系统 | iOS 15 以上，已越狱。无根、隐根都行 |
| IPCC | 64.0 以上。实测联通 65.0.3、移动 65.0.4 |
| Overlay | `DataIndicatorOverrideForNRMmwave = NRPlus` |
| 覆盖 | 所在位置有 5G-A（三载波）。移动 n41 比联通 n78 密，同一个位置移动亮联通不亮很正常 |

iOS 18.4 之后系统自己会显示 `5G-A`，这个插件就没必要装了。18.4 之前只能走「IPCC 映射 + 换字形」这条路。

## 下载

**deb**：[FiveA_1.0.0.deb](下载地址)

是 rootless 包，隐根环境要用 RootHide Patcher 转一次，步骤在下面。

## 安装

### 1. 刷 IPCC

老版本 IPCC 不具备 5G-A 的上报条件，先升到 64.0 以上。IPCC 文件自己找，爱思助手或各家公众号都有。

电脑装爱思助手，手机连上，工具箱 → 更新 IPCC 文件 → 选择本地 IPCC → 立即更新。刷完去「设置 → 通用 → 关于本机」看运营商后面的数字变没变，没变就再刷一次，不是每次都能成。

双卡要分别刷，刷之前先重启手机回到未越狱状态，干净些。

### 2. 改 Overlay

用 Filza 打开：

```
/var/mobile/Library/Carrier Bundles/Overlay/
```

找文件名含运营商代码（联通 `46001`、移动 `46000`）且版本号跟「关于本机」对得上的 plist。可能有多个，全改。

打开后找 `DataIndicatorOverrideForNRMmwave`，把 `NRCA` 改成 `NRPlus`。没有这个键就自己加一条，类型 String。

顺手想要独立 5G 和 VoNR 开关，加这两条：

```
Show5GStandaloneSwitch = true
ShowVoNRSwitch         = true
```

改完把整个 Overlay 目录权限设成 `0555`，**记得勾「应用到子文件」**。不设这一步，重启后 CommCenter 会把 plist 写回去，白改。

用终端更省事：

```bash
chmod -R 0555 "/var/mobile/Library/Carrier Bundles/Overlay"
ls -ld "/var/mobile/Library/Carrier Bundles/Overlay"   # 看到 dr-xr-xr-x 就对了
```

下次要刷 IPCC，先改回 `0777`，否则写不进去。

### 3. 装插件

隐根环境先装 RootHide Patcher（源 `https://roothide.github.io/`），打开它 → Select .deb file → 选这个 deb → 模式保持默认 → Convert .deb → 完成后点 Sileo 安装。

装完重启用户空间。

## 怎么确认是真的

拨 `*3001#12345#*` 进 Field Test，看聚合带宽 `aggregated_dl_bw`。超过 100MHz 才算真在做载波聚合。只有图标、带宽没上去，说明那个基站只是双载波。

移动和广电的门槛比联通高：3CC 且总带宽 ≥180MHz 才给显示 5GA，电信联通是 3CC ≥130MHz 或 2CC ≥200MHz。这是终端白皮书里的口径，正好解释了为什么同一位置移动亮联通不亮。

## 卸载

Sileo 里卸掉 FiveA，重启用户空间，状态栏恢复 `5G+`。

想把 IPCC 那层也还原，Overlay 权限改回 `0777`，把 `NRPlus` 改回 `NRCA` 或者直接删掉这个键，重启。

## 遇到问题

**装完没变化。** 先确认装之前状态栏有没有出现过 `5G+`。从来没出现过，说明卡在 IPCC 或覆盖，插件救不了。出现过但没换成 `5Gᴀ`，把 `Tweak.x` 里的 `#define DEBUG_LOG` 改成 1 重新编译，Console.app 过滤 `FiveA` 看哪条 hook 在跑。

**装完进安全模式。** RootHide Patcher 转换不是万能的。这个插件不碰文件路径，转换成功率算高的，真出问题就在 Sileo 里卸掉。

**重启后失效。** 半不完美越狱重启就丢环境，重新跑一次越狱工具，插件还在。

**联通一直不亮。** 大概率是覆盖。别在这上面折腾配置。

## 自己编

源码就一个 `Tweak.x`，三条 hook 兜底，分别打 `_UIStatusBarCellularItem`、`STStatusBarDataCellularEntry` 和 `NSBundle` 的本地化查表。哪个版本走哪条不确定，都留着。

```bash
export THEOS=~/theos
git clone --recursive https://github.com/theos/theos.git $THEOS
# theos/sdks 里的 iPhoneOS SDK 放进 $THEOS/sdks
brew install ldid
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```

也可以丢 GitHub Actions 编。镜像别写 `macos-14`，2026 年 11 月已经下线了，指向它的 job 会在 0 秒被取消且没有日志，写 `macos-15`。

## 参考

改键和权限那套来自威锋的几篇老帖，动手之前值得看一遍：

- https://www.feng.com/post/13950046 —— iPhone 15 系开 5GA 教程，`DataIndicatorOverrideForNRMmwave` 和 0555 权限的出处
- https://www.feng.com/post/13896641 —— 键名全表、失败救援、刷 IPCC 前置条件
- https://www.feng.com/post/13900165 —— 挂载改字形的老办法，和本插件效果等价

## 许可

MIT。出问题自己担。刷 IPCC 和改系统文件都有风险，尤其系统已经停签的时候，出问题没法靠重装系统兜底。
