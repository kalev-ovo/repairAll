# 家政维修服务平台

Flutter 单 App 双角色（用户端 + 师傅端）+ Go 轻量后端。

## 技术栈

| 层 | 技术 |
|---|------|
| App | Flutter 3.x + Dart, Riverpod, go_router |
| 后端 | Go + Gin, SQLite (WAL) |
| IM | WebSocket |
| 管理 | 内置 CLI (`./repair admin`) |

## 项目结构

```
repairAll/
├── repair_server/     # Go 后端
│   ├── cmd/server/    # API 服务入口
│   ├── cmd/admin/     # CLI 管理工具
│   └── internal/      # 内部包
├── repair_app/        # Flutter App
│   └── lib/
│       ├── core/      # 基础设施
│       ├── features/  # 功能模块
│       └── router/    # 路由
└── README.md
```

## 快速开始

### 后端

```bash
cd repair_server
go build -o repair .
./repair server --port 8080
```

API 地址: `http://localhost:8080/api/v1`

### CLI 管理

```bash
./repair admin category list        # 查看类目
./repair admin user list            # 用户列表
./repair admin worker verify <id>   # 审核师傅
./repair admin order list           # 订单列表
./repair admin stats                # 统计
```

### Flutter App

```bash
cd repair_app
flutter pub get
flutter run
```

开发验证码: `123456`

## 部署

```bash
bash repair_server/deploy/deploy.sh
```

## API 概览

- `POST /api/v1/auth/send-code` — 发送验证码
- `POST /api/v1/auth/register` — 注册
- `POST /api/v1/auth/login` — 登录
- `GET /api/v1/categories` — 服务类目
- `POST /api/v1/orders` — 发布订单
- `GET /api/v1/orders?type=hall` — 接单大厅
- `PUT /api/v1/orders/:id/accept` — 接单
- `PUT /api/v1/orders/:id/complete` — 完成
- `GET /api/v1/ws/chat` — WebSocket 聊天
- `POST /api/v1/reviews` — 评价
