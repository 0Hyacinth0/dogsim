#!/usr/bin/env python3
# 简单的HTTP服务器，支持绑定到指定地址和端口

import http.server
import socketserver
import sys

PORT = 8888
HOST = '0.0.0.0'  # 允许外部访问

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # 添加CORS头，允许跨域访问
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

if __name__ == '__main__':
    with socketserver.TCPServer((HOST, PORT), MyHTTPRequestHandler) as httpd:
        print(f'服务器启动成功！')
        print(f'访问地址: http://localhost:{PORT}/game.html')
        print(f'外网访问: http://59.110.36.83:{PORT}/game.html')
        print('按 Ctrl+C 停止服务器')
        httpd.serve_forever()
