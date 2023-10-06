# Experimentos Colaborativos Default
# Workflow  Feature Engineering historico

# limpio la memoria
rm(list = ls(all.names = TRUE)) # remove all objects
gc(full = TRUE) # garbage collection

require("data.table")
require("yaml")
require("Rcpp")

require("ranger")
require("randomForest") # solo se usa para imputar nulos

require("lightgbm")


# Parametros del script
PARAM <- list()
PARAM$experimento <- "FE6660-boruta-00"

PARAM$exp_input <- "DR6210"

PARAM$home <- "~/buckets/b1/"
# FIN Parametros del script

OUTPUT <- list()