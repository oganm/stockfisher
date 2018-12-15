#' @export
gameState = function(board){
    if(board$game_over()){
        if(board$in_threefold_repetition()){
            return('draw-threefold repetition')
        } else if(board$in_stalemate()){
            return('draw-stalemate')
        } else if(board$in_checkmate()){
            winner = switch(board$turn(),
                            'w' = 'b',
                            'b' = 'w')
            return(paste('checkmate',winner))
        } else if(board$insufficient_material()){
            return('draw insufficient material')
        }
    } else{
        return('ongoing')
    }
}