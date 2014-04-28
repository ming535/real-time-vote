# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/



@vote = angular.module('vote', ['ngRoute', 'ngAnimate'])

@vote.config(['$httpProvider', ($httpProvider) ->
  authToken = $("meta[name=\"csrf-token\"]").attr("content")
  $httpProvider.defaults.headers.common["X-CSRF-TOKEN"] = authToken
])

@vote.config(['$routeProvider', ($routeProvider) ->
  $routeProvider
    .when('/rooms', {
      templateUrl: '../templates/rooms/index.html',
      controller: 'RoomIndexCtrl',
      requireLogin: true
    })
    .when('/group', {
      templateUrl: '../templates/group.html',
      controller: 'GroupCtrl',
      requireLogin: true
      })
    .otherwise({
      templateUrl: '../templates/home.html',
      controller: 'UserAuthCtrl',
      requireLogin: false
      })
])

@vote.factory('userService', ['$http', "$location", ($http, $location) ->
  user = null
  return {
    init: (userInfo) =>
      user = userInfo unless user

    signup: (username, weibo, password) =>
      promise = $http.post(
        'users.json', 
        {
          username: username,
          weibo: weibo 
          password: password,
          weibo: weibo
        })
        .success (data, status) =>
          user = data
          console.log('signup: ', user)
        .error (rsp) ->

      promise
    login: (username, password) =>
      promise = $http.post(
        'sessions.json', 
        {
          username: username, password: password
        })
        .success (data, status) =>
          user = data
        .error (rsp) ->
          user = null
      promise

    logout: () ->
      promise = $http.delete("sessions/#{user.id}.json")
        .success (data, status) ->
          user = null
        .error (rsp) ->
          console.log("logout error")
      promise

    joinRoom: (roomId) ->
      promise = $http.put("./rooms/join.json", {room_id: roomId, user_id: user.id})
        .success (data, status) ->
          console.log('joinRoom: ', data)
          user = data
        .error (rsp) ->
          console.log('joinRoom error')

      promise

    isLoggedIn: ->
      user != null and user.id > 0

    hasRoom: ->
      user != null and user.room_id > 0

    hasGroup: ->
      user != null and user.group_id > 0

    groupId: (id) ->
      user.group_id = id
      
    currentUser: ->
      user    
  }
])

@vote.factory('userQueryService', ['$http', '$interval', 'userService', ($http, $interval, userService) ->
  userInfo = null
  poll = () ->
    userService.init(gon.user_info)
    user = userService.currentUser()

    if user and user.id
      $http.get("users/query/#{user.id}.json")
          .success (data, rsp) =>
            userInfo = data
            # console.log('queryUser: ', userInfo)
          .error (rsp) =>
    else
      # console.log('user not logged in')
      # userService.redirect_to_home()

  queryResult = () ->
    userInfo

  start = () ->
    $interval(poll, 1000)

  return {
    queryResult: queryResult
    start: start
  }
])

@vote.run (['$rootScope', '$location', 'userService', ($rootScope, $location, userService) ->
  userService.init(gon.user_info)
  $rootScope.$on('$routeChangeStart', (e, next, current) ->
    if next.requireLogin and !userService.isLoggedIn()
      $location.path('/')
  )
])
