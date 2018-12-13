estimateOverhead = function(stockfish,movetime = 1000, times = 5){
    benchmark = microbenchmark::microbenchmark(stockStep(posString = 'startpos',movetime =  movetime,stockfish = stockfish),
                                               unit= 'ms', times = times)
    
    benchmark = summary(benchmark)
    benchmark$min = benchmark$min - movetime
    benchmark$lq = benchmark$lq - movetime
    benchmark$mean = benchmark$mean - movetime
    benchmark$median = benchmark$median - movetime
    benchmark$uq = benchmark$uq - movetime
    benchmark$max = benchmark$max - movetime
    
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

