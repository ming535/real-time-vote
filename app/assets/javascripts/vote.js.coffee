# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

#= require_self
#= require listener
#= require ./models/proposal
#= require ./models/group
#= require ./models/opponents
#= require ./models/login
#= require ./models/rooms
#= require ./models/current_user
#= require_tree ./templates
#= require_tree ./views
#= require_tree ./routers


window.App =
  Routers: {}
  Views: {}
  Collections: {}
  Models: {}
  Vent: _.clone(Backbone.Events)
  initialize: (data)->
    App.currentUser = new App.Models.CurrentUser(data)
    App.listener = new App.Listener()
    new App.Routers.MainRouter()
    Backbone.history.start()


    