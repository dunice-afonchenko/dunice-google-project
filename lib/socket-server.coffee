# The socket server wraps socket.io and allows for integration with Controllers
# Usage:
#     socketServer = new SocketServer(myExpressServer, mySessionStore, myCookieParser, socketRoutes)
#
# Access socket.io with:
#     socketServer.server
#
# The socket server setup looks something like
#
# 1. Hook up to express
# 2. Tell all incoming sockets that when they connect they need to get a session
#
# When a socket connects, this happens (roughly)
#
# 1. Make sure there is a cookie that points to a valid session to be loaded
# 2. Loop through all of the routes that have been set by the controllers
# (passed to the server as socketRoutes)
# 3. Assign each route to the socket (as an event).
#
# **PLEASE NOTE** - Session data must be loaded and saved manually from the controller method if it is
# changed! Example:
#
#    await @session.get defer(err)
#    @session.data.timesVisited++
#    await @session.save defer(err)
#    console.log('Save success') unless err

io = require 'socket.io'
_ = require 'lodash'

conf = require '../config/environment'

SocketSessionProvider = require './socket-session-provider'

SocketServer =
  # Sets up socket.io using the express application
  # Links `SocketSessionProvider` to
  init: (appServer, sessionStore, cookieParser, @socketRoutes) ->
    @server = io.listen appServer
    socketSessionProvider = new SocketSessionProvider(@server, sessionStore, cookieParser)
    socketSessionProvider.on 'connection', SocketServer.onSocketConnect
    return @


  onSocketConnect: (err, socket, session) ->
    if err
      console.log.info("Invalid socket attempt", { err: err, socket: socket, session: session })
    else
      # socketRoutes is built from the controller
      # These loops hook up the routes to the controller method
      for routes in SocketServer.socketRoutes
        socket.on(route, cb) for route, cb of routes

      return null

#  # ## onActivityCreated
#  # Broadcast each time new activity has been added to the database. Send the
#  # new activity out to listening sockets
#  onActivityCreated: (data) ->
#    # `data.data` is the data column in the activity table,
#    # which is stored as a json string. If it has been turned
#    # into an object, turn it back to json
#    if _.isObject data.data
#      data.data = JSON.stringify data.data

#    SocketServer.server.sockets.json.emit 'activity created', data


module.exports = SocketServer

