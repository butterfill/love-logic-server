describe 'zoxiy', ->
  describe 'Page title', ->
    it 'should be set by the Meteor method', ->
      browser.url 'http://localhost:3000/sign-in'
      browser.deleteCookie()
      browser.sessionStorage 'DELETE'
      browser.localStorage 'DELETE'
      expect(browser.getTitle()).to.equal 'love-logic'
      return
    return
