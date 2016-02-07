// Generated by CoffeeScript 1.10.0
(function() {
  var base;

  base = require('./base');

  describe('zoxiy', function() {
    return describe('sign out', function() {
      it('clear cache', function() {
        return base.clearCache(browser);
      });
      it('login', function() {
        return base.login(browser, 'student@', 'student');
      });
      it('click sign out button', function() {
        browser.click('#at-nav-button');
        browser.waitUntil(function() {
          var res;
          res = browser.execute(function() {
            return ix.url();
          });
          return res.value === '/sign-in';
        });
      });
    });
  });

}).call(this);
