BSON = (require 'bson').BSONPure.BSON
require "coffee-script" if process.env["DEVELOP_RUNTIME"]?

rpc_service = require "./#{if process.env['DEVELOP_RUNTIME']? then 'src' else 'out'}/"
rpc_service.run()
