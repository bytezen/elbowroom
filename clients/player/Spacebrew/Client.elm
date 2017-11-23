port module Client exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode
import WebSocket
import Spacebrew.Spacebrew as Sb

{- 
    Client has a random generated name and subscribes
    to Spacebrew Controller messages by default

    The client will receive instructions from the controller
    on the channels that it should subscribe and publish to
    for playing the game
-}


-- Model 


type alias Model =
    { messages : List String
    , clientId : String -- TODO: passed in at startup
    , server : String -- TODO: passed in at startup
    }

init : ( Model, Cmd msg ) 
--init = ( Model [] "foo123" , Cmd.none )
init = ( { 
           messages = [] 
         , clientId = "foo123"
         , server = "ws://localhost:9000" 
         } 
         , Cmd.none )

-- Ports


-- Browser bound ( -> Cmd msg)
port messageReceived : String -> Cmd msg
port log : String -> Cmd msg

-- Elm bound ( -> Sub msg)
-- pattern from https://medium.com/@_rchaves_/elm-how-to-use-decoders-for-ports-how-to-not-use-decoders-for-json-a4f95b51473a
port sendMessage : (Decode.Value -> msg ) -> Sub msg

-- Update


type Msg = Message (Result String String)
         | Connect String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Message m -> 
            (
            { model | messages = (handleMessage m) :: model.messages }
            , log <| " logging from elm: " ++ (handleMessage m)
            )
        Connect configmsg ->
            (model, WebSocket.send model.server configmsg)

        --_ ->
        --    ( model, Cmd.none )


handleMessage : Result String String -> String
handleMessage msg =
    case msg of
        Ok s -> s
        Err s -> "bad message: " ++ s


-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch 
        [
         sendMessage  (decodeClientMessage  >> Message )
        ]




-- Decoders
decodeClientMessage : Decode.Value -> Result String String
decodeClientMessage =
    Decode.decodeValue
        <| Decode.oneOf 
            [ 
             (Decode.field "messages" Decode.string)
            --, Sb.clientConfigMsgDecoder
            ]



-- Main


main =
    Platform.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        }

