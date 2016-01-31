describe 'zoxiy', ->
  describe 'Page title', ->
    it 'should be set by the Meteor method', ->
      browser.url 'http://localhost:3000/sign-in'
      browser.deleteCookie()
      browser.sessionStorage 'DELETE'
      browser.localStorage 'DELETE'
      expect(browser.getTitle()).to.equal 'love-logic'

  describe 'student login', ->
    it 'should be possible to login as a student',  ->
      browser.setValue 'input[name=at-field-email]', 'student@'
      browser.setValue 'input[name=at-field-password]', 'lovelogic'
      browser.submitForm 'form#at-pwd-form'
