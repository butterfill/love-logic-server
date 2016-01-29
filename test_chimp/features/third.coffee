describe 'zoxiy', ->
  describe 'Page title', ->
    it 'should be set by the Meteor method @watch', ->
      browser.deleteCookie()
      browser.sessionStorage 'DELETE'
      browser.localStorage 'DELETE'
      browser.url 'http://localhost:3000/sign-in'
      expect(browser.getTitle()).to.equal 'love-logic'

  describe 'student login', ->
    it 'should be possible to login as a student @watch',  ->
      browser.setValue 'input[name=at-field-email]', 'sb@'
      browser.setValue 'input[name=at-field-password]', 'lovelogic'
      browser.submitForm 'form#at-pwd-form'
