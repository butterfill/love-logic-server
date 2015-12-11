describe 'love-logic tests', () ->
  server = meteor({
    # Seems to be ignored!
    # mongoUrl : 'mongodb://127.0.0.1:3001/love-logic'
    
    # doesn’t work
    # remoteServer : 'http://127.0.0.1:3000'
  })
  client = browser(server)
  db = mongo({dbName:'love-logic'})
  
  before( () ->
    return server.execute( () ->
      Accounts.createUser({email: 'test@.com',password: 'password'})
    )
  )
  
  it 'should log on the server', () ->
    return server.execute () -> 
      console.log 'I am alive!'

  # Doesn’t work because `db.getMongoUrl() is not a function`
  # it 'should connect to the database', () ->
  #   url = db.getMongoUrl()
  #   console.log url
  #   return server.execute( ( (url) -> console.log "mongo url #{url}" ), [ url ] )

  it 'should log on the client client', () ->
    return client.execute () ->
      console.log 'In the client!'

  it 'should get users on the server', () ->
    return server.execute () ->
      console.log "nof users: #{Meteor.users.find().count()}"
      console.log "nof subEx: #{SubmittedExercises.find().count()}"

  it 'has the title love-logic', () ->
    return client.title().then (title) ->
      expect(title).to.equal('love-logic')

  # NO: because signup is disabled (as is login)
  # it 'allows signup', () ->
  #   client.signUp({email:'test2@', password:'password'}).execute( () ->
  #     return  Meteor.users.findOne({'emails.address': 'test2@'})
  #   ).then (res) ->
  #     email = res.emails[0].address
  #     expect(email).to.equal('test2@')
      
  
  it 'should be able to login', () ->
    return client.execute( () ->
      FlowRouter.go('/sign-in')
      $('#at-field-email').val('test@')
      $('#at-field-password').val('password')
      $('#at-btn').click() 
    ).then( client.execute () ->
      return Meteor.users.findOne({'emails.address': 'test@'})
    ).then( client.execute (res) ->
      email = res.emails[0].address
      expect(email).to.equal('test2@')
    )