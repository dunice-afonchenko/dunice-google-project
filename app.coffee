
###
Form5 Node.js Express Skeleton
Based on https://github.com/madhums/nodejs-express-mongoose-demo
###
express = require("express")
http = require("http")
fs = require("fs")
passport = require("passport")
mongoose = require("mongoose")
coffee = require("coffee-script")
less = require("less")
env = process.env.NODE_ENV or "development"
config = require("./config/environment")[env]
auth = require("./config/middlewares/authorization")
MongoStore = require('connect-mongo')(express)

# Bootstrap database
console.log "Connecting to database at " + config.db
mongoose.connect config.db

# Bootstrap models
models_path = __dirname + "/app/models"
fs.readdirSync(models_path).forEach (file) ->
  require models_path + "/" + file

# bootstrap passport config
require("./config/passport") passport, config
app = express()

sessionStore = new MongoStore({
  url: config.db,
  collection : 'sessions'
})

# express settings
require("./config/express") app, config, passport, sessionStore

# Bootstrap routes
require("./config/routes") app, passport, auth

# Helper funtions
require("./app/helpers/general") app

# Start the app by listening on <port>
port = process.env.PORT or 4000

server = http.createServer(app)




SocketServer = require './lib/socket-server'
controllers = []
#controllers = ['user', 'scanner']
socketRoutes = []
addController = (controllerName) ->
  Controller = require("./controllers/#{controllerName}")
  controller = new Controller(app)
  socketRoutes.push controller.getSocketRoutes()
addController(controllerName) for controllerName in controllers
cookieParser = express.cookieParser config.session.secret
SocketServer.init(server, sessionStore, cookieParser, socketRoutes)



server.listen port, ->
  console.log "Scanner app running on port " + port

