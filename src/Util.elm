module Util exposing (..)

import Http exposing (Error(..))

iff : Bool -> a -> a -> a
iff cond a b =
    if cond then
        a

    else
        b
        
errorToString : Error -> String
errorToString error =
    case error of
        BadUrl url ->
            "The URL " ++ url ++ " was invalid."
        Timeout ->
            "Unable to reach the server, try again"
        NetworkError ->
            "Unable to reach the server, check your network connection"
        BadStatus 500 ->
            "The server had a problem, try again later"
        BadStatus 400 ->
            "Verify your information and try again"
        BadStatus s ->
            "Unknown error: status code " ++ String.fromInt s
        BadBody errorMessage ->
            errorMessage