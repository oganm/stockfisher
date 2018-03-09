library(subprocess)
library(rchess)

stockStep = function(board, movetime = 5000, translate = TRUE){
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
    
    bestmove = stringr::str_extract(out, '(?<=bestmove )[a-zA-Z0-9]+')
    ponder = stringr::str_extract(out, '(?<=ponder )[a-zA-Z0-9]+')
    
    out = list(bestmove = bestmove,
               ponder = ponder)
    
    if(translate){
        boardClone = Chess$new()
        boardClone$load(board$fen())
        for(i in 1:length(out)){
            if(is.na(out[[i]])){
                next
            }
            move = out[[i]]
            moved = move %>% substr(1,2)
            moveOn = move %>% substr(3,4)
            whatMoved = board$get(moved)$type %>% toupper()
            isPawn = whatMoved %in% "P"
            isCapture = !is.null(board$get(moveOn)$type)
            
            isCastling = out[[i]] %in% c('e1g1','e1b2','e8b8','e8g8')
            if(isCastling){
                if(out[[i]] %in% c('e1b1','e8b8')){
                    out[[i]] = 'O-O-O'
                } else if(out[[i]] %in% c('e1g1','e8g8')){
                    out[[i]] = 'O-O'
                }
            } else if (isCapture & isPawn){
                out[[i]] = paste0(substr(moved,1,1),
                                  'x',
                                  moveOn)
            } else if (isPawn & !isCapture){
                out[[i]] = moveOn
            } else if(!isPawn & ! isCapture){
                out[[i]] = paste0(whatMoved,moveOn)
            } else if(!isPawn & isCapture){
                out[[i]] = paste0(whatMoved,
                                  'x',
                                  moveOn)
            }
            # is this a check?
            fixNeeded = tryCatch(boardClone$move(out[[i]]),
                     error = function(e){
                         out[[i]] = paste0(out[[i]],'+')
                     })
            # is there disambiguity
            if('character' %in% class(fixNeeded)){
                fixNeeded = tryCatch(boardClone$move(fixNeeded),
                         error = function(e){
                             out[[i]] = paste0(whatMoved,
                                               substr(moved,1,1),
                                               moveOn)
                         })
            }
            if('character' %in% class(fixNeeded)){
                fixNeeded = tryCatch(boardClone$move(fixNeeded),
                                     error = function(e){
                                         out[[i]] = paste0(whatMoved,
                                                           substr(moved,1,1),
                                                           moveOn)
                                     })
            }
            out[[i]] = fixNeeded$history()
        }
        
    }
    return(out)
}

board = Chess$new()
while(TRUE){
    move = stockStep(board,movetime= 1000)$bestmove
    print(move)
    board$move(move)
    board$ascii()
}
move = stockStep(board,movetime= 1000)$bestmove
print(move)
board$move(move)
board$ascii()

