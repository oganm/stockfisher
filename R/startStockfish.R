#' Start stockfish
#' 
#' Starts a stockfish process from binaries included in the package. Functions
#' in stockfisher accept a stockfish process to keep things quick. If a process
#' is not provided they will spawn one of their own and close it after they are done.
#' This will add some overhead that.
#' 
#' @examples
#' stockfish = startStockfish()
#' stockStep(posString = 'startpos',movetime = 1000,stockfish = stockfish)
#' stopStockfish()
#' 
#' @export
startStockfish = function(...){
    if(Sys.info()['sysname'] =='Windows'){
        stockfish = system.file('Windows/stockfish_10_x64.exe',package = 'stockfisher')
    } else if(Sys.info()['sysname'] == 'Linux'){
        stockfish = system.file('Linux/stockfish_10_x64',package = 'stockfisher')
    } else{
        stockfish = system.file('Mac/stockfish_10_64',package = 'stockfisher')
    }
    stockfish = subprocess::spawn_process(stockfish,...)
    return(stockfish)
}


#' Stop running stockfish process
#' 
#' Use for cleanup
#' 
#' @param stockfish A running stockfish (or technically any other process started by \code{subprocess::spawn_process}) process.
#' 
#' @examples
#' stockfish = startStockfish()
#' stockStep(posString = 'startpos',movetime = 1000,stockfish = stockfish)
#' stopStockfish()
#' @export
stopStockfish = function(stockfish){
    subprocess::process_kill(stockfish)
}