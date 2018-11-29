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
stockStep = function(board, movetime = 5000, wtime = NULL, btime = NULL, depth = NULL, translate = TRUE, stockfish = NULL){
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
    if(!is.null(movetime)){
        subprocess::process_write(stockfish, glue::glue('go movetime {movetime}\n\n'))
        Sys.sleep(movetime/1000+0.1)
    } else if(!is.null(wtime) & !is.null(btime)){
        subprocess::process_write(stockfish, glue::glue('go wtime {wtime} btime {btime}\n\n'))
    } else if(!is.null(depth)){
        subprocess::process_write(stockfish, glue::glue('go depth {depth}\n\n'))
    }
    
    # Sys.sleep(movetime/1000+0.1)
    out = ''
    while(!grepl(pattern = 'bestmove',x = out[length(out)])){
        out = c(out,subprocess::process_read(stockfish, subprocess::PIPE_STDOUT, timeout = 1000,  flush = TRUE))
        # out = out[length(out)]
    }
    # subprocess::process_kill(stockfish)
    
    bestmove = stringr::str_extract(out[length(out)], '(?<=bestmove )[a-zA-Z0-9]+')
    ponder = stringr::str_extract(out[length(out)], '(?<=ponder )[a-zA-Z0-9]+')
    score = stringr::str_extract(out[length(out)-1],'(?<=cp )[0-9]*') %>% as.integer()
    
    out = list(bestmove = bestmove,
               ponder = ponder,
               score = score)
    if(translate){
        for(x in c('bestmove','ponder')){
            boardClone = rchess::Chess$new()
            boardClone$load(board$fen())
            if(x=='ponder'){ # on ponder
                boardClone$move(out$bestmove)
            }
            matches = boardClone$moves(verbose = TRUE) %>% 
                mutate(ft = paste0(from, to)) %>% 
                filter(ft == stringr::str_extract(out[[x]],pattern = '[a-z][0-9][a-z][0-9]')) %$% 
                san
            if(length(matches)>1){
                out[[x]] = matches[grepl(stringr::str_extract(out[[x]],'(?<=[0-9])[a-z]$'),matches,ignore.case = TRUE)]
            } else{
                out[[x]] = matches
            }
            assertthat::assert_that(length(out[[x]])==1)
            
            # out[[x]] = translateMove(out[[x]],boardClone)
        }
    }
    return(out)
}
