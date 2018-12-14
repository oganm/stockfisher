estimateOverhead = function(stockfish,movetime = NULL, wtime = NULL, btime=NULL,depth = NULL,translate = FALSE,times = 5){
    
    
    steps = lapply(seq_len(times),function(x){
        stockStep(posString = 'startpos',
                                    movetime =  movetime,
                                    wtime = wtime,
                                    btime = btime,
                                    depth = depth,
                                    stockfish = stockfish)})
    
    steps = list()
    benchmark = microbenchmark::microbenchmark({
        stockStep(posString = 'startpos',
                  movetime =  movetime,
                  wtime = wtime,
                  btime = btime,
                  depth = depth,
                  stockfish = stockfish) -> step
        steps = c(steps,list(step))
        assign('steps',steps,envir = parent.frame())
    },
    unit= 'ms', times = times)
    time = steps %>% sapply(function(x){x$time})
    
    benchmark$time = benchmark$time - time*1000000
    
    benchmark = summary(benchmark)
    return(benchmark)
    
}

#' @export
setOptions = function(stockfish,optionList){
    names(optionList) %>% sapply(function(x){
        subprocess::process_write(stockfish, glue::glue('setoption name {x} value {optionList[[x]]}\n\n'))
    })
    
    return(invisible(NULL))
}

#' @export
getOptions = function(stockfish){
    subprocess::process_write(stockfish, glue::glue('uci\n\n'))
    out = ''
    while(!grepl(pattern = 'uciok',x = out[length(out)])){
        out = c(out,subprocess::process_read(stockfish, subprocess::PIPE_STDOUT, timeout = 1000,  flush = TRUE))
        # out = out[length(out)]
    }
    name = out %>% stringr::str_extract('(?<=option name ).*?(?= type)') %>% as.character
    info = out %>% stringr::str_extract('type .*?$') %>% as.character
    # default = out %>% stringr::str_extract('(?<=default ).*?(?=$)') %>% as.character
    
    data.frame(name,info,stringsAsFactors = FALSE) %>% dplyr::filter(!is.na(name))
}

