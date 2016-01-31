describe('zoxiy', function() {
  describe('Page title', function () {
    it('should be set by the Meteor method', function () {
      browser.url('http://localhost:3000/sign-in');
      browser.deleteCookie();
      browser.sessionStorage('DELETE');
      browser.localStorage('DELETE');
      expect(browser.getTitle()).to.equal('love-logic');
    });
  });
  
  describe('login', function () {
    it('should be possible to login', function () {
      browser.url('http://localhost:3000/sign-in');
      browser.setValue('input[name=at-field-email]', 'tester@');
      browser.setValue('input[name=at-field-password]', 'tester');
      browser.submitForm('form#at-pwd-form');
    });
  });
});