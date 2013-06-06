var pidfile = require('pid');

pidfile('/var/run/dgm.pid');

require('coffee-script')
require('./app')
