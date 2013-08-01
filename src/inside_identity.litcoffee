自我ID标记文档，用来生成/读取自身相关标记信息
引用config来查找是通过数据库还是通过文本文件来获取相关数据
TODO:可以通过配置来改变id生成方式

    bson = require 'bson'
    path = require 'path'

    mid = ''
    try
      mid = require './id.js'
      mid = bson.ObjectID.createFromHexString mid
    catch
      mid = bson.ObjectID.createPk()

如果没有读取到id，则将生成的ID写入./id.js 以便下次启动的时候id.js唯一确定
PS:一定要确保本地目录可以写入，否则会失败。
PS:可以在安装过程中主动require该模块生成id

      fs = require 'fs'
      idfile = fs.openSync "#{path.dirname require.resolve './inside_identity'}/id.js", 'w'
      fs.writeSync idfile, "module.exports='#{mid}'"
      fs.closeSync idfile

最终输出：ObjectID 对象

    module.exports = mid
