#!/bin/bash
# 服务器停止脚本

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

if [ ! -f "server.pid" ]; then
    echo "未找到PID文件，服务器可能没有运行"
    echo "正在搜索server.py进程..."
    
    # 尝试找到并终止server.py进程
    PID=$(ps aux | grep 'python3 server.py' | grep -v grep | awk '{print $2}')
    if [ -n "$PID" ]; then
        echo "找到服务器进程 (PID: $PID)，正在停止..."
        kill $PID
        sleep 2
        if ps -p $PID > /dev/null 2>&1; then
            echo "正常停止失败，强制终止..."
            kill -9 $PID
        fi
        echo "服务器已停止"
    else
        echo "未找到运行中的服务器"
    fi
    exit 0
fi

PID=$(cat server.pid)

if ps -p $PID > /dev/null 2>&1; then
    echo "正在停止服务器 (PID: $PID)..."
    kill $PID
    
    # 等待进程结束
    for i in {1..10}; do
        if ! ps -p $PID > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    # 如果进程仍然存在，强制终止
    if ps -p $PID > /dev/null 2>&1; then
        echo "正常停止失败，强制终止..."
        kill -9 $PID
        sleep 1
    fi
    
    echo "服务器已停止"
else
    echo "PID文件中的进程不存在，正在清理..."
fi

# 清理PID文件和日志
rm -f server.pid
echo "已清理临时文件"