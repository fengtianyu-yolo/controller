from zeroconf import ServiceInfo, Zeroconf
import socket

# 获取本机 IP
ip_address = socket.gethostbyname(socket.gethostname())
print(ip_address)

# 创建服务信息
service_info = ServiceInfo(
    "_http._tcp.local.",
    "小困子的iMac._http._tcp.local.",
    addresses=[socket.inet_aton(ip_address)],
    port=8080,
    properties={},
)

# 启动 Bonjour 广播
zeroconf = Zeroconf()
zeroconf.register_service(service_info)
print(f"Bonjour 服务已启动: {ip_address}:8080")

try:
    input("按 Enter 退出...\n")
finally:
    zeroconf.unregister_service(service_info)
    zeroconf.close()

