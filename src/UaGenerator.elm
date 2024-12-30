module UaGenerator exposing (..)

import Html exposing (u)
import List exposing (..)
import Random
import Random.Extra exposing (andMap)



-- userAgent : Random.Generator String


type alias UaRecord =
    { chromeVerMajor : Int
    , chromeVerOther : List Int
    , os : String
    , appleWebkitVer : String
    , isMobile : Bool
    }


uaReducedOs : ( String, List String )
uaReducedOs =
    ( "Macintosh; Intel Mac OS X 10_15_7", [ "Windows NT 10.0; Win64; x64", "X11; Linux x86_64", "Linux; Android 10; K" ] )


-- randomList : List a -> Random.Generator a
-- randomList (x::xs) = Random.uniform x xs
-- randomList _ = Random.constant 0

{--
Mozilla/5.0 ({os}) AppleWebKit/{engv} (KHTML, like Gecko) Chrome/{browserv} Safari/{engv}
Mozilla/5.0 ({os/mac}) AppleWebKit/{engv} (KHTML, like Gecko) Version/{browserv} Safari/{engv}

iPad
Mozilla/5.0 (iPad; CPU OS 8_4_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) CriOS/45.0.2454.68 Mobile/12H321 Safari/600.1.4
--}

uaGenerator : Random.Generator String
uaGenerator =
    let
        makeString : UaRecord -> String
        makeString info =
            let
                chromeVer =
                    String.fromInt info.chromeVerMajor
                        ++ (info.chromeVerOther
                                |> List.map String.fromInt
                                |> List.intersperse "."
                                |> String.concat
                           )
            in
            "Mozilla/5.0 (" ++ info.os ++ ") AppleWebKit/" ++ info.appleWebkitVer ++ " (KHTML, like Gecko) Chrome/" ++ chromeVer ++ " Safari/" ++ info.appleWebkitVer
    in
    Random.map (\x -> x < 0.25) (Random.float 0 1)
        |> Random.andThen
            (\useUaReduction ->
                let
                    verMajor =
                        Random.int 90 130

                    verOther =
                        Random.int 0 10 |> Random.list 3

                    os = Random.uniform (Tuple.first uaReducedOs) (Tuple.second uaReducedOs)

                    appleWebkitVer =
                        Random.weighted ( 95, "537.36" ) [ ( 5, "605.1.15" ) ]
                in
                if useUaReduction then
                    Random.map UaRecord verMajor
                        |> andMap (Random.constant [ 0, 0, 0 ])
                        |> andMap os
                        |> andMap (Random.constant "537.36")
                        |> andMap (Random.constant False)
                        |> Random.map makeString

                else
                    Random.map UaRecord verMajor
                        |> andMap verOther
                        |> andMap os
                        |> andMap appleWebkitVer
                        |> andMap (Random.uniform True [ False ])
                        |> Random.map makeString
            )



-- Mac: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.0.0 Mobile Safari/537.36
-- Windows: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.0.0 Mobile Safari/537.36
-- ChromeOS: Mozilla/5.0 (X11; CrOS x86_64 14541.0.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.0.0 Mobile Safari/537.36
-- Linux: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.0.0 Mobile Safari/537.36
-- Android: Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.0.0 Mobile Safari/537.36
