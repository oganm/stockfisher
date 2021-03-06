# returns from white perspective
# game is either a character pgn or a board from rchess
#' @export
gameAnalysis = function(game,movetime=5000,depth = NULL,stockfish = NULL,progress = TRUE){
    if(is.null(stockfish)){
        stockfish = startStockfish()
        on.exit(subprocess::process_kill(stockfish))
    }
    if('character' %in% class(game)){
        pgn = game
        game = rchess::Chess$new()
        game$load_pgn(pgn)
    }
    assertthat::assert_that('Chess' %in% class(game),msg = 'game should be a RChess board or a pgn character string')
    
    moves = game$history(verbose= TRUE)
    stockmoves = historyToLong(moves)
    
    if(progress){
        pb = txtProgressBar(min = 0,max = length(stockmoves),style = 3)
    }
    
    evaluations = lapply(c(0,seq_along(stockmoves)),function(i){
        if(progress){
            setTxtProgressBar(pb,value = i)
        }
        if(i == 0){
            init = 'startpos'
        } else{
            init = paste('startpos moves',paste(stockmoves[1:i],collapse = ' '))
        }
        out = stockStep(posString = init,movetime = movetime,depth = depth,translate = FALSE,stockfish = stockfish)
        
        if((i %% 2)==1){
            out$score = - out$score 
        }
        
        return(out)
    })
    
    evaluations = data.frame(bestmove = evaluations %>% purrr::map_chr('bestmove'),
                             ponder = evaluations %>% purrr::map_chr('ponder'),
                             score = evaluations %>% purrr::map_int('score'),
                             scoreType = evaluations %>% purrr::map_chr('scoreType'),
                             stringsAsFactors = FALSE)
    
    return(evaluations)
}