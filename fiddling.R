library(subprocess)
library(rchess)
library(dplyr)
devtools::load_all()


stockfish = system2('which','stockfish',stdout = TRUE)
stockfish = subprocess::spawn_process(stockfish)

board = Chess$new()
while(board$game_over() == FALSE){
    turn = board$turn()
    if(turn =='w'){
        movetime = 2000
    } else{
        movetime = 1000
    }
    move = stockStep(board,movetime= movetime,stockfish = stockfish)$bestmove
    print(move)
    board$move(move)
    board$ascii()
}


subprocess::process_kill(stockfish)



# 6 minute game



library(subprocess)
library(rchess)
library(dplyr)
library(magick)
library(ggplot2)
library(tools)
library(tictoc)
devtools::load_all()

stockfish = system2('which','stockfish',stdout = TRUE)
stockfish = 'C:/Users/Ogan/Desktop/stockfish-9-win/Windows/stockfish_9_x64.exe'
stockfish = subprocess::spawn_process(stockfish)

# we create an rchess board to play our game with
board = Chess$new()
p = ggchessboard(board$fen())

btime = 360000
wtime = 360000

# we create an rchess board to play our game with
board = Chess$new()
p = ggchessboard(board$fen())
dir.create('chessImgFast',showWarnings = FALSE)

ggsave(paste0('chessImgFast/',length(board$history()),'.png'),p,width = 7,height = 7)

while(board$game_over() == FALSE){
    turn = board$turn()
    # if(turn =='w'){
    #     movetime = 3000 # movetime controls how much time does the AI have to think
    # } else{
    #     movetime = 1000 # here black AI is dumber than white AI
    # }
    
    tic()
    out = stockStep(board,btime= btime,wtime=wtime,stockfish = stockfish)
    move = out$bestmove
    # move = stockStep(board,movetime = 5000,stockfish = stockfish)$bestmove
    elapsed = toc()
    elapsed = (elapsed$toc- elapsed$tic)*1000
    if(turn =='w'){
        wtime = wtime-elapsed # movetime controls how much time does the AI have to think
    } else{
        btime = btime-elapsed # here black AI is dumber than white AI
    }
    print(wtime)
    print(btime)
    print(out$score)
    board$move(move)
    p = ggchessboard(board$fen())
    ggsave(paste0('chessImgFast/',length(board$history()),'.png'),width = 7,height = 7)
}



subprocess::process_kill(stockfish)

imgs = list.files('chessImg/',full.names = TRUE)
imgs = imgs[order(imgs %>% basename %>% file_path_sans_ext() %>% as.integer())]

animation = imgs %>% lapply(image_read) %>% do.call(c,.) %>% image_animate(fps =1)
image_write(animation,'game.gif')


# game analysis
pgn <- system.file("extdata/pgn/kasparov_vs_topalov.pgn", package = "rchess")
pgn <- readLines(pgn, warn = FALSE)


pgn = readLines('carlsen_caruana_2018.pgn')
pgn = readLines('nakamura_kramnik_2012.pgn')

pgn <- paste(pgn, collapse = "\n")

evaluations = gameAnalysis(pgn,movetime = 500,stockfish = stockfish)
scores = evaluations$score
scores[evaluations$scoreType=='mate'] = (evaluations$score %>% max)+1


chsspgn <- Chess$new()
chsspgn$load_pgn(pgn)
moves = chsspgn$history(verbose= TRUE)
moves$promotion[is.na(moves$promotion)]=''
stockmoves = paste0(moves$from,moves$to,moves$promotion)
