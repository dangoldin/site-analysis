console.log('Starting crawl');

var page = require('webpage').create(),
    system = require('system'),
    fs = require('fs'),
    fin = fs.open('top100.csv', 'r'),
    domains = get_domains(fin),
    urls = [],
    timeout = 5000,
    outfile = system.args[2] || 'out.csv',
    f = fs.open(outfile, 'w'),
    ft = fs.open('out-times.csv', 'w'),
    iterations = 10,
    url;

function handle_page(url) {
    var page = require('webpage').create();
    page.settings.resourceTimeout = timeout;
    page.settings.userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.57 Safari/537.36";
    page.onResourceReceived = function(response) {
        // console.log('Response (#' + response.id + ', stage "' + response.stage + '"): ' + JSON.stringify(response));
        if (response.status == 200) {
            console.log(response.contentType + "\t" + response.url);
            f.write(url + "\t" + response.contentType + "\t" + response.url + "\n");
        }
    };
    page.onResourceError = function(resourceError) {
        page.reason = resourceError.errorString;
        page.reason_url = resourceError.url;
    };

    var start = Date.now();
    page.open(url, function(status) {
    console.log("Status: " + status);
    if (status !== 'success') {
        console.log('Unable to load the address: ' + url);
        console.log(page.reason);
        console.log(page.reason_url);
      };
      var end = Date.now();
      var duration = end - start;
      console.log(url + ': ' + duration);
      ft.write(url + "\t" + duration + "\n");

      page.close();
      setTimeout(process, 100);
  });
}

function process() {
    if (urls.length == 0) {
        console.log('Done!');
        f.close();
        ft.close();
        phantom.exit();
        return;
    }

    var url = 'http://' + urls.shift();
    console.log('Opening ' + url);
    handle_page(url);
}

function get_domains(f) {
    var domains = [],
        line = f.readLine();
    while (line) {
        var domain = line.split(',')[1];
        console.log( domain );
        domains.push( domain );
        line = f.readLine();
    };

    return domains;
}

/*
Can change "iterations" to run more times (note that this is useful for the -times.csv file
but not the general requests file)
*/

for (var i = 0; i < iterations; i++) {
    urls = urls.concat(domains.slice(0));
};

console.log('# of URLs: ' + urls.length);

process();