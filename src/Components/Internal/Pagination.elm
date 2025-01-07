module Components.Internal.Pagination exposing (..)

import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick)
import Components.Internal.Column exposing (Pipe)
import Components.Internal.Config exposing (..)
import Components.Internal.Data exposing (..)
import Components.Internal.Selection exposing (..)
import Components.Internal.State exposing (..)
import Components.Internal.Util exposing (..)
import Components.Table.Types exposing (..)


tableFooterContent : Type -> Pipe msg -> Pipe msg -> Int -> Int -> Int -> Html msg
tableFooterContent type_ pipeInt pipeExt byPage page total =
    let
        nb =
            ceiling (toFloat total / toFloat byPage)

        ( ia, ib, ic ) =
            iff (nb == 1) ( 0, 0, 0 ) (pagIndex nb page)

        pipe =
            iff (type_ == Static) pipeInt pipeExt
    in
    div [ class "table-footer" ]
        [ nav
            [ class "pagination is-centered"
            , attribute "role" "navigation"
            , attribute "aria-label" "pagination"
            ]
            [ ifh (nb > 1) <|
                a
                    [ class <| "pagination-previous" ++ iff (page == 0) " is-disabled" ""
                    , onClick <| pipe <| \state -> { state | page = state.page - 1 }
                    ]
                    [ text "Previous" ]
            , ifh (nb > 1) <|
                a
                    [ class <| "pagination-next" ++ iff (page == nb - 1) " is-disabled" ""
                    , onClick <| pipe <| \state -> { state | page = page + 1 }
                    ]
                    [ text "Next page" ]
            , ul [ class "pagination-list" ]
                -- First page
                [ ifh (nb > 3) <| paginationLink pipe page 0
                , ifh (nb > 3) <| paginationEllipsis

                -- Middle (m-1) m (m+1)
                , ifh (nb > 1) <| paginationLink pipe page ia
                , ifh (nb > 0) <| paginationLink pipe page ib
                , ifh (nb > 2) <| paginationLink pipe page ic

                -- Last page
                , ifh (nb > 4) <| paginationEllipsis
                , ifh (nb > 4) <| paginationLink pipe page (nb - 1)
                ]
            ]
        ]


paginationEllipsis =
    span [ class "pagination-ellipsis" ] [ text "…" ]


paginationLink pipe page i =
    a
        [ class <| "pagination-link " ++ iff (page == i) "is-current" ""
        , attribute "aria-label" <| "Goto page " ++ String.fromInt (i + 1)
        , attribute "aria-current" <| iff (page == i) "page" ""
        , onClick <| pipe <| \state -> { state | page = i }
        ]
        [ text <| String.fromInt (i + 1) ]


pagIndex : Int -> Int -> ( Int, Int, Int )
pagIndex n c =
    if c == 0 then
        if n > 3 then
            let
                m =
                    floor (toFloat n / 2)
            in
            ( m - 1, m, m + 1 )

        else
            ( 0, 1, 2 )

    else if c == 1 then
        if n > 3 then
            ( 1, 2, 3 )

        else
            ( 0, 1, 2 )

    else if c == n - 1 then
        if n > 3 then
            ( n - 4, n - 3, n - 2 )

        else
            ( n - 3, n - 2, n - 1 )

    else if c == n - 2 then
        ( n - 4, n - 3, n - 2 )

    else
        ( c - 1, c, c + 1 )
