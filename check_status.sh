#!/bin/bash
# 服务器状态检查脚本

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

echo "=== 游戏服务器状态检查 ==="
echo ""

# 检查PID文件
if [ -f "server.pid" ]; then
    PID=$(cat server.pid)
    echo "PID文件存在: $PID"
    
    if ps -p $PID > /dev/null 2>&1; then
        echo "服务器状态: ✅ 运行中"
        echo "进程信息:"
        ps -p $PID -o pid,ppid,cmd,etime,pcpu,pmem
        
        # 检查端口监听
        if lsof -i :8888 > /dev/null 2>&1; then
            echo "端口状态: ✅ 8888端口正在监听"
            lsof -i :8888
        else
            echo "端口状态: ❌ 8888端口未监听"
        fi
    else
        echo "服务器状态: ❌ 进程不存在"
        echo "PID文件过时，正在清理..."
        rm -f server.pid
    fi
else
    echo "PID文件: ❌ 不存在"
    echo "正在搜索server.py进程..."
    
    PID=$(ps aux | grep 'python3 server.py' | grep -v grep | awk '{print $2}')
    if [ -n "$PID" ]; then
        echo "找到服务器进程: $PID"
        echo "进程信息:"
        ps -p $PID -o pid,ppid,cmd,etime,pcpu,pmem
        
        if lsof -i :8888 > /dev/null 2>&1; then
            echo "端口状态: ✅ 8888端口正在监听"
        else
            echo "端口状态: ❌ 8888端口未监听"
        fi
    else
        echo "服务器状态: ❌ 未运行"
    fi
fi

echo ""
echo "=== 服务器访问地址 ==="
echo "本地访问: http://localhost:8888/game.html"
echo "外网访问: http://59.110.36.83:8888/game.html"

# 检查日志文件
if [ -f "server.log" ]; then
    echo ""
    echo "=== 最近10行日志 ==="
    tail -n 10 server.log
fi