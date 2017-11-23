port module Shanghai exposing (..)
{-  Shanghai.elm - Updated for 0.18
    Build with: $elm-make --warn --output Shanghai.js Shanghai.elm
 -}

import Json.Decode
-- https://github.com/elm-lang/elm-make/issues/127

import Dict exposing (Dict)

type alias Model =
    Dict String Int

type alias ShipInfo =
    { name : String
    , capacity : Int
    }

-- Browser-bound (-> Cmd msg)
port totalCapacity : Int -> Cmd msg

-- Elm-bound (-> Sub msg)
port incomingShip : (ShipInfo -> msg) -> Sub msg
port outgoingShip : (String -> msg) -> Sub msg

type Msg            -- see also "subscriptions" below
    = Dock ShipInfo -- ShipInfo as specified by incomingShip
    | Sail String   -- ship name as specified by outgoingShip

{-
    Specify which Msg data constructors to use for
    the various Elm-bound port values
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ incomingShip Dock
        , outgoingShip Sail
        ]

tallyCapacity : Model -> Int
tallyCapacity  =
    List.sum << Dict.values

{-  1. "regular" boring version
    tallyCapacity model =
        List.sum (Dict.values model)
    2. Use backward function application (<|) to "avoid parentheses"
    tallyCapacity model =
        List.sum <| Dict.values model
    3. Use function composition (<<) for a "pointfree style"
       representation (parameter is implied and therefore "unseen")
    tallyCapacity  =
        List.sum << Dict.values
    4. Alternately with (>>) 
    tallyCapacity  =
        Dict.values >> List.sum
-}

dock : ShipInfo -> Model -> ( Model , Cmd Msg )
dock info model =
    let
        newModel = Dict.insert info.name info.capacity model
    in
        ( newModel, totalCapacity <| tallyCapacity newModel )

sail : String -> Model -> ( Model, Cmd Msg )
sail name model =
    let
        newModel = Dict.remove name model
    in
        ( newModel, tallyCapacity newModel |> totalCapacity )
        -- alternately used forward function application (|>) instead

{-  Alternately Platform.programWithFlags
    accepts initialization data to be passed
    to "init" function
-}
init : ( Model, Cmd msg )
init =
    ( Dict.empty, totalCapacity 0 )
--  ( Dict.empty, Cmd.none )
--  as an alternate if initial capacity report is not desired. 

-- Process the incoming values and dispatch the updated capacity
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Dock info ->
            dock info model

        Sail name ->
            sail name model

{-
  Platform.program is "headless" - it does not
  generate an HTML view
-}
main : Program Never Model Msg
main =
    Platform.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        }

