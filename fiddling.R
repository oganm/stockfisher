library(subprocess)
library(rchess)
board = Chess$new()

stockStep = function(board, movetime = 5000){
    stockfish = system2("which","stockfish",stdout = TRUE)
    stockfish = subprocess::spawn_process(stockfish)
    process_read(stockfish, PIPE_STDOUT, timeout = 1000,  flush = FALSE)
    subprocess::process_write(stockfish, glue::glue('position fen {board$fen()}\n\n'))
    subprocess::process_write(stockfish, glue::glue('go movetime {movetime}\n\n'))
    Sys.sleep(movetime/1000+0.5)
    out = ''
    while(!grepl(pattern = 'bestmove',x = out)){
        out = process_read(stockfish, PIPE_STDOUT, timeout = 1000,  flush = TRUE)
        out = out[length(out)]
    }
    process_kill(stockfish)
    
    bestmove = stringr::str_extract(out, '(?<=bestmove )....')
    ponder = stringr::str_extract(out, '(?<=ponder )....')
    # out = list(bestmove = bestmove,
    #            ponder = ponder)
    # for(i in 1:length(out)){
    #     out[[i]] %>% stringr::str_ext 
    # }
    
    return(list(bestmove = bestmove,
                ponder = ponder))
}


