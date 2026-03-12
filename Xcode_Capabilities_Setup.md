# SafeParents - Xcode Capabilities 配置指南

## 概述
本文档说明了在 Xcode 中需要配置的 Capabilities 和设置，以便 SafeParents 应用能够正常运行。

---

## 1. App Groups Capability

**位置**: Signing & Capabilities → App Groups

**配置步骤**:
1. 在 Xcode 中选择项目导航器中的项目文件
2. 选择 `safeparents` Target
3. 点击 `Signing & Capabilities` 标签页
4. 点击 `+ Capability` 按钮
5. 搜索并双击 `App Groups`
6. 点击 `+` 按钮添加新的 App Group
7. 输入 Identifier: `group.com.safeparents.app`
8. 点击 OK

**重要说明**:
- App Group ID 必须与代码中 `AppConstants.AppGroup.identifier` 保持一致
- 格式必须是 `group.` 开头，后面跟你的 Bundle ID（或类似格式）
- 如果你的 Bundle ID 不同，需要修改 `AppConstants.swift` 中的值

---

## 2. CloudKit (iCloud) Capability

**位置**: Signing & Capabilities → iCloud

**配置步骤**:
1. 在 `Signing & Capabilities` 标签页
2. 点击 `+ Capability` 按钮
3. 搜索并双击 `iCloud`
4. 在 iCloud 部分:
   - 勾选 `CloudKit`
   - 点击 `+` 按钮添加容器
   - 容器名称: `iCloud.com.safeparents.app`（或使用默认容器）

**重要说明**:
- CloudKit 需要 Apple Developer 付费账号
- 容器名称需要与 `AppConstants.CloudKit.containerIdentifier` 保持一致
- 如果使用模拟器测试，CloudKit 功能可能受限

---

## 3. Push Notifications Capability

**位置**: Signing & Capabilities → Push Notifications

**配置步骤**:
1. 在 `Signing & Capabilities` 标签页
2. 点击 `+ Capability` 按钮
3. 搜索并双击 `Push Notifications`

**重要说明**:
- 推送通知功能需要真实的 Apple Developer 账号
- 模拟器不支持推送通知测试，需要真机测试

---

## 4. Background Modes Capability

**位置**: Signing & Capabilities → Background Modes

**配置步骤**:
1. 在 `Signing & Capabilities` 标签页
2. 点击 `+ Capability` 按钮
3. 搜索并双击 `Background Modes`
4. 勾选以下选项:
   - ✅ Background fetch
   - ✅ Remote notifications
   - ✅ Background processing（如果可用）

---

## 5. Notification Configuration (Info.plist)

**位置**: Info 标签页

**配置步骤**:
1. 选择 `Info` 标签页
2. 添加以下键值:

| Key | Type | Value |
|-----|------|-------|
| UIBackgroundModes | Array | fetch, remote-notification |
| NSUserNotificationsUsageDescription | String | SafeParents needs to send you check-in reminders and family status updates. |

---

## 6. Widget Extension Configuration

如果你需要配置 Widget Extension:

### 6.1 为 Widget Target 添加 App Groups
1. 选择 `SafeParentsWidget` Target
2. 在 `Signing & Capabilities` 标签页
3. 添加 `App Groups` Capability
4. 添加相同的 App Group ID: `group.com.safeparents.app`

### 6.2 确保 Widget 和主应用使用相同的 App Group
- 主应用和 Widget 必须使用相同的 App Group ID 才能共享数据
- Widget 通过 App Group 的 UserDefaults 读取主应用的数据

---

## 7. 完整配置清单

### 主应用 (safeparents Target)
- [x] App Groups: `group.com.safeparents.app`
- [x] iCloud (CloudKit): `iCloud.com.safeparents.app`
- [x] Push Notifications
- [x] Background Modes: fetch, remote-notification

### Widget Extension (SafeParentsWidget Target)
- [x] App Groups: `group.com.safeparents.app`

---

## 8. 常见问题

### Q: 编译时提示 "Failed to provision App Group"
**A**: 确保:
1. 你的 Apple Developer 账号有权限创建 App Groups
2. App Group ID 格式正确（以 `group.` 开头）
3. 在 Apple Developer Portal 中也创建了对应的 App Group

### Q: CloudKit 同步不工作
**A**: 检查:
1. 是否在真机上测试（模拟器 CloudKit 功能有限）
2. 用户是否登录了 iCloud 账户
3. 容器 ID 是否正确配置

### Q: Widget 不显示数据
**A**: 确保:
1. 主应用和 Widget 使用相同的 App Group ID
2. 主应用已经正确写入数据到 App Group UserDefaults
3. Widget 的 TimelineProvider 正确读取数据

---

## 9. 代码中需要修改的地方

如果你的 Bundle ID 与默认不同，请修改以下文件:

### AppConstants.swift
```swift
struct AppConstants {
    struct CloudKit {
        static let containerIdentifier: String = "iCloud.你的BundleID"
    }

    struct AppGroup {
        static let identifier = "group.你的BundleID"
        // ...
    }
}
```

---

## 10. 测试建议

1. **模拟器测试**:
   - 大部分功能可以在模拟器上测试
   - CloudKit 和推送通知需要真机测试

2. **真机测试**:
   - 需要配置真实的 Apple Developer 账号
   - 需要在真机上测试推送通知和 CloudKit 同步

3. **Widget 测试**:
   - 添加 Widget 到主屏幕
   - 在主应用中创建 Check-in
   - 检查 Widget 是否更新显示

---

## 联系支持

如有问题，请检查:
1. Xcode 版本是否为最新
2. iOS 部署目标是否为 17.0+
3. Apple Developer 账号状态是否正常
