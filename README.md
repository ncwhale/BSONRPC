BSONRPC
=======

A simple rpc server/client based on BSON, written on node.js.

It can work with other languages & systems.

From now on, C++ & Java can simple connect with it.

----

BSONRPC 模块说明
=======

这是一个简单的RPC 服务端/客户端 模块，采用 BSON 作为其最基本通信包。

本项目作为 Node.js 模块进行编写和发布，同时还有 C++ 和 Java 相关实现。

当然，这个协议是如此 *简单* 以至于大家都可以简单的编写一个对应语言的模块出来。

----

Example
=======

To start a project as a RPC service, just do things below:

1. in your project dir, type `npm install bsonrpc` to install this module.
2. create a dir named 'RPC' or something as U wish. 

    *PS:* if you changed the default directory, you need config this when start service.

3. create a simple model in that dir, such as "Hello, world":

        hello = (session, call_id)->
          session.do_result 
            id: call_id
            result:
              message: "world!"
          
        
        module.exports = (method, session) ->
          return (param, call_id) ->
            hello(session, call_id)

4. create a simple start script:

        rpc = require 'bsonrpc'
        rpc.run 
          host: '127.0.0.1'
          port: 9527

5. all done! A BSON-RPC service is created! Now you can use this service like this:

        client.connect '127.0.0.1', 9527
        
        client.on 'result', (result)->
          log result
        
        client.call 'hello', null, 0



备注
------

