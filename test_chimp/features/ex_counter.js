// Generated by CoffeeScript 1.10.0
(function() {
  var base, xFindText;

  base = require('./base');

  xFindText = base.xFindText;

  describe('zoxiy', function() {
    describe('counter_ex', function() {
      it('clear cache', function() {
        return base.clearCache(browser);
      });
      it('login', function() {
        return base.login(browser);
      });
      it('can reset tester', function() {
        return base.resetTester(browser);
      });
      it('goes to the page', function() {
        var msg;
        base.goPage(browser, '/ex/counter/qq/F(a)|F(b)');
        msg = browser.getText(xFindText('F(a)'));
        return expect(msg).to.exist;
      });
      it('allows you to add to the extension of a predicate', function() {
        var inputSel;
        inputSel = 'input[name=predicate-F]';
        browser.setValue(inputSel, '{<0>}\t');
        return expect(browser.getValue(inputSel).replace(/\s/g, '')).to.equal('{<0>}');
      });
      it('marks correct answers correct @watch', function() {
        var msg;
        browser.click('button#submit');
        browser.pause(250);
        msg = browser.waitForText(xFindText('answer is correct'));
        return expect(msg).to.exist;
      });
      it('allows you to add to, and remove from, the domain', function() {
        browser.click('.addToDomain');
        expect(browser.getText('.domain').indexOf('1')).not.to.equal(-1);
        browser.click('.removeFromDomain');
        return expect(browser.getText('.domain').indexOf('1')).to.equal(-1);
      });
      it('doesn’t allow removing the last element from the domain', function() {
        browser.click('.removeFromDomain');
        browser.click('.removeFromDomain');
        return expect(browser.getText('.domain').indexOf('0')).not.to.equal(-1);
      });
      it('does not allow you to include non-domain objects in extensions', function() {
        var inputSel;
        inputSel = 'input[name=predicate-F]';
        browser.setValue(inputSel, '{<0>,<1>}\t');
        return expect(browser.getValue(inputSel).replace(/\s/g, '')).to.equal('{<0>}');
      });
      it('does not allow you to remove domain objects if they are in extensions', function() {
        var inputSel;
        browser.execute(function() {
          return $('#toast-container').hide();
        });
        browser.click('.addToDomain');
        inputSel = 'input[name=predicate-F]';
        browser.setValue(inputSel, '{<0>,<1>}\t');
        expect(browser.getValue(inputSel).replace(/\s/g, '')).to.equal('{<0>,<1>}');
        browser.click('.removeFromDomain');
        browser.click('.removeFromDomain');
        return expect(browser.getText('.domain').indexOf('1')).not.to.equal(-1);
      });
      it('allows you to update the referents of names', function() {
        var inputSel;
        inputSel = 'input[name=name-a]';
        browser.setValue(inputSel, '1\t');
        return expect(browser.getValue(inputSel).replace(/\s/g, '')).to.equal('1');
      });
      it('only allows you to assign names to objects in the domain', function() {
        var inputSel;
        inputSel = 'input[name=name-a]';
        browser.setValue(inputSel, '2\t');
        return expect(browser.getValue(inputSel).replace(/\s/g, '')).not.to.equal('2');
      });
      it('marks incorrect answers incorrect', function() {
        var inputSel, msg;
        browser.click('.addToDomain');
        browser.click('.addToDomain');
        inputSel = 'input[name=name-a]';
        browser.setValue(inputSel, '2\t');
        expect(browser.getValue(inputSel).replace(/\s/g, '')).to.equal('2');
        browser.click('button#submit');
        browser.pause(250);
        msg = browser.waitForText(xFindText('answer is incorrect'));
        return expect(msg).to.exist;
      });
      it('updates the question when changing the page', function() {
        var doesntExist, msg;
        browser.execute(function() {
          return FlowRouter.go('/ex/counter/qq/G(c)|a=c');
        });
        doesntExist = browser.waitForExist(xFindText('F(a)'), 100, true);
        expect(doesntExist).to.be["true"];
        msg = browser.getText(xFindText('G(c)'));
        expect(msg).to.exist;
        msg = browser.getText(xFindText('a = c'));
        expect(msg).to.exist;
      });
    });
  });

}).call(this);
