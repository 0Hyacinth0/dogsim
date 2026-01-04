#!/bin/bash
# 服务器健康检查和简单监控脚本

# 配置
SERVER_PORT=8888
CHECK_INTERVAL=10  # 检查间隔（秒）
MAX_FAILURES=3     # 最大连续失败次数

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 函数：检查端口
check_port() {
    if lsof -i :$SERVER_PORT > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 函数：检查进程
check_process() {
    if [ -f "server.pid" ]; then
        local pid=$(cat server.pid)
        if ps -p $pid > /dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# 函数：测试HTTP响应
test_http() {
    if curl -s --connect-timeout 5 "http://localhost:$SERVER_PORT/game.html" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 函数：生成状态报告
generate_report() {
    local status=$1
    local failure_count=$2
    
    echo "=== 服务器健康检查报告 ==="
    echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "服务器状态: $status"
    
    if [ $failure_count -gt 0 ]; then
        echo "连续失败次数: $failure_count"
    fi
    
    # 进程信息
    if check_process; then
        echo -e "进程状态: ${GREEN}✅ 运行中${NC}"
        if [ -f "server.pid" ]; then
            local pid=$(cat server.pid)
            echo "进程PID: $pid"
            ps -p $pid -o pid,ppid,etime,pcpu,pmem
        fi
    else
        echo -e "进程状态: ${RED}❌ 未运行${NC}"
    fi
    
    # 端口状态
    if check_port; then
        echo -e "端口状态: ${GREEN}✅ $SERVER_PORT端口正在监听${NC}"
        lsof -i :$SERVER_PORT
    else
        echo -e "端口状态: ${RED}❌ $SERVER_PORT端口未监听${NC}"
    fi
    
    # HTTP测试
    if test_http; then
        echo -e "HTTP响应: ${GREEN}✅ 正常${NC}"
    else
        echo -e "HTTP响应: ${RED}❌ 异常${NC}"
    fi
    
    echo ""
}

# 函数：监控模式
monitor_mode() {
    local failure_count=0
    local start_time=$(date +%s)
    
    echo "开始监控服务器 (间隔: ${CHECK_INTERVAL}秒)"
    echo "按 Ctrl+C 停止监控"
    echo ""
    
    while true; do
        local current_time=$(date +%s)
        local run_duration=$((current_time - start_time))
        
        # 检查服务器状态
        if check_process && check_port && test_http; then
            if [ $failure_count -gt 0 ]; then
                echo -e "$(date '+%H:%M:%S') - ${GREEN}✅ 服务器恢复正常${NC}"
                failure_count=0
            else
                echo -e "$(date '+%H:%M:%S') - ${GREEN}✅ 运行正常${NC} (运行时间: ${run_duration}秒)"
            fi
        else
            failure_count=$((failure_count + 1))
            echo -e "$(date '+%H:%M:%S') - ${RED}❌ 检测到问题 (失败 #$failure_count)${NC}"
            
            if [ $failure_count -ge $MAX_FAILURES ]; then
                echo -e "${RED}连续失败 $MAX_FAILURES 次，生成详细报告${NC}"
                generate_report "❌ 异常" $failure_count
                
                echo -e "${YELLOW}是否尝试重启服务器？(y/n)${NC}"
                read -r response
                if [[ "$response" =~ ^[Yy]$ ]]; then
                    echo "尝试重启服务器..."
                    if [ -f "./stop_server.sh" ]; then
                        ./stop_server.sh > /dev/null 2>&1
                    fi
                    sleep 2
                    if [ -f "./start_server_bg.sh" ]; then
                        ./start_server_bg.sh > /dev/null 2>&1
                        sleep 5
                        if check_process && check_port; then
                            echo -e "${GREEN}重启成功！${NC}"
                            failure_count=0
                            start_time=$(date +%s)
                        else
                            echo -e "${RED}重启失败${NC}"
                        fi
                    fi
                fi
                
                # 重置失败计数
                failure_count=0
            fi
        fi
        
        sleep $CHECK_INTERVAL
    done
}

# 主程序
case "${1:-check}" in
    "check")
        generate_report "状态检查" 0
        ;;
    "monitor")
        monitor_mode
        ;;
    "test")
        echo "=== 快速测试 ==="
        echo -n "进程检查: "
        if check_process; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌${NC}"
        fi
        
        echo -n "端口检查: "
        if check_port; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌${NC}"
        fi
        
        echo -n "HTTP测试: "
        if test_http; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌${NC}"
        fi
        ;;
    *)
        echo "用法: $0 {check|monitor|test}"
        echo "  check   - 生成详细状态报告"
        echo "  monitor - 持续监控模式"
        echo "  test    - 快速测试所有检查项"
        exit 1
        ;;
esac