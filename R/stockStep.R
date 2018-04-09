#' @export
startStockfish = function(){
    stockfish = system2('which','stockfish',stdout = TRUE)
    stockfish = subprocess::spawn_process(stockfish)
    return(stockfish)
}

#' Title
#'
#' @param board 
#' @param movetime 
#' @param translate 
#' @param stockfish 
#'
#' @return
#' @export
#'
#' @examples
stockStep = function(board, movetime = 5000, translate = TRUE, stockfish = NULL){
    if(is.null(stockfish)){
        if(Sys.info()['sysname'] =='Windows'){
            stockfish = system2('where','stockfish',stdout = TRUE)
        } else {
            stockfish = system2('which','stockfish',stdout = TRUE)
        }
        stockfish = subprocess::spawn_process(stockfish)
        on.exit(subprocess::process_kill(stockfish))
    }
    # stockfish = subprocess::spawn_process(stockfish)
    # process_read(stockfish, PIPE_STDOUT, timeout = 1000,  flush = FALSE)
    subprocess::process_write(stockfish, glue::glue('position fen {board$fen()}\n\n'))
    subprocess::process_write(stockfish, glue::glue('go movetime {movetime}\n\n'))
    Sys.sleep(movetime/1000+0.1)
    out = ''
    while(!grepl(pattern = 'bestmove',x = out)){
        out = process_read(stockfish, PIPE_STDOUT, timeout = 1000,  flush = TRUE)
        out = out[length(out)]
    }
    # subprocess::process_kill(stockfish)
    
    bestmove = stringr::str_extract(out, '(?<=bestmove )[a-zA-Z0-9]+')
    ponder = stringr::str_extract(out, '(?<=ponder )[a-zA-Z0-9]+')
    
    out = list(bestmove = bestmove,
               ponder = ponder)
    if(translate){
        for(x in c('bestmove','ponder')){
            boardClone = rchess::Chess$new()
            boardClone$load(board$fen())
            if(x=='ponder'){ # on ponder
                boardClone$move(out$bestmove)
            }
            out[[x]] = translateMove(out[[x]],boardClone)
        }
    }
    return(out)
}
