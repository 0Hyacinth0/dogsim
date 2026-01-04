#!/bin/bash
# 增强版服务器启动脚本 - 带自动重启功能

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# 配置参数
MAX_RESTART_ATTEMPTS=3
HEALTH_CHECK_INTERVAL=30
SERVER_PORT=8888
LOG_FILE="auto_server.log"

# 函数：记录日志
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 函数：检查端口是否可用
check_port() {
    if lsof -i :$SERVER_PORT > /dev/null 2>&1; then
        return 1  # 端口被占用
    else
        return 0  # 端口可用
    fi
}

# 函数：等待端口就绪
wait_for_port() {
    local port=$1
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if lsof -i :$port > /dev/null 2>&1; then
            log_message "端口 $port 已就绪"
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    
    log_message "等待端口 $port 超时"
    return 1
}

# 函数：启动服务器
start_server() {
    log_message "启动游戏服务器..."
    
    # 检查端口是否可用
    if ! check_port; then
        log_message "错误：端口 $SERVER_PORT 已被占用"
        return 1
    fi
    
    # 后台启动服务器
    nohup python3 server.py > server_output.log 2>&1 &
    SERVER_PID=$!
    echo $SERVER_PID > server.pid
    
    log_message "服务器启动进程 PID: $SERVER_PID"
    
    # 等待端口就绪
    if wait_for_port $SERVER_PORT; then
        log_message "服务器启动成功！"
        return 0
    else
        log_message "服务器启动失败"
        kill $SERVER_PID 2>/dev/null
        rm -f server.pid
        return 1
    fi
}

# 函数：检查服务器健康状态
check_health() {
    if [ ! -f "server.pid" ]; then
        return 1  # 无PID文件
    fi
    
    local pid=$(cat server.pid)
    
    if ! ps -p $pid > /dev/null 2>&1; then
        return 1  # 进程不存在
    fi
    
    # 检查端口是否监听
    if ! lsof -i :$SERVER_PORT > /dev/null 2>&1; then
        return 1  # 端口未监听
    fi
    
    return 0  # 健康状态良好
}

# 函数：停止服务器
stop_server() {
    if [ -f "server.pid" ]; then
        local pid=$(cat server.pid)
        log_message "正在停止服务器 (PID: $pid)..."
        
        if ps -p $pid > /dev/null 2>&1; then
            kill $pid
            sleep 2
            
            # 强制终止如果还在运行
            if ps -p $pid > /dev/null 2>&1; then
                kill -9 $pid
            fi
        fi
        
        rm -f server.pid
        log_message "服务器已停止"
    fi
}

# 函数：自动重启循环
auto_restart_loop() {
    local restart_count=0
    
    log_message "启动自动重启监控模式"
    log_message "配置：最大重启次数=$MAX_RESTART_ATTEMPTS，健康检查间隔=${HEALTH_CHECK_INTERVAL}秒"
    
    while [ $restart_count -lt $MAX_RESTART_ATTEMPTS ]; do
        if start_server; then
            restart_count=0  # 重置重启计数
            
            # 监控循环
            while check_health; do
                sleep $HEALTH_CHECK_INTERVAL
            done
            
            log_message "检测到服务器异常停止，准备重启..."
            stop_server
            restart_count=$((restart_count + 1))
            
            if [ $restart_count -lt $MAX_RESTART_ATTEMPTS ]; then
                log_message "第 $restart_count 次重启，5秒后重新启动..."
                sleep 5
            else
                log_message "达到最大重启次数，停止自动重启"
                break
            fi
        else
            log_message "启动失败，30秒后重试..."
            sleep 30
            restart_count=$((restart_count + 1))
        fi
    done
}

# 主程序逻辑
case "${1:-start}" in
    "start")
        log_message "=== 启动增强版游戏服务器 ==="
        if auto_restart_loop; then
            log_message "服务器运行完成"
        else
            log_message "服务器启动失败或达到重启限制"
            exit 1
        fi
        ;;
    "stop")
        log_message "=== 停止服务器 ==="
        stop_server
        ;;
    "status")
        log_message "=== 检查服务器状态 ==="
        if check_health; then
            log_message "✅ 服务器运行正常"
            if [ -f "server.pid" ]; then
                pid=$(cat server.pid)
                ps -p $pid -o pid,ppid,cmd,etime,pcpu,pmem
            fi
        else
            log_message "❌ 服务器未运行或异常"
        fi
        ;;
    "restart")
        log_message "=== 重启服务器 ==="
        stop_server
        sleep 2
        auto_restart_loop
        ;;
    *)
        echo "用法: $0 {start|stop|status|restart}"
        echo "  start  - 启动服务器（带自动重启监控）"
        echo "  stop   - 停止服务器"
        echo "  status - 检查服务器状态"
        echo "  restart- 重启服务器"
        exit 1
        ;;
esac