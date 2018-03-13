
stockfisher
-----------

### Use example

Using stockfisher to run a whole game between two AI opponents. Here, white AI is smarter than black AI.

``` r
library(subprocess)
library(rchess)
library(dplyr)
library(magick)
library(ggplot2)
library(tools)
devtools::load_all()

stockfish = system2('which','stockfish',stdout = TRUE)
stockfish = subprocess::spawn_process(stockfish)

dir.create('chessImg',showWarnings = FALSE)

# we create an rchess board to play our game with
board = Chess$new()
p = ggchessboard(board$fen())
ggsave(paste0('chessImg/',length(board$history()),'.png'),p)

while(board$game_over() == FALSE){
    turn = board$turn()
    if(turn =='w'){
        movetime = 3000 # movetime controls how much time does the AI have to think
    } else{
        movetime = 1000 # here black AI is dumber than white AI
    }
    move = stockStep(board,movetime= movetime,stockfish = stockfish)$bestmove
    board$move(move)
    p = ggchessboard(board$fen())
    ggsave(paste0('chessImg/',length(board$history()),'.png'))
}

subprocess::process_kill(stockfish)

imgs = list.files('chessImg/',full.names = TRUE)
imgs = imgs[order(imgs %>% basename %>% file_path_sans_ext() %>% as.integer())]

animation = imgs %>% lapply(image_read) %>% do.call(c,.) %>% image_animate(fps =1)
image_write(animation,'game.gif')
```

![](game.gif)
