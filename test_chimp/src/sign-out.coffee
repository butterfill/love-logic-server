base = require('./base')

describe 'zoxiy', ->
  describe 'sign out', ->
    
    it 'clear cache', ->
      base.clearCache(browser)

    it 'login', ->
      base.login(browser, 'student@', 'student')
      
    it 'click sign out button', ->
      browser.click '#at-nav-button'
      browser.waitUntil () ->
        res = browser.execute () -> ix.url()
        return res.value is '/sign-in'
      return
  
    return
