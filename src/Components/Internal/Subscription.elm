module Components.Internal.Subscription exposing (..)

import Browser.Events
import Components.Internal.Column exposing (Pipe)
import Components.Internal.Config exposing (..)
import Components.Internal.Data exposing (..)
import Components.Internal.State exposing (..)
import Json.Decode as Decode
import Components.UaDropdownMultiSelect as UaDropdown


subscriptions : Config a b tbstate msg -> Model a -> Sub msg
subscriptions config model =
    if isModal model then
        Browser.Events.onMouseDown (outsideTarget (pipeInternal config model) "dropdown")

    else
        Sub.none


isModal : Model a -> Bool
isModal (Model { state }) =
    state.ddColumns.isOpen || state.ddPagination.isOpen


outsideTarget : Pipe msg -> String -> Decode.Decoder msg
outsideTarget pipe dropdownId =
    Decode.field "target" (isOutsideDropdown dropdownId)
        |> Decode.andThen
            (\isOutside ->
                if isOutside then
                    Decode.succeed <|
                        pipe <|
                            \state -> state

                else
                    Decode.fail "inside dropdown"
            )


isOutsideDropdown : String -> Decode.Decoder Bool
isOutsideDropdown dropdownId =
    Decode.oneOf
        [ Decode.field "id" Decode.string
            |> Decode.andThen
                (\id ->
                    if dropdownId == id then
                        -- found match by id
                        Decode.succeed False

                    else
                        -- try next decoder
                        Decode.fail "continue"
                )
        , Decode.lazy (\_ -> isOutsideDropdown dropdownId |> Decode.field "parentNode")

        -- fallback if all previous decoders failed
        , Decode.succeed True
        ]
