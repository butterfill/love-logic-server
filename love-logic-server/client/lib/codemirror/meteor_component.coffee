# This is a CodeMirror editor that (TODO:) will save state
#
# Modified from https://github.com/perak/codemirror/blob/master/lib/component/component.js

# Template.CodeMirror.onCreated = ->

Template.CodeMirror.rendered = () ->
  options = @data.options or lineNumbers: true
  textarea = @find('textarea')
  editor = CodeMirror.fromTextArea(textarea, options)
  self = this
  editor.on 'change', (doc) ->
    val = doc.getValue()
    textarea.value = val
    if self.data.reactiveVar
      Session.set self.data.reactiveVar, val

  # Ugly hack: TODO: get rid of this
  if @data.getEditorObj
    @data.getEditorObj.editor = editor

  if @data.reactiveVar
    Tracker.autorun ->
      val = Session.get(self.data.reactiveVar) or ''
      if val != editor.getValue()
        editor.setValue val

Template.CodeMirror.destroyed = () ->
  @$('textarea').parent().find('.CodeMirror').remove()
  return

Template.CodeMirror.helpers
  'editorId': () ->
    @id or 'code-mirror-textarea'
  'editorName': () ->
    @name or 'code-mirror-textarea'





# TODO: enchanced for sentences of FOL: includes a feedback line
#Template.CodeMirrorFOL.rendered = ->


# TODO: enchanced for proofs: includes a feedback line
#Template.CodeMirrorProof.rendered = ->
