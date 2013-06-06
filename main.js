var pidfile = require('pid');

pidfile('/var/run/dgp.pid');

require('coffee-script')
require('./app')
