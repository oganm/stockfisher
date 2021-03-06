
#' Calculate next move based on current position
#' 
#' Given a board or a position string that can be accepted by UCI, calculate the
#' next best move, opponents best move (ponder) and which player has the upper hand
#' (score)
#'
#' @param board is an board generated by \code{rchess}. Mandatory if \code{translate} = TRUE
#' @param posString is a string that can be accepted by a UCI as an alternative to \code{board}
#' Will be ignored if \code{board} is defined
#' @param movetime How much time should the engine spend on thinking
#' @param wtime Alternative to \code{movetime}, must be provided with btime. How much time 
#' the white player has on the clock
#' @param btime Alternative to \code{movetime}, must be provided with wtime. How much time the black
#' player has on the clock.
#' @param depth Alternative to \code{movetime}. The search depth.
#' @param translate Should the move from the UCI be translated into standard chess notation. This format
#' is accepted by \code{rchess} boards. You need to provide a \code{board} for this option to work instead
#' of a \code{posString}
#' @param ponder Not implemented yet. Should the engine continue to ponder
#' @param stockfish A running UCI engine process. If NULL, a stockfish process will be spawned and stopped
#' at the end of function execution.
#'
#' @return a list containing 4 elements. \code{bestmove} is the calculated best move by the engine.
#' \code{ponder} is the opponent's best move against the engine's best move. \code{score} is engine's
#' perception of how good it's position is. \code{scoreType} is the type of score. If its cp, upperbound or
#' lowerbound, the score estimate is in centipawns. If it is mate, the score is a guess of how many turns till
#' the opponents demise (or the engine's if its negative).
#' 
#' @export
#'
#' @examples
stockStep = function(board = NULL, posString = NULL, movetime = NULL, wtime = NULL, btime = NULL, depth = NULL, translate = FALSE, ponder = FALSE, stockfish = NULL){
    # send a stop just in case it was pondering
    # print('stockstep')
    # print(board$ascii())
    subprocess::process_write(stockfish, glue::glue('stop\n\n'))
    # cleanup any previous messages that might still be there
    leftovers = subprocess::process_read(stockfish, subprocess::PIPE_STDOUT, timeout = 0,  flush = TRUE)
    # print(leftovers)
    if(is.null(stockfish) & ponder){
        stop("You need to provide a stockfish session to enable pondering")
    } else if(ponder){
        tictoc::tic()
    }
    if(is.null(stockfish)){
        stockfish = startStockfish()
        on.exit(subprocess::process_kill(stockfish))
    }
    # stockfish = subprocess::spawn_process(stockfish)
    # process_read(stockfish, PIPE_STDOUT, timeout = 1000,  flush = FALSE)
    if(!is.null(board)){
        # i used to send fen information to the engine by itself but that causes
        # engine not to notice if it's getting into a 3fold repetition state. 
        # now I send the 
        if(length(board$history())>0){
            moves = historyToLong(board$history(verbose=TRUE))
            oldFen = stringr::str_extract(board$pgn(),'(?<=FEN ").*?(?=")')
            if(is.na(oldFen)){
                subprocess::process_write(stockfish, glue::glue("position startpos moves {paste(moves,collapse = ' ')}\n\n"))
            } else{
                subprocess::process_write(stockfish, glue::glue("position fen {oldFen} moves {paste(moves,collapse = ' ')}\n\n"))
            }
        } else{
            subprocess::process_write(stockfish, glue::glue('position fen {board$fen()}\n\n'))
        }
    } else if(!is.null(posString)){
        # translate must be false if posString is used
        subprocess::process_write(stockfish, glue::glue('position {posString}\n\n'))
    }
    
    if(!is.null(movetime)){
        subprocess::process_write(stockfish, glue::glue('go movetime {movetime}\n\n'))
        Sys.sleep(movetime/1000)
    } else if(!is.null(wtime) & !is.null(btime)){
        subprocess::process_write(stockfish, glue::glue('go wtime {wtime} btime {btime}\n\n'))
    } else if(!is.null(depth)){
        subprocess::process_write(stockfish, glue::glue('go depth {depth}\n\n'))
    }
    
    # Sys.sleep(movetime/1000+0.1)
    out = readBestMove(stockfish)
    
    if(ponder & !is.na(out$ponder)){
        ponderfun(board,posString,out,stockfish, tictoc::toc(quiet = TRUE), movetime, wtime,btime,depth)
    }
    
    if(translate){
        out = translateMove(board,out)
    }

    return(out)
}

ponderfun = function(board = NULL,posString = NULL,out,stockfish,toc,movetime=NULL,wtime=NULL,btime=NULL,depth=NULL){
    # print('ponder func')
    # print(board$ascii())
    time = toc
    elapsed = 1000*(time$toc - time$tic)
    if(!is.null(board)){
        boardClone = rchess::Chess$new()
        boardClone$load(board$fen())
        out = translateMove(board,out)
        boardClone$move(out$bestmove)
        boardClone$move(out$ponder)
        
        if(length(boardClone$history())>0){
            moves = historyToLong(boardClone$history(verbose=TRUE))
            oldFen = stringr::str_extract(boardClone$pgn(),'(?<=FEN ").*?(?=")')
            if(is.na(oldFen)){
                subprocess::process_write(stockfish, glue::glue("position startpos moves {paste(moves,collapse = ' ')}\n\n"))
            } else{
                subprocess::process_write(stockfish, glue::glue("position fen {oldFen} moves {paste(moves,collapse = ' ')}\n\n"))
            }
        } else{
            subprocess::process_write(stockfish, glue::glue('position fen {boardClone$fen()}\n\n'))
        }
        
        # subprocess::process_write(stockfish, glue::glue('position fen {boardClone$fen()}\n\n'))
    } else if (!is.null(posString)){
        anneal = paste(out$bestmove,out$ponder)
        if(grepl('moves',posString)){
            newPos = paste(posString,anneal)
        } else{
            newPos = paste(posString,'moves',anneal)
        }
        subprocess::process_write(stockfish, glue::glue('position {newPos}\n\n'))
        
    }
    
    if(!is.null(movetime)){
        subprocess::process_write(stockfish, glue::glue('go ponder movetime {movetime}\n\n'))
        
    } else if(!is.null(wtime) & !is.null(btime)){
        # imagine both players have spent the time you spent last turn
        # this is partially because I don't know which player's turn is it
        # unless the input is a board or a fen. this should be fine in most cases...
        btime = btime - elapsed
        wtime = wtime - elapsed
        subprocess::process_write(stockfish, glue::glue('go ponder wtime {wtime} btime {btime}\n\n'))
    } else if(!is.null(depth)){
        subprocess::process_write(stockfish, glue::glue('go ponder depth {depth}\n\n'))
    }
}

historyToLong = function(history){
    if(!'promotion' %in% colnames(history)){
        history$promotion = NA
    }
    history$promotion[is.na(history$promotion)] = ''
    paste0(history$from,history$to,history$promotion)
}

translateMove = function(board,out){
    # print('translating')
    # print(board$ascii())
    # print(out)
    for(x in c('bestmove','ponder')){
        if(is.na(out[[x]])){
            next()
        }
        boardClone = rchess::Chess$new()
        boardClone$load(board$fen())
        if(x=='ponder'){ # on ponder
            boardClone$move(out$bestmove)
        }
        matches = boardClone$moves(verbose = TRUE) %>% 
            dplyr::mutate(ft = paste0(from, to)) %>% 
            dplyr::filter(ft == stringr::str_extract(out[[x]],pattern = '[a-z][0-9][a-z][0-9]')) %$% 
            san
        if(length(matches)>1){
            out[[x]] = matches[grepl(stringr::str_extract(out[[x]],'(?<=[0-9])[a-z]$'),matches,ignore.case = TRUE)]
        } else{
            out[[x]] = matches
        }
        assertthat::assert_that(length(out[[x]])==1)
        
        # out[[x]] = translateMove(out[[x]],boardClone)
    }
    return(out)
}

readBestMove = function(stockfish){
    out = ''
    while(!grepl(pattern = 'bestmove',x = out[length(out)])){
        out = c(out,subprocess::process_read(stockfish, subprocess::PIPE_STDOUT, timeout = 1000,  flush = TRUE))
        # out = out[length(out)]
    }
    # cat(out,sep='\n')
    # subprocess::process_kill(stockfish)
    bestmove = stringr::str_extract(out[length(out)], '(?<=bestmove )[a-zA-Z0-9]+')
    ponder = stringr::str_extract(out[length(out)], '(?<=ponder )[a-zA-Z0-9]+')
    scores = out[grepl(pattern = 'score (cp|mate|upperbound|lowerbound)',out)]
    score = stringr::str_extract(scores[length(scores)],'(?<=(cp|mate|upperbound|lowerbound) )[\\-0-9]*') %>% as.integer()
    # if(score==0){
    #     print(out)
    # }
    scoreType = stringr::str_extract(scores[length(scores)],'(?<=score )(cp|mate|upperbound|lowerbound)')
    time = stringr::str_extract(scores[length(scores)],'(?<=time )[0-9]*') %>% as.integer
    
    out = list(bestmove = bestmove,
               ponder = ponder,
               score = score,
               scoreType = scoreType,
               time = time)
    return(out)
}

#' @export
ponderhit = function(board = NULL,posString = NULL,movetime = NULL, wtime = NULL, btime = NULL, depth = NULL, translate = FALSE, ponder = FALSE, stockfish = NULL){
    if(ponder){
        tictoc::tic()
    }
    # print('ponderhit function')
    # print(board$ascii())
    # browser()
    
    # cleanup any previous messages that might still be there
    leftovers = subprocess::process_read(stockfish, subprocess::PIPE_STDOUT, timeout = 0,  flush = TRUE)
    
    subprocess::process_write(stockfish, glue::glue('ponderhit\n\n'))
    
    out = readBestMove(stockfish)
    
    if(ponder & !is.na(out$ponder)){
        ponderfun(board,posString,out,stockfish, tictoc::toc(quiet = TRUE), movetime, wtime,btime,depth)
    }
    
    if(translate){
        out = translateMove(board,out)
    }
    return(out)
}