#!/bin/bash
# 后台服务器启动脚本

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# 检查是否已经在运行
if [ -f "server.pid" ]; then
    PID=$(cat server.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "服务器已经在后台运行中 (PID: $PID)"
        echo "如需重启，请先运行 ./stop_server.sh"
        exit 1
    else
        echo "清理过期的PID文件..."
        rm -f server.pid
    fi
fi

echo "在后台启动游戏服务器..."

# 后台启动服务器并保存PID
nohup python3 server.py > server.log 2>&1 &
SERVER_PID=$!
echo $SERVER_PID > server.pid

echo "服务器已在后台启动 (PID: $SERVER_PID)"
echo "访问地址: http://localhost:8888/game.html"
echo "日志文件: server.log"
echo "PID已保存到 server.pid 文件"

# 等待一下确保服务器启动
sleep 2

# 检查服务器是否正常运行
if ps -p $SERVER_PID > /dev/null 2>&1; then
    echo "服务器启动成功！"
else
    echo "服务器启动失败，请检查日志文件: server.log"
    rm -f server.pid
    exit 1
fi