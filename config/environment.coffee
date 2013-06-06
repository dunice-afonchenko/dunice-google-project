module.exports =
  development:
    session:
      secret: 'fhwrg7823yg8923yg8wer'
    app:
      name: 'Scanner app'
    root: require('path').normalize(__dirname + '/..')
    db: process.env.MONGOLAB_URI || process.env.MONGOHQ_URL || 'mongodb://localhost/scanner-app'

