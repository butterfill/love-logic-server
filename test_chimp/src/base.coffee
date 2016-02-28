exports.xFindText = (text) -> "//*[contains( normalize-space(.), '#{text}' )]"

BASE_URL = 'http://logic-ex.butterfill.com'
# BASE_URL = 'http://logic-ex-test.butterfill.com'
# BASE_URL = 'http://localhost:3000'
exports.BASE_URL = BASE_URL

exports.clearCache = (b) ->
  b.url "#{BASE_URL}/sign-in"
  try
    b.deleteCookie()
  catch error
    console.log error
  try
    b.localStorage 'DELETE'
  catch error
    console.log error
  try
    b.sessionStorage 'DELETE'
  catch error
    console.log error
  # in case can’t clear, try to logout manually
  try
    browser.click '#at-nav-button'
    browser.waitUntil () ->
      res = browser.execute () -> ix.url()
      return res.value is '/sign-in'
  catch error
    console.log "no sign out [may be expected]"
  

exports.login = (b, username, password) ->
  username ?= 'tester@'
  password ?= 'tester'
  b.url "#{BASE_URL}/sign-in"
  b.setValue 'input[name=at-field-email]', username
  b.setValue 'input[name=at-field-password]', password
  b.submitForm 'form#at-pwd-form'
  # res = b.execute(() -> 1+1)
  # expect(res.value).to.equal(2)
  b.waitUntil () ->
    res = b.execute () -> ix.url()
    return res.value is '/'
  return

exports.resetTester = (b) ->
  b.execute () ->
    FlowRouter.go('/resetTester')
  b.pause 100
  itExists = b.waitForExist '.itIsDone'
  expect(itExists).to.be.true
  

exports.goPage = (browser, url) ->
  browser.execute (url) ->
    FlowRouter.go url
  , url
      
