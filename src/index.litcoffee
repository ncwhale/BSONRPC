RPC 平台启动模块
加载必要组件

    log = require './log'
    rpc = require './net_tcp_server'

导出函数，只有一个 run，通过输入config来声明地址和端口等

    module.exports.run = (config)->
        rpc_server = new rpc(config)
        rpc_server.run()
          
