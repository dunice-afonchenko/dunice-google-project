


# SocketSession is attached to each socket when it connects
# (or on whichever event you pass to SocketSessionProvider.on)
class SocketSession
  constructor: (@sessionStore, @cookie) ->

  # Gets the socket's related session from the session store (asynchronous)
  get: (cb) ->
    @sessionStore.get @cookie, (err, session)=>
      # Assign the session to `this.data`
      unless err
        @data = session
      cb err, session

  # Saves the socket's modified session to the session store (asynchronous)
  #
  # The callback is optional
  save: (cb = null) ->
    @sessionStore.set @cookie, @data, (err, result)=>

      if err
        console.log.error "Error saving session", { err: err }

      if cb
        cb err, result


class SocketSessionProvider
  constructor: (@io, @sessionStore, @cookieParser, @key = 'connect.sid') ->


  on: (event, cb) ->
    # Socket event handler
    onSocketEvent = (socket) =>
      # Waits for cookie parser to get cookie information
      @cookieParser socket.handshake, {}, (parseErr)=>
        cookie = @findCookie socket.handshake
        @sessionStore.get cookie, (storeErr, session)=>
          err = @resolveErrors parseErr, storeErr, session

          # Gives each socket a get session and save session method
          unless err
            socket.session = new SocketSession(@sessionStore, cookie)

          cb err, socket, session

    @io.sockets.on event, onSocketEvent

  # Cookies can hide in multiple places within the handhsake. This method ferrets out the correct one.
  findCookie: (handshake) ->
    (handshake.secureCookies and handshake.secureCookies[@key]) or (handshake.signedCookies and handshake.signedCookies[@key]) or (handshake.cookies and handshake.cookies[@key])

  # Helper function for checking if there was an error:
  #
  # * parsing cookies
  # * accessing the session store
  # * getting a valid session
  #
  resolveErrors: (parseErr, storeErr, session) ->
    (parseErr) or ( if (!storeErr and !session) then new Error("Could not look up session by key: #{ @key }") else null ) or storeErr

module.exports = SocketSessionProvider

