base = require('./base')

describe 'zoxiy', ->
  describe 'Page title', ->
    it 'should be set by the Meteor method', ->
      browser.url "#{base.BASE_URL}/sign-in"
      console.log "browser.getTitle() = #{browser.getTitle()}"
      expect(browser.getTitle()).to.equal 'love-logic'
      return
    return
