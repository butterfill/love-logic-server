describe 'zoxiy', ->
  describe 'Page title', ->
    it 'should be set by the Meteor method @watch', ->
      browser.deleteCookie()
      browser.sessionStorage 'DELETE'
      browser.localStorage 'DELETE'
      browser.url 'http://localhost:3000/sign-in'
      expect(browser.getTitle()).to.equal 'love-logic'
      return
    return
