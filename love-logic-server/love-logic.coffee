Router.route '/', () ->
  this.render 'hello'

Router.route '/ex/proof/from/:_premises/to/:_conclusion', () ->
  this.render 'proof'#, 
    # data : () ->
    #   premises = decodeURIComponent(@params._premises).split('|')
    #   conclusion = decodeURIComponent @params._conclusion
    #   return {premises, conclusion}