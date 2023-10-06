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
require("Boruta")

# Parametros del script
PARAM <- list()
PARAM$experimento <- "FE6310-boruta-00"

PARAM$exp_input <- "DR6210"

PARAM$Boruta$enabled <- TRUE
PARAM$Boruta$semilla <- 800161


# varia de 0.0 a 2.0, si es 0.0 NO se activan
PARAM$CanaritosAsesinos$ratio <- 0.0
# desvios estandar de la media, para el cutoff
PARAM$CanaritosAsesinos$desvios <- 4.0
# cambiar por la propia semilla
PARAM$CanaritosAsesinos$semilla <- 800161

PARAM$home <- "~/buckets/b1/"
# FIN Parametros del script

OUTPUT <- list()

#------------------------------------------------------------------------------

options(error = function() {
  traceback(20)
  options(error = NULL)
  stop("exiting after script error")
})
#------------------------------------------------------------------------------

GrabarOutput <- function() {
  write_yaml(OUTPUT, file = "output.yml") # grabo OUTPUT
}
#------------------------------------------------------------------------------
# se calculan para los 6 meses previos el minimo, maximo y
#  tendencia calculada con cuadrados minimos
# la formula de calculo de la tendencia puede verse en
#  https://stats.libretexts.org/Bookshelves/Introductory_Statistics/Book%3A_Introductory_Statistics_(Shafer_and_Zhang)/10%3A_Correlation_and_Regression/10.04%3A_The_Least_Squares_Regression_Line
# para la maxíma velocidad esta funcion esta escrita en lenguaje C,
# y no en la porqueria de R o Python


#------------------------------------------------------------------------------
VPOS_CORTE <- c()

fganancia_lgbm_meseta <- function(probs, datos) {
  vlabels <- get_field(datos, "label")
  vpesos <- get_field(datos, "weight")

  tbl <- as.data.table(list(
    "prob" = probs,
    "gan" = ifelse(vlabels == 1 & vpesos > 1, 117000, -3000)
  ))

  setorder(tbl, -prob)
  tbl[, posicion := .I]
  tbl[, gan_acum := cumsum(gan)]
  setorder(tbl, -gan_acum) # voy por la meseta

  gan <- mean(tbl[1:500, gan_acum]) # meseta de tamaño 500

  pos_meseta <- tbl[1:500, median(posicion)]
  VPOS_CORTE <<- c(VPOS_CORTE, pos_meseta)

  return(list(
    "name" = "ganancia",
    "value" = gan,
    "higher_better" = TRUE
  ))
}
#------------------------------------------------------------------------------
# Elimina del dataset las variables que estan por debajo
#  de la capa geologica de canaritos
# se llama varias veces, luego de agregar muchas variables nuevas,
#  para ir reduciendo la cantidad de variables
# y así hacer lugar a nuevas variables importantes

GVEZ <- 1

BorutaReduction <- function(
  boruta_semilla = 800161) {
  gc()
  dataset[, clase01 := ifelse(clase_ternaria == "CONTINUA", 0, 1)]

  set.seed(boruta_semilla, kind = "L'Ecuyer-CMRG")

  campos_buenos <- setdiff(
    colnames(dataset),
    c("clase_ternaria", "foto_mes")
  )

  set.seed(boruta_semilla, kind = "L'Ecuyer-CMRG")
  azar <- runif(nrow(dataset))

#  dataset[, entrenamiento :=
#            foto_mes >= 202101 & foto_mes <= 202103 & (clase01 == 1 | azar < 0.10)]
  dataset[, entrenamiento :=
    foto_mes >= 202101 & foto_mes <= 202103 ]

  dtrain <- lgb.Dataset(
    data = data.matrix(dataset[entrenamiento == TRUE, campos_buenos, with = FALSE]),
    label = dataset[entrenamiento == TRUE, clase01],
    weight = dataset[
      entrenamiento == TRUE,
      ifelse(clase_ternaria == "BAJA+2", 1.0000001, 1.0)
    ],
    free_raw_data = FALSE
  )

  dvalid <- lgb.Dataset(
    data = data.matrix(dataset[foto_mes == 202105, campos_buenos, with = FALSE]),
    label = dataset[foto_mes == 202105, clase01],
    weight = dataset[
      foto_mes == 202105,
      ifelse(clase_ternaria == "BAJA+2", 1.0000001, 1.0)
    ],
    free_raw_data = FALSE
  )

  boruta.train <- Boruta(
    clase01~. ,
    data = dataset[entrenamiento == TRUE, campos_buenos, with = FALSE],

  )

  # param <- list(
  #   objective = "binary",
  #   metric = "custom",
  #   first_metric_only = TRUE,
  #   boost_from_average = TRUE,
  #   feature_pre_filter = FALSE,
  #   verbosity = -100,
  #   seed = canaritos_semilla,
  #   max_depth = -1, # -1 significa no limitar,  por ahora lo dejo fijo
  #   min_gain_to_split = 0.0, # por ahora, lo dejo fijo
  #   lambda_l1 = 0.0, # por ahora, lo dejo fijo
  #   lambda_l2 = 0.0, # por ahora, lo dejo fijo
  #   max_bin = 31, # por ahora, lo dejo fijo
  #   num_iterations = 9999, # un numero grande, lo limita early_stopping_rounds
  #   force_row_wise = TRUE, # para que los alumnos no se atemoricen con  warning
  #   learning_rate = 0.065,
  #   feature_fraction = 1.0, # lo seteo en 1
  #   min_data_in_leaf = 260,
  #   num_leaves = 60,
  #   early_stopping_rounds = 200,
  #   num_threads = 1
  # )
  
  # set.seed(canaritos_semilla, kind = "L'Ecuyer-CMRG")
  # modelo <- lgb.train(
  #   data = dtrain,
  #   valids = list(valid = dvalid),
  #   eval = fganancia_lgbm_meseta,
  #   param = param,
  #   verbose = -100
  # )

  # tb_importancia <- lgb.importance(model = modelo)
  # tb_importancia[, pos := .I]

  # fwrite(tb_importancia,
  #   file = paste0("impo_", GVEZ, ".txt"),
  #   sep = "\t"
  # )

  # GVEZ <<- GVEZ + 1

  # umbral <- tb_importancia[
  #   Feature %like% "canarito",
  #   median(pos) + canaritos_desvios * sd(pos)
  # ] # Atencion corto en la mediana mas desvios!!

  # col_utiles <- tb_importancia[
  #   pos < umbral & !(Feature %like% "canarito"),
  #   Feature
  # ]

  # col_utiles <- unique(c(
  #   col_utiles,
  #   c("numero_de_cliente", "foto_mes", "clase_ternaria", "mes")
  # ))

  # col_inutiles <- setdiff(colnames(dataset), col_utiles)

  # dataset[, (col_inutiles) := NULL]
}
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Aqui empieza el programa
OUTPUT$PARAM <- PARAM
OUTPUT$time$start <- format(Sys.time(), "%Y%m%d %H%M%S")

setwd(PARAM$home)

# cargo el dataset donde voy a entrenar
# esta en la carpeta del exp_input y siempre se llama  dataset.csv.gz
# dataset_input <- paste0("./exp/", PARAM$exp_input, "/dataset.csv.gz")
dataset_input <- paste0("./datasets/dataset_pequeno.csv")

dataset <- fread(dataset_input)

colnames(dataset)[which(!(sapply(dataset, typeof) %in% c("integer", "double")))]


# creo la carpeta donde va el experimento
dir.create(paste0("./exp/", PARAM$experimento, "/"), showWarnings = FALSE)
# Establezco el Working Directory DEL EXPERIMENTO
setwd(paste0("./exp/", PARAM$experimento, "/"))

GrabarOutput()
write_yaml(PARAM, file = "parametros.yml") # escribo parametros utilizados



# ordeno el dataset por <numero_de_cliente, foto_mes> para poder hacer lags
#  es MUY  importante esta linea
setorder(dataset, numero_de_cliente, foto_mes)






#------------------------------------------------------------------------------
# Agrego variables a partir de las hojas de un Random Forest


#--------------------------------------------------------------------------
# Elimino las variables que no son tan importantes en el dataset
# with great power comes grest responsability



if (PARAM$Boruta$enabled){
  OUTPUT$Boruta$ncol_antes <- ncol(dataset)
  BorutaReduction(
    boruta_semilla = PARAM$Boruta$semilla
  )
  OUTPUT$Boruta$ncol_despues <- ncol(dataset)
  GrabarOutput()
}

#------------------------------------------------------------------------------
# grabo el dataset
fwrite(dataset,
  "dataset.csv.gz",
  logical01 = TRUE,
  sep = ","
)

#------------------------------------------------------------------------------

# guardo los campos que tiene el dataset
tb_campos <- as.data.table(list(
  "pos" = 1:ncol(dataset),
  "campo" = names(sapply(dataset, class)),
  "tipo" = sapply(dataset, class),
  "nulos" = sapply(dataset, function(x) {
    sum(is.na(x))
  }),
  "ceros" = sapply(dataset, function(x) {
    sum(x == 0, na.rm = TRUE)
  })
))

fwrite(tb_campos,
  file = "dataset.campos.txt",
  sep = "\t"
)

#------------------------------------------------------------------------------
OUTPUT$dataset$ncol <- ncol(dataset)
OUTPUT$dataset$nrow <- nrow(dataset)

OUTPUT$time$end <- format(Sys.time(), "%Y%m%d %H%M%S")
GrabarOutput()

# dejo la marca final
cat(format(Sys.time(), "%Y%m%d %H%M%S"), "\n",
  file = "zRend.txt",
  append = TRUE
)
