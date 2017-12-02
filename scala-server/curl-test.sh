#!/bin/sh

GAME_SERVER_PORT=6597

creds="admin:admin"
accept="Accept: application/json"
contentType="Content-Type: application/json"
baseUrl="http://localhost:$GAME_SERVER_PORT"

function send {
  curl -u "$creds" -H "$accept" -H "$contentType" -X POST -d @- "${baseUrl}/game/$1" 
}

startResponse=`send "game" <<EOF
[
  {
    "width": 9,
    "height": 9,
    "trayCapacity": 9,
    "languageCode": "en",
    "playerName": "You"
  },
  [],
  [
    {
      "id": "4",
      "value": "S"
     },
    {
      "id": "5",
      "value": "T"
     },
    {
      "id": "6",
      "value": "Z"
     }
  ],
  [
    {
      "id": "1",
      "value": "B"
     },
    {
      "id": "2",
      "value": "E"
     },
    {
      "id": "3",
      "value": "T"
     }
  ]
]
EOF
`
echo $startResponse | python -m json.tool

gameId=`echo $startResponse | grep gameId | head -1 | sed -e 's/{"gameId":"//' -e 's/",.*//'`
echo $gameId

# ROMP is first play. tray pieces A - I. So COD will work.

# /game/gameId - + body that has play pieces for COD. piece, point, and moved -
# a list of these

commitResponse=`send "commit-play/${gameId}" <<EOF
[
  {
    "piece": {
      "id": "4",
      "value": "S"
     },
     "point": {
       "col": 2,
       "row": 1
     },
     "moved": true
  },
  {
    "piece": {
      "id": "2",
      "value": "E"
     },
     "point": {
       "col": 2,
       "row": 2
     },
     "moved": false
  },
  {
    "piece": {
      "id": "5",
      "value": "T"
     },
     "point": {
       "col": 2,
       "row": 3
     },
     "moved": true
  }
]
EOF
`

echo $commitResponse | python -m json.tool

machineResponse=`send "machine-play/${gameId}" <<EOF
EOF
`

echo $machineResponse | python -m json.tool

