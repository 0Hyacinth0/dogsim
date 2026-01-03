#!/bin/bash
# 服务器启动脚本

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# 检查是否已经在运行
if [ -f "server.pid" ]; then
    PID=$(cat server.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "服务器已经在运行中 (PID: $PID)"
        echo "如需重启，请先运行 ./stop_server.sh"
        exit 1
    else
        echo "清理过期的PID文件..."
        rm -f server.pid
    fi
fi

echo "启动游戏服务器..."
echo "使用 Ctrl+C 可以停止服务器"
echo "如果需要在后台运行，请使用 ./start_server_bg.sh"
echo ""

# 启动服务器并保存PID
python3 server.py &
SERVER_PID=$!
echo $SERVER_PID > server.pid

echo "服务器已启动 (PID: $SERVER_PID)"
echo "访问地址: http://localhost:8888/game.html"
echo "PID已保存到 server.pid 文件"

# 等待进程结束
wait $SERVER_PID

# 清理PID文件
rm -f server.pid
echo "服务器已停止"