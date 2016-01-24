/*==============================================================================*/
/* Casper generated Thu Jan 21 2016 19:15:33 GMT+0000 (GMT) */
/*==============================================================================*/

var x = require('casper').selectXPath;
casper.options.viewportSize = {width: 1436, height: 805};
casper.on('page.error', function(msg, trace) {
   this.echo('Error: ' + msg, 'ERROR');
   for(var i=0; i<trace.length; i++) {
       var step = trace[i];
       this.echo('   ' + step.file + ' (line ' + step.line + ')', 'ERROR');
   }
});
casper.test.begin('Resurrectio test', function(test) {
   casper.start('http://localhost:3000');
   casper.waitForSelector(x("//*[contains(text(), \'Sign In\')]"),
       function success() {
           test.assertExists(x("//*[contains(text(), \'Sign In\')]"));
         },
       function fail() {
           test.assertExists(x("//*[contains(text(), \'Sign In\')]"));
   });
   casper.waitForSelector("form#at-pwd-form input[name='at-field-email']",
       function success() {
           test.assertExists("form#at-pwd-form input[name='at-field-email']");
           this.click("form#at-pwd-form input[name='at-field-email']");
       },
       function fail() {
           test.assertExists("form#at-pwd-form input[name='at-field-email']");
   });
   casper.waitForSelector("input[name='at-field-email']",
       function success() {
           this.sendKeys("input[name='at-field-email']", "tes");
       },
       function fail() {
           test.assertExists("input[name='at-field-email']");
   });
   casper.waitForSelector("input[name='at-field-password']",
       function success() {
           this.sendKeys("input[name='at-field-password']", "tester");
       },
       function fail() {
           test.assertExists("input[name='at-field-password']");
   });
   casper.waitForSelector("form#at-pwd-form button#at-btn",
       function success() {
           test.assertExists("form#at-pwd-form button#at-btn");
           this.click("form#at-pwd-form button#at-btn");
       },
       function fail() {
           test.assertExists("form#at-pwd-form button#at-btn");
   });
   /* submit form */
   casper.waitForSelector(".col.s12.m6.l4:nth-child(1) .card-title.black-text",
       function success() {
           test.assertExists(".col.s12.m6.l4:nth-child(1) .card-title.black-text");
           this.click(".col.s12.m6.l4:nth-child(1) .card-title.black-text");
       },
       function fail() {
           test.assertExists(".col.s12.m6.l4:nth-child(1) .card-title.black-text");
   });
   casper.waitForSelector(".col.s12.m6.l4:nth-child(1) .card-title.black-text",
       function success() {
           test.assertExists(".col.s12.m6.l4:nth-child(1) .card-title.black-text");
           this.click(".col.s12.m6.l4:nth-child(1) .card-title.black-text");
       },
       function fail() {
           test.assertExists(".col.s12.m6.l4:nth-child(1) .card-title.black-text");
   });
   casper.waitForSelector(".col.s12.m6.l4:nth-child(1) .card-action",
       function success() {
           test.assertExists(".col.s12.m6.l4:nth-child(1) .card-action");
           this.click(".col.s12.m6.l4:nth-child(1) .card-action");
       },
       function fail() {
           test.assertExists(".col.s12.m6.l4:nth-child(1) .card-action");
   });
   casper.waitForSelector(x("//*[normalize-space(text())='Select an exercise set']"),
       function success() {
           test.assertExists(x("//*[normalize-space(text())='Select an exercise set']"));
         },
       function fail() {
           test.assertExists(x("//*[normalize-space(text())='Select an exercise set']"));
   });
   casper.then(function() {
       test.assertExists(x("//a[normalize-space(text())='Select an exercise set' and @href='/courses']"));
   });
   casper.waitForSelector(x("//a[normalize-space(text())='Select an exercise set']"),
       function success() {
           test.assertExists(x("//a[normalize-space(text())='Select an exercise set']"));
           this.click(x("//a[normalize-space(text())='Select an exercise set']"));
       },
       function fail() {
           test.assertExists(x("//a[normalize-space(text())='Select an exercise set']"));
   });
   casper.waitForSelector(x("//*[contains(text(), \'UK_W20_PH126\')]"),
       function success() {
           test.assertExists(x("//*[contains(text(), \'UK_W20_PH126\')]"));
         },
       function fail() {
           test.assertExists(x("//*[contains(text(), \'UK_W20_PH126\')]"));
   });
   casper.waitForSelector("#__blaze-root h2",
       function success() {
           test.assertExists("#__blaze-root h2");
           this.click("#__blaze-root h2");
       },
       function fail() {
           test.assertExists("#__blaze-root h2");
   });

   casper.run(function() {test.done();});
});