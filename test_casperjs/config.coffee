try
  slimer
catch e
  console.log "using phantomjs"
  require('es6-shim')
  localStorage.clear()
  

configure = (casper) ->
  casper.options.viewportSize = {width: 1024, height: 768}

  # This ensures tests fail if there’s an error in the code behind a template which Meteor catches
  casper.on 'remote.message', (message) ->
    @echo 'console: ' + message.substring(0,300)
    if message.startsWith('Exception in template helper')
      @capture 'img/exception.png'
      @echo '---'
      @echo 'long msg: ' + message.substring(0,3000)
      @echo '---'
      throw new Error "meteor exception in template"

  casper.on 'page.error', (msg, trace) ->
    @echo('Error: ' + msg, 'ERROR')
    # for step in trace
    #   @echo('   ' + step.file + ' (line ' + step.line + ')', 'ERROR')
exports.configure = configure

exports.LOGIN_EMAIL = 'tester@'
exports.LOGIN_PW = 'tester'

# URL = 'http://logic-ex.butterfill.com/sign-in'
# URL = 'http://logic-ex-test.butterfill.com/sign-in'
URL = 'http://localhost:3000/sign-in'
exports.URL = URL
console.log "URL: #{URL}"