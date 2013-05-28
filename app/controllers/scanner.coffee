mongoose = require 'mongoose'
request = require 'request'
async = require 'async'
#_ = require 'underscore'
#_.mixin require 'underscore.deferred'

Business = require('../models/business')
Scanner = require('../models/scanner')



exports.create = (req, res) ->
  scanner = new Scanner req.body
  scanner.save (err) ->
    if err
      res.render 'scanner/new',
        errors: err.errors
        scanner: scanner
    scanner.scan()
    res.redirect '/'


exports.index = (req, res) ->


  Scanner.list (err, scanners) ->
    res.render 'scanner/index',
      scanners: scanners
      message: req.flash 'notice'

exports.new = (req, res) ->
  res.render 'scanner/new',
    scanner: new Scanner({})

exports.refresh = (req, res)->
  req.scanner.scan()
  console.log 'refresh'#, req.scanner
  res.redirect '/'


exports.scanner = (req, res, next, id) ->
  Scanner.findById(id).exec (err, scanner) ->
    return next err if err
    return next new Error 'Failed to load scanner' if not scanner
    req.scanner = scanner
    next()

exports.destroy = (req, res) ->
  scanner = req.scanner
  scanner.remove (err) ->
    req.flash 'notice', scanner.title + ' was successfully deleted.'
    # TODO: remove all appropriate businesses?
    res.redirect '/'


exports.show = (req, res)->
  req.scanner.populate 'businesses', (err, scanner)->
    res.render 'scanner/show',
      scanner: scanner


#exports.businesses = (req, res) ->
#  query = req.query
#  params = {
#    location: [query.latitude, query.longitude]
#    radius: query.radius
#    title: query.title
#  }

#  scanner = new Scanner


##  controller.getBusinesses (errors, businesses)->
#  Business.find({}).limit(3).exec (error, businesses)->
#    console.log 'results------>>', arguments#businesses.json.name
#    return res.render 'scanner/businesses',
#      businesses: businesses

