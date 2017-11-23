module Spacebrew.Spacebrew exposing (..)

import Json.Encode as E
import Json.Decode as D

type alias Name = String
type alias Description = String
type alias IpAddress = String
type alias ChannelType = String --StringChannel | BooleanChannel | RangeChannel

type SubChannel = SubChannel Name ChannelType
type PubChannel = PubChannel Name ChannelType String
type alias SubMessages = List SubChannel 
type alias PubMessages = List PubChannel 
--type ClientConfigDetail = ClientConfigDetail Name Description SubMessages PubMessages IpAddress

type ChannelValue = StringValue String | BooleanValue Bool | RangeValue Int

type Flags = AdminConfig AdminRecord
          | ClientFlag ClientConfig
          | MultipleClientFlag (List ClientConfig)
          | Unknown String

type Msg = AdminMsg AdminRecord
         | SubStringChannel Name
         | PubStringChannel Name String
         | Send Channel ChannelValue
         | ClientMsg ClientConfigMsg

type alias ClientConfigMsg = { config: ClientConfigMsgDetail }
type alias ClientConfigMsgDetail = {
                                     name: String
                                   , description: String
                                   , subscribe: SubMessages
                                   , publish: PubMessages
                                   }

-- this is the client config message that is sent from the server
-- the server will send the remoteAddress for the client
-- the client will send the same configuration message sans the remoteAddress
-- being extra explicit about the message difference here. This may not be 
-- necessary going forward
type alias ClientConfig = { config: ClientConfigDetail }
type alias ClientConfigDetail = 
            {name:String
               ,description:String
               ,subscribe: SubMessages
               ,publish: PubMessages
               ,remoteAddress: IpAddress}

type alias Channel = {name: String, channelType: String, default: String}
type alias AdminRecord = {admin: Bool, no_msgs: Bool}

subscribeToStringChannel : String -> String -> String 
subscribeToStringChannel name default = 
    E.encode 0 
      <| encodeChannel 
      <| Channel name "string" default 

adminWithMsg : String
adminWithMsg = 
    E.encode 0 
      <| encodeAdminConfig 
      <| AdminRecord True True

encodeChannel : Channel -> E.Value
encodeChannel channel =
    E.object
        [ ("name", E.string <| channel.name)
        , ("type", E.string <| channel.channelType)
        , ("default", E.string <| channel.default)
        ]

encodeAdminConfig : AdminRecord -> E.Value
encodeAdminConfig record =
    E.object
        [ ("admin", E.bool <| record.admin)
        , ("no_msgs", E.bool <| record.no_msgs)
        ]    

clientDecoder : D.Decoder Flags
clientDecoder =
    D.map ClientFlag clientConfigDecoder

adminConfigDecoder : D.Decoder Flags
adminConfigDecoder =
    D.map (AdminConfig) 
       <| D.map2 AdminRecord
            (D.field "admin" D.bool)
            (D.field "no_msgs" D.bool)

clientConfigDecoder : D.Decoder ClientConfig
clientConfigDecoder =
    let 
        configuration = 
            D.map5 (ClientConfigDetail)
                (D.field "name" D.string)
                (D.field "description" D.string)
                (D.field "subscribe" decodeSubMessages)
                (D.field "publish" decodePubMessages)
                (D.field "remoteAddress" D.string)
    in
        D.map ClientConfig
            <| D.field "config" configuration

clientConfigMsgDecoder : D.Decoder Msg
clientConfigMsgDecoder =
    let
        configuration =
            D.map4 (ClientConfigMsgDetail)
                (D.field "name" D.string)
                (D.field "description" D.string)
                (D.field "subscribe" decodeSubMessages)
                (D.field "publish" decodePubMessages)

        clientMsg =
            D.map ClientConfigMsg
                <| D.field "config" configuration
    in
        D.map ClientMsg clientMsg
            
subMsgDecoder : D.Decoder Msg
subMsgDecoder =
    D.map2 (PubStringChannel)
            (D.field "name" D.string)
            (D.field "default" D.string)

{-
clientListDecoder : D.Decoder Flags
clientListDecoder =
    let 
        rec = D.field "config" <| D.list clientConfigDecoder
    in
        D.map MultipleClientConfig rec --<| D.list clientConfigDetailDecoder
-}

decodeSubChannel : D.Decoder SubChannel
decodeSubChannel = 
    D.map2 (SubChannel)
        (D.field "name" D.string)
        (D.field "type" D.string)

decodePubChannel : D.Decoder PubChannel
decodePubChannel = 
    D.map3 (PubChannel)
        (D.field "name" D.string)
        (D.field "type" D.string)
        (D.field "default" D.string)

decodeSubMessages : D.Decoder SubMessages
decodeSubMessages =
    D.field "messages" <| D.list decodeSubChannel 

decodePubMessages : D.Decoder PubMessages
decodePubMessages =
    D.field "messages" <| D.list decodePubChannel



decode: D.Decoder Flags
decode =
    D.oneOf [adminConfigDecoder, clientDecoder, D.fail "Could not decode value"]


clientName: ClientConfig -> String
clientName config = .config config |> .name

handleFlag : Flags -> String
handleFlag flag =
    case flag of 
        ClientFlag config ->
            clientName config
        _ -> 
            "unhandled flag"

--clientConfigDecoder : D.Decoder Flags
--clientConfigDecoder =
--    D.map

{-
    sample decoder usage

decodeString clientDecoder sampleString

decodeString adminConfigDecoder sampleString

-}


mockAdminConfig = """
{ "admin" : true
 ,"no_msgs" : true
 }
"""

mockClientConfig = """
{
    "config": {
        "name": "PLAYER 2",
        "description": "PLAYER 2 client ",
        "subscribe": {
            "messages": [{
                "name": "control",
                "type": "string"
            }]
        },
        "publish": {
            "messages": [{
                "name": "player2",
                "type": "string",
                "default": ""
            }]
        },
        "remoteAddress": "127.0.0.1"
    },
    "targetType": "admin"
}
"""

mockMultipleClientConfig = """
[{
    "config": {
        "name": "PLAYER 1",
        "description": "PLAYER 1 client ",
        "subscribe": {
            "messages": [{
                "name": "control",
                "type": "string"
            }]
        },
        "publish": {
            "messages": [{
                "name": "player1",
                "type": "string",
                "default": ""
            }]
        },
        "remoteAddress": "127.0.0.1"
    }
}
, {
    "config": {
        "name": "PLAYER 1",
        "description": "PLAYER 1 client ",
        "subscribe": {
            "messages": [{
                "name": "control",
                "type": "string"
            }]
        },
        "publish": {
            "messages": [{
                "name": "player1",
                "type": "string",
                "default": ""
            }]
        },
        "remoteAddress": "127.0.0.1"
    }
}]
"""

test : Result String Msg
test = D.decodeString clientConfigMsgDecoder mockClientConfig

