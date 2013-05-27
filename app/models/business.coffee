mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId
Mixed = Schema.Types.Mixed

BusinessSchema = new Schema
  json: {type: Mixed}
  createdAt:
    type: Date
    default: Date.now


#
# Schema statics
#
BusinessSchema.statics =
  list: (cb) ->
    @find().sort
      createdAt: -1
    .exec(cb)

module.exports = mongoose.model 'Business', BusinessSchema

