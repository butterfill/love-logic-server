describe 'zoxiy', ->
  describe 'sign out @watch', ->
    
    it 'clear cache', ->
      browser.url 'http://localhost:3000/sign-in'
      browser.deleteCookie()
      browser.sessionStorage 'DELETE'
      browser.localStorage 'DELETE'
      return
      
    it 'login', ->
      browser.url 'http://localhost:3000/sign-in'
      browser.setValue 'input[name=at-field-email]', 'student@'
      browser.setValue 'input[name=at-field-password]', 'lovelogic'
      browser.submitForm 'form#at-pwd-form'
      res = browser.execute(() -> 1+1)
      expect(res.value).to.equal(2)
      browser.waitUntil () ->
        res = browser.execute () -> ix.url()
        return res.value is '/'
      return
      
    it 'click sign out button', ->
      browser.click '#at-nav-button'
      browser.waitUntil () ->
        res = browser.execute () -> ix.url()
        return res.value is '/sign-in'
      return
  
    return
