var page = require('webpage').create(),
    system = require('system'); 

if (system.args.length < 3) {
  console.log('Usage: phantomjs capture.js INFILE OUTFILE')
    phantom.exit(1);
}

page.open(system.args[1], function() {
  page.render(system.args[2]);
  phantom.exit();
});
