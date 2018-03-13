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