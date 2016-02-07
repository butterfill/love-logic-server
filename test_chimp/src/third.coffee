base = require('./base')

describe 'zoxiy', ->
  describe 'student login', ->
    it 'clear cache', ->
      base.clearCache(browser)
      
    it 'should be possible to login as a student',  ->
      base.login(browser, 'student@', 'student')
