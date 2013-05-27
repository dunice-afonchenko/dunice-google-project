mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId
Mixed = Schema.Types.Mixed

ScannerSchema = new Schema
  radius: {type: Number, default: 100}
  latitude: {type: Number, default: 32.048243}
  longitude: {type: Number, default: -81.101074}

module.exports = mongoose.model 'Scanner', ScannerSchema

