  # BSON 流切割、写入模块，用于从流数据中取得BSON数据转换为JS对象并发出，同时接收JS对象并转换为BSON回写给流

加载必要的系统组件

    events = require 'events'
    BSON = (require 'mongodb').BSON
    log = require '../log'

    class BSON_Spliter extends events.EventEmitter
      constructor: (stream_in, stream_out, args) ->
        # 输入参数
        # 1.监听 steam 的 'data' 事件，读取输入数据流(Sockets一般，当然也可能是FileStream等)
        # 2.Out:输出数据流(Sockets的话，一般输出是其本身，FileStream的话，应该是回复数据文件)
        @listen stream_in if stream_in?
        @join stream_out if stream_out?

        # 生成事件
        # 1.BSON到来事件 -> emit "BSON_IN", BSON_Data
        # 2.BSON事件监听 -> on "BSON_OUT", BSON_Data
        # 3.error -> 出错，比如steam出错等
        # 调试，输出所有返回BSON内容
        @on 'BSON_OUT', (doc) =>
          log '发送BSON对象', doc

可以多路监听，因为每个 listen 后都会生成一个单独的分割函数！

      listen: (s_in) =>
        read_buffer = new Buffer 0
        bson_listen_callback = (data) =>
          read_buffer = Buffer.concat [read_buffer, data]
          while read_buffer.length > 4 #还包括BSON数据头则可以预见处理
            bson_len = read_buffer.readUInt32LE 0
            #log "收到BSON头:#{bson_len}"
            return if bson_len > read_buffer.length
            bson_buf = read_buffer.slice 0, bson_len
            bson_doc = BSON.deserialize bson_buf
            log "收到BSON对象", bson_doc
            @emit 'BSON_IN', bson_doc
            read_buffer = read_buffer.slice bson_len, read_buffer.length
        
        s_in.on 'data', bson_listen_callback

        s_in.once 'end', () =>
          log '读取流结束'
          s_in.removeListener 'data', bson_listen_callback
          #@emit 'end',
          #  'message': '流输入完毕'

        s_in.once 'error', (err...) =>
          log '读取流断开' #, err, s_in.bson_listen_callback
          s_in.removeListener 'data', bson_listen_callback
          #@emit 'error',
          #  'message': '监听输入流出错'
          #  #'error' : err ? {}

          
同样可以多路out，只要在事件到来前初始化好多路out的连接

      join: (out) =>
        bson_write_callback = (doc) =>
          out.write BSON.serialize(doc)
        
        @on 'BSON_OUT', bson_write_callback

        out.once 'end', () =>
          log '写入流结束'
          @removeListener 'BSON_OUT', bson_write_callback 
  
        out.once 'error', (err...) =>
          log '写入流出错' #, err, out.bson_write_callback
          @removeListener 'BSON_OUT', bson_write_callback 
          #@emit 'error',
            #'message': '输出流出错'
            #'error': err ? {}


      send: (obj) =>
        @emit 'BSON_OUT', obj

输出模块

    module.exports = BSON_Spliter
    module.exports.net_adapter = (socket) ->
       s = new BSON_Spliter socket, socket
