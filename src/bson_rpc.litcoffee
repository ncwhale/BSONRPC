# BSON RPC 的主要引导文件,用来自动载入被请求模块并执行相关操作；

* 所有的模块都设计按照 源代码\设备名称\模块名称 这样的目录进行存储；
* 模块的功能可以放到一个模块文件中，也可以单独以模块名称为目录，单独为每个功能提供一个模块文件；
* SYS 定义了RPC所有相关的服务模块
* LU 定义了LU设备相关模块
* LY 定义了LY设备相关模块

## 定义 RPC Session class，每个Session都只是单独针对某个会话进行管理，会话终止即消除

    log = require './log'

    class BSON_RPC_Session
      constructor: (@id, @bson_spliter, options...) ->
        # @id 是针对当前会话的ID，由管理器提供，标记唯一Session
        #
        # @bson_spliter 处理bson收发接口
        @bson_spliter.on 'BSON_IN', (bson) =>
          return if !bson? or typeof bson isnt 'object'
          switch
            when bson.method? and bson.param? and bson.id?
              @on_method bson.method, bson.param, bson.id
            when bson.method? and bson.param?
              @on_method bson.method, bson.param
            when bson.method?
              @on_method bson.method
            when bson.id?
              @on_result bson
            when bson.event?
              @on_event bson
          return
          
        # options Session相关设置
        
        # 设置一个默认的权限表，使得登录能够默认进行
        @permissions = [ 'SYS.AUTH.*' ]
        @user = 'GUEST' #默认账号名称，TODO:由options 输入合适的值
        @function_list = {}
        @model_rev_path = options.model_path ? "../../RPC"
        @model_max_name_parts = 10

## 权限检查，目前这是一个预留的空函数，所有检查都将返回有效

      check_permission: (permission) ->
        # 假权限检查，直接返回true使得所有功能直接可用
        # 真实应该在初始化的时候进行 @check_Permission = require './SYS/check_permission'
        true

## 载入模块，根据模块名称使用正则表达式和require来尝试载入模块，在权限检查之后进行

      load_module: (method) =>
        # 返回的是确定的Module下的某个确定Method
        # 加速缓存函数,如果一个函数已经缓存则直接调取缓存函数
        return @function_list[method] if @function_list[method]?
        
        # 正则验证该请求是否正确
        #/^[\w+\.]+/ .test method
        if not /^([A-Za-z]+\.)+[A-Za-z]+$/.test method
          return (param, id) =>
            log "非法模块名称: #{@id}:@{method}"
            @do_result {
              'id': id
              'error':
                'code': -32600 #Invalid Request
                'message':"无效的方法名称"
            } if id?

        # 切分模块名称，尝试加载
        sp = method.split '.'
        
        # 如果请求模块名称过长，则有可能是恶意请求，在此进行处理
        # TODO:消除这个MagicNumber 系统.模块.子模块.方法
        if sp.length >  10
          return (param, id) =>
            log "非法模块名称: #{@id}:#{method}"
            @do_result {
              'id': id
              'error':
                'code': -32600 #Invlid Request
                'message': '无效的方法名称'
            } if id?
        
        # 尝试加载对应函数
        # 循环遍历 sp 数组，尝试用 require 来加载
        for i in [1..sp.length]
          mod_path = "#{@model_rev_path}/#{sp[0..sp.length-i].join '/'}"
          try
            mod = require mod_path
            func = mod "#{sp[sp.length-i..sp.length].join '.'}", this if mod?
            continue if !method?
            return @function_list[method] = func            
          catch error
            continue
        
        # 加载失败返回函数，将在调用中自动返回调用失败并记录日志
        (param, id) =>
          log "加载模块失败：#{@id}:#{method}", param
          @do_result {
            'id': id
            'error':
              'code': -32601 #Method not found
              'message': '没有找到方法'
          } if id?
          
## 收到接口调用请求
注意登录也是在本接口调用的，所以需要注意不要让登录函数无法通过最初校验.
另外，登陆模块可能需要替换本session的相关设定和权限校验函数

      on_method: (method, param, id) =>
        # 收到method请求，处理只有一句话……
        #log "收到请求:#{method}", param, id
        @load_module(method)(param, id) #if @check_permission(method)

      do_result: (result) =>
        # 检查数据发送回去
        #log "返回结果:", result
        @bson_spliter.send result if result? and result.id? and (result.result? or result.error?)
        
## 操作接口进行调用(反向调用 Etc.)接口，简单来说就是要对方来响应

      do_method: (method, param, id) =>
        # 数据整理好调用数据发送出去
        @bson_spliter.send
          method: method
          param: param
          id: id
        
## 收到返回，直接emit出去使得监听本Session的模块能够得到消息以便处理

      on_result: (result) =>
        # 收到result结果……直接emit吧?
        emit 'result', result
        #log @id, result

## Event 收发，只有 event 和 data 两个

      emit_event: (name, data) =>
        @bson_spliter.send
          event: name
          data: data

      on_event: (event) =>
        emit 'event', event
        #log @id, event

    module.exports = BSON_RPC_Session
