module ButtonTest exposing (..)

import Browser
import Html.Styled exposing (toUnstyled)
import Components.CopyToClipboardButton exposing (..)

type alias State = {
        counter : Int
    }


main = Browser.element {
        init = \() -> (init { counter = 42 }, Cmd.none),
        update = update,
        subscriptions = subscriptions,
        view = toUnstyled << view {
            onCopy = (\x -> "copy text " ++ String.fromInt x.counter)
        }
    }