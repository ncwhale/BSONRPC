BSONRPC
=======

A simple rpc server based on BSON, written on node.js.

约定：所有Model都以其自身模组名字命名并放置在与SYS同级的目录下；
约定：所有的Model及其子Model和方法的命名用.分割开，例如： BSONRPC.CALL

开发的目录结构就像这样：

/- 项目根
|- README.md 你现在看到的这个
|- SYS 本项目提供的代码
 \- 本项目提供的源代码
|- 你的Model目录
 |- 某个SubModel的目录
 |- 某个方法的独立文件
 \- 你的Model的其它源代码
|- 你的其它Model目录...
\- index.litcoffee 本项目的启动脚本，可以根据自身需求调整

1.每次远程调用到来的时候，系统会自动查找对应的Model是否存在，顺序是 方法名-> SubModel名称 -> Model名称 -> 未找到；
2.远程调用的接口如下，涉及3个BSON结构：
