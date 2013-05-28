module.exports = (app, passport, auth) ->

  # User routes
  users = require '../app/controllers/users'
  app.get '/login', users.login

  app.post '/login', passport.authenticate('local',
    failureRedirect: '/login'
    failureFlash: true),

    (req, res) ->
      res.redirect '/'
      return

  app.get '/logout', users.logout

  app.get '/users', auth.requiresLogin, users.index
  app.get '/users/new', auth.requiresLogin, users.new
  app.post '/users', auth.requiresLogin, users.create
  app.get '/users/:userId/edit', auth.requiresLogin, users.edit
  app.put '/users/:userId', auth.requiresLogin, users.update
  app.get '/users/:userId/destroy', auth.requiresLogin, users.destroy

  app.param 'userId', users.user

  # Article routes
  articles = require '../app/controllers/articles'
#  app.get '/', articles.index

  app.get '/articles', articles.manage
  app.get '/articles/new', auth.requiresLogin, articles.new
  app.get '/articles/:articleId', articles.show
  app.post '/articles', auth.requiresLogin, articles.create
  app.get '/articles/:articleId/edit', auth.requiresLogin, articles.edit
  app.put '/articles/:articleId', auth.requiresLogin, articles.update
  app.get '/articles/:articleId/destroy', auth.requiresLogin, articles.destroy
  app.param 'articleId', articles.article


  # Scanner routes
  scanner = require '../app/controllers/scanner'
  app.get '/', scanner.index
  app.get '/scanner/new', auth.requiresLogin, scanner.new
  app.get '/scanner/:scannerId/refresh', auth.requiresLogin, scanner.refresh
  app.get '/scanner/:scannerId/show', scanner.show
  app.get '/scanner/:scannerId/destroy', auth.requiresLogin, scanner.destroy
  app.post '/scanner', auth.requiresLogin, scanner.create
#  app.get '/scanner/businesses', scanner.businesses

  app.param 'scannerId', scanner.scanner




  return

