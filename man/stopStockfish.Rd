% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/startStockfish.R
\name{stopStockfish}
\alias{stopStockfish}
\title{Stop running stockfish process}
\usage{
stopStockfish(stockfish)
}
\arguments{
\item{stockfish}{A running stockfish (or technically any other process started by \code{subprocess::spawn_process}) process.}
}
\description{
Use for cleanup
}
\examples{
stockfish = startStockfish()
stockStep(posString = 'startpos',movetime = 1000,stockfish = stockfish)
stopStockfish()
}
