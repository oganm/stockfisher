#' Title
#'
#' @param move 
#' @param board 
#'
#' @return
#' @export
#'
#' @examples
translateMove = function(move, board){
    boardClone = Chess$new()
    boardClone$load(board$fen())
    if(is.na(move)){
        return(NA)
    }
    moved = move %>% substr(1,2)
    moveOn = move %>% substr(3,4)
    promotion = move %>% substr(5,5) %>% toupper()
    whatMoved = boardClone$get(moved)$type %>% toupper()
    isPawn = (whatMoved %in% "P") 
    isCapture = !is.null(boardClone$get(moveOn)$type)
    isPassant = (whatMoved %in% 'P') & (moveOn == (boardClone$fen() %>% strsplit(' ') %>% {.[[1]][4]}))
    isCastling = (move %in% c('e1g1','e1c1','e8c8','e8g8')) & (whatMoved == 'K')
    if(isCastling){
        if(move %in% c('e1b1','e8c8')){
            move = 'O-O-O'
        } else if(move %in% c('e1g1','e8g8')){
            move = 'O-O'
        }
    } else if(isPassant){
        move = paste0(substr(moved,1,1),
                          'x',
                          moveOn)
    }else if (isCapture & isPawn){
        move = paste0(substr(moved,1,1),
                          'x',
                          moveOn)
    } else if (isPawn & !isCapture){
        move = moveOn
    } else if(!isPawn & ! isCapture){
        move = paste0(whatMoved,moveOn)
    } else if(!isPawn & isCapture){
        move = paste0(whatMoved,
                          'x',
                          moveOn)
    }
    if(promotion != ''){
        move = paste0(move,'=',promotion)
    }
    # is this a check? if something's wrong return an alternative string
    fixNeeded = tryCatch(boardClone$move(move),
                         error = function(e){
                             move = paste0(move,'+')
                         })
    # is there disambiguity
    if('character' %in% class(fixNeeded)){
        fixNeeded = tryCatch(boardClone$move(fixNeeded),
                             error = function(e){
                                 move = paste0(whatMoved,
                                                   substr(moved,1,1),
                                                   moveOn)
                             })
    }
    if('character' %in% class(fixNeeded)){
        fixNeeded = tryCatch(boardClone$move(fixNeeded),
                             error = function(e){
                                 move = paste0(whatMoved,
                                                   substr(moved,2,2),
                                                   moveOn)
                             })
    }
    # if there is a check
    if('character' %in% class(fixNeeded)){
        fixNeeded = tryCatch(boardClone$move(fixNeeded),
                             error = function(e){
                                 move = paste0(whatMoved,
                                                   substr(moved,2,2),
                                                   moveOn,'+')
                             })
    }
    if('character' %in% class(fixNeeded)){
        fixNeeded = tryCatch(boardClone$move(fixNeeded),
                             error = function(e){
                                 move = paste0(whatMoved,
                                                   substr(moved,1,1),
                                                   moveOn,'+')
                             })
    }
    # if checkmate
    if('character' %in% class(fixNeeded)){
        fixNeeded = tryCatch(boardClone$move(fixNeeded),
                             error = function(e){
                                 move = paste0(move,'#')
                             })
    }
    
    if('character' %in% class(fixNeeded)){
        fixNeeded = tryCatch(boardClone$move(fixNeeded),
                             error = function(e){
                                 move = paste0(whatMoved,
                                               substr(moved,1,1),
                                               moveOn,'#')
                             })
    }
    
    if('character' %in% class(fixNeeded)){
        fixNeeded = tryCatch(boardClone$move(fixNeeded),
                             error = function(e){
                                 move = paste0(whatMoved,
                                               substr(moved,2,2),
                                               moveOn,'#')
                             })
    }
    
    
    if('character' %in% class(fixNeeded)){
        fixNeeded = tryCatch(boardClone$move(fixNeeded),
                             error = function(e){
                                 stop('Failed to parse move')
                             })
    }
    move = fixNeeded$history()
    return(move)
}
