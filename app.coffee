app = angular.module "DraftPickerApp", ['firebase']
app.value('fbURL', 'https://brilliance.firebaseio.com/')
  .factory 'Fantasy', (angularFireCollection, fbURL) ->
    return angularFireCollection(fbURL)

draftPickerCtrl = ($scope, angularFire) ->

  $scope.current_needs = {}

  $scope.playerVal = (item) ->
    val = item['2012_points']
    val *= item.AdjRating if item.AdjRating and item.AdjRating > 0
    val *= item.Injury if item.Injury and item.Injury != "0"
    val *= item.TeamChange if item.TeamChange and item.TeamChange != "0"
    return val.toFixed(2)


  $scope.fixNumbers = ()->
    for player in $scope.players
      player['2012_points'] = parseFloat(player['2012_points'])


  angularFire("https://brilliance.firebaseio.com/roster", $scope, 'roster', {}).then ()->
    angularFire("https://brilliance.firebaseio.com/all_players", $scope, 'all_players', {}).then ()-> 
      angularFire("https://brilliance.firebaseio.com/players", $scope, 'players', []).then ()-> 
        angularFire("https://brilliance.firebaseio.com/byes", $scope, 'byes', {}).then playersHandlers

  playersHandlers = ()->

    $scope.getBye = (player)->
      return $scope.byes[$scope.all_players[player].Team]

    do resetByes = ()->
      $scope.bye_counts = {} if not $scope.bye_counts
      for bye,week of $scope.byes
        $scope.bye_counts[week] = 0 

    $scope.positionNeeds = (position) ->
      resetByes()
      need = $scope.roster.required[position]
      if $scope.roster.selections.length == 0 
        return need

      have = 0
      for sel in $scope.roster.selections
        $scope.bye_counts[$scope.getBye(sel)] += 1
        have += 1 if $scope.all_players[sel].Position == position 

      req = need - have
      if req < -1
        $scope.players = $scope.players.filter (elem)->
          $scope.all_players[elem].Position != position

      return req

    if not $scope.roster.selections
      $scope.roster.selections = []
    for position of $scope.roster.required
      $scope.current_needs[position] = $scope.positionNeeds(position)


    $scope.doReSort = () ->
      $scope.players.sort (a, b)->
        $scope.playerVal($scope.all_players[b]) - $scope.playerVal($scope.all_players[a])

    $scope.byeWarnings = (player)->
      bye = $scope.getBye(player)
      if $scope.bye_counts[bye] > 4
        return 'text-danger'
      if $scope.bye_counts[bye] > 2
        return 'text-warning'
      return ''

    $scope.reset = () ->
      $scope.players = []
      for player of $scope.all_players
        $scope.players.push player
      $scope.roster.selections = []
      $scope.roster.bye_warnings = {}
      for position of $scope.roster.required
        $scope.current_needs[position] = $scope.positionNeeds(position)

      resetByes()
      $scope.doReSort()

    $scope.selectPlayer = (index) ->
      playerName = $scope.players.splice(index,1)
      playerData = $scope.all_players[playerName]

      $scope.roster.selections = [] if not $scope.roster.selections
      $scope.roster.selections.push(playerName)
      $scope.current_needs[playerData.Position] = $scope.positionNeeds(playerData.Position)

    $scope.otherPicked = (index)->
      playerName = $scope.players.splice(index,1)

    $scope.removePlayer = (playerName) ->
      $scope.roster.selections = $scope.roster.selections.filter (elem)->(elem isnt playerName)
      $scope.players.push playerName[0]
      for position of $scope.roster.required
        $scope.current_needs[position] = $scope.positionNeeds(position)

      $scope.doReSort()



app.controller 'draftPickerCtrl', ['$scope', 'angularFire', draftPickerCtrl]
