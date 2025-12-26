#!/bin/bash
# 后台启动HTTP服务器脚本

# 检查是否已经有进程在运行
if [ -f server.pid ]; then
    PID=$(cat server.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "服务器已经在运行中 (PID: $PID)"
        echo "访问地址: http://localhost:8888/game.html"
        exit 1
    else
        echo "发现旧的PID文件，正在清理..."
        rm server.pid
    fi
fi

# 启动服务器并记录PID
nohup python3 server.py > server.log 2>&1 &
echo $! > server.pid

# 等待服务器启动
sleep 1

# 检查是否启动成功
if ps -p $(cat server.pid) > /dev/null 2>&1; then
    echo "✓ 服务器启动成功！"
    echo "PID: $(cat server.pid)"
    echo "本地访问: http://localhost:8888/game.html"
    echo "外网访问: http://59.110.36.83:8888/game.html"
    echo "日志文件: server.log"
else
    echo "✗ 服务器启动失败"
    rm server.pid
    exit 1
fi
