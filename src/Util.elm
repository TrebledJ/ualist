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

appendIfT : Bool -> List a -> List a -> List a
appendIfT cond ys xs = if cond then xs ++ ys else xs

if0then : Int -> Int -> Int
if0then default test = if test == 0 then default else test
