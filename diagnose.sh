#!/bin/bash
# 服务器诊断和故障排查脚本

echo "=== 服务器故障诊断 ==="
echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. 检查系统资源
echo "=== 系统资源检查 ==="
echo "CPU使用率:"
top -l 1 | grep "CPU usage" || echo "无法获取CPU信息"

echo ""
echo "内存使用情况:"
free -h 2>/dev/null || vm_stat | grep "Pages free\|Pages active"

echo ""
echo "磁盘空间:"
df -h . | tail -1

echo ""

# 2. 检查网络连接
echo "=== 网络连接检查 ==="
echo "活跃网络连接:"
netstat -an | grep :8888 || echo "无8888端口相关连接"

echo ""

# 3. 检查Python环境
echo "=== Python环境检查 ==="
echo "Python版本:"
python3 --version

echo "当前Python进程:"
ps aux | grep python | grep -v grep

echo ""

# 4. 检查文件权限
echo "=== 文件权限检查 ==="
echo "server.py权限:"
ls -la server.py

echo "脚本目录权限:"
ls -ld .

echo ""

# 5. 检查依赖项
echo "=== 依赖项检查 ==="
echo "检查http.server模块:"
python3 -c "import http.server; print('http.server: OK')" 2>&1

echo "检查socketserver模块:"
python3 -c "import socketserver; print('socketserver: OK')" 2>&1

echo ""

# 6. 尝试手动启动并捕获错误
echo "=== 手动启动测试 ==="
echo "尝试手动启动服务器..."

# 设置较短的超时时间进行测试
timeout 10s python3 server.py 2>&1 &
TEST_PID=$!

sleep 3

# 检查是否成功启动
if lsof -i :8888 > /dev/null 2>&1; then
    echo "✅ 手动启动测试成功"
    
    # 停止测试进程
    kill $TEST_PID 2>/dev/null
    wait $TEST_PID 2>/dev/null
    
    echo "正在停止测试进程..."
else
    echo "❌ 手动启动测试失败"
    if ps -p $TEST_PID > /dev/null 2>&1; then
        kill $TEST_PID 2>/dev/null
    fi
fi

echo ""

# 7. 分析最近的日志
echo "=== 日志分析 ==="
if [ -f "server.log" ]; then
    echo "最近的日志条目:"
    tail -20 server.log
else
    echo "无server.log文件"
fi

if [ -f "server_output.log" ]; then
    echo ""
    echo "最近的服务器输出:"
    tail -20 server_output.log
fi

echo ""

# 8. 生成建议
echo "=== 诊断建议 ==="
echo "如果服务器无法启动，可能的原因："
echo "1. 端口8888被其他进程占用"
echo "2. Python环境问题或模块缺失"
echo "3. 文件权限问题"
echo "4. 系统资源不足"
echo "5. 网络配置问题"
echo ""
echo "建议解决方案："
echo "1. 运行 './auto_server.sh start' 启动带监控的服务器"
echo "2. 运行 './health_monitor.sh monitor' 进行实时监控"
echo "3. 检查系统资源使用情况"