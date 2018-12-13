#' @export
animateGame = function(board, filename = NULL, width = 4.5,height = 4.5, fps = 1,...){
    temp = tempfile()
    dir.create(temp)
    
    newBoard = rchess::Chess$new()
    p = ggchessboard2(newBoard$fen(),...)
    ggplot2::ggsave(plot = p,filename = glue::glue('{temp}/{length(newBoard$history())}.png'),width = width, height = height)
    for (x in board$history()){
        newBoard$move(x)
        p = ggchessboard2(newBoard$fen(),...)
        ggplot2::ggsave(plot = p,filename = glue::glue('{temp}/{length(newBoard$history())}.png'),width = width, height = height)
    }
    imgs = list.files(temp,full.names = TRUE)
    imgs = imgs[order(imgs %>% basename %>% tools::file_path_sans_ext() %>% as.integer())]
    animation = imgs %>% lapply(magick::image_read) %>% do.call(c,.) %>% magick::image_animate(fps =fps)
    if(!is.null(filename)){
        magick::image_write(animation,filename)
    }
    invisible(animation)
}

ggchessboard2 = function(...){
    rchess::ggchessboard(...) +
        ggplot2::theme(panel.background = ggplot2::element_blank()) +
        ggplot2::xlab('') + ggplot2::ylab('') + ggplot2::scale_x_discrete(labels = letters[1:8])
}
