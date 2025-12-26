#!/bin/bash
# 停止HTTP服务器脚本

# 检查PID文件是否存在
if [ ! -f server.pid ]; then
    echo "没有找到运行中的服务器"
    exit 1
fi

PID=$(cat server.pid)

# 检查进程是否还在运行
if ps -p $PID > /dev/null 2>&1; then
    echo "正在停止服务器 (PID: $PID)..."
    kill $PID
    
    # 等待进程结束
    for i in {1..10}; do
        if ! ps -p $PID > /dev/null 2>&1; then
            echo "✓ 服务器已停止"
            rm server.pid
            exit 0
        fi
        sleep 1
    done
    
    # 如果进程还在运行，强制终止
    echo "强制终止服务器..."
    kill -9 $PID
    rm server.pid
    echo "✓ 服务器已强制停止"
else
    echo "服务器未运行，清理PID文件"
    rm server.pid
fi
