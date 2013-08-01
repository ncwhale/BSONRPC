用于监听网络连接，并同时将到来的socket绑定session，并Kick session start.

    rpc = require './bson_rpc'
    split = require './bson_split'
    net = require 'net'
    log = require '../log'
    id = require './inside_identity'

    class TcpServer
      constructor: (options = {}) ->
        @listen_port = options.port ? 42757
        @listen_bind = options.host ? '0.0.0.0'

      run: () ->
        @server = net.createServer (socket)=>
          log "连接到来:",socket.address()
          spliter = new split.net_adapter socket
          session = new rpc 0, spliter

          #发送一个连接成功的Event给连接端
          session.emit_event 'RPC.CONNECTED',
            message:'连接成功'
            server_id: id
          
        @server.on 'error', (err) ->
          log "服务端出错：", err

        @server.listen @listen_port, @listen_bind, =>
          log "服务端开始监听：#{@listen_bind}:#{@listen_port}"

导出TCP服务器模块
  
    module.exports = TcpServer
