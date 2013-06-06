mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId
Mixed = Schema.Types.Mixed
ScannerManager = require('../lib/scanner_manager').ScannerManager

ScannerSchema = new Schema
  radius: {type: Number, default: 100}
  latitude: {type: Number, default: 32.048243}
  longitude: {type: Number, default: -81.101074}
  title: {type: String, default: 'Default search title'}
  scannerType: [{type: String}]
  searchType: {type: String}
  createdAt:
    type: Date
    default: Date.now
  status: {type: String, default: 'New'}
  businesses: [{ type: ObjectId, ref: 'Business' }]


ScannerSchema.methods.scan = ->
  Scanner.update {_id: @id}, {businesses: []}, {upsert: on}, (err)=>
    new ScannerManager(@).exec()

ScannerSchema.statics =
  list: (cb) ->
    @find()
    .sort(createdAt: -1)
#    .populate('businesses')
    .exec(cb)

ScannerSchema.post 'init', (doc)->
#  if @get('status') is in ['Completed', 'New']
#    new ScannerManager(doc).exec()
#  doc._id

Scanner = mongoose.model 'Scanner', ScannerSchema

module.exports = Scanner

