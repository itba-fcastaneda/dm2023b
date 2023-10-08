
require("data.table")
require("yaml")
require("Rcpp")

require("randomForest") # solo se usa para imputar nulos

require("Boruta")

# limpio la memoria
rm(list = ls(all.names = TRUE)) # remove all objects
gc(full = TRUE) # garbage collection

#############################################################
# PARAMETROS

PARAM <- list()
PARAM$seed <- 800161

PARAM$experimento <- "local-Boruta-small-10"

#PARAM$exp_input <- "exp/DR6210"
#PARAM$dataset_file <- "/dataset.csv.gz"
PARAM$exp_input <- "datasets"
PARAM$dataset_file <- "/dataset_pequeno.csv"

PARAM$home <- "~/buckets/b1/"
PARAM$output_file <- "output.yml"

PARAM$train_month <- 202107

# PARAMETROS
#############################################################
# FUNCIONES

GrabarOutput <- function( output_file ) {
  write_yaml(OUTPUT, file = output_file ) # grabo OUTPUT
}

#############################################################
#############################################################



# Preparo el archivos de salida
OUTPUT <- list()
OUTPUT$PARAM <- PARAM

setwd(PARAM$home)
output_folder <- paste0("./exp/", PARAM$experimento, "/") 
dir.create(output_folder, showWarnings = FALSE)


dataset_input <- paste0( PARAM$home, PARAM$exp_input, PARAM$dataset_file)
output_file <- paste0( output_folder, PARAM$output_file )

OUTPUT$time$start <- format(Sys.time(), "%Y%m%d %H%M%S")
GrabarOutput( output_file )

#############################################################
## CARGO DATASET
dataset <- fread(dataset_input)


OUTPUT$cols_init <- ncol(dataset)

## PREPARACION DATASET

# Armo un feature de clasificación
dataset[, clase01 := ifelse(clase_ternaria == "CONTINUA", 0, 1)]
# campos sobre los que vamos a hacer en entrenamiento
campos_buenos <- setdiff(
  colnames(dataset),
  c("clase_ternaria", "foto_mes", "numero_de_cliente" )
)

# Armo una lista auxiliar para el under sampling clase00
set.seed(PARAM$seed, kind = "L'Ecuyer-CMRG")
azar <- runif(nrow(dataset))

# Agrego una columna para indicar cuales quiero usar del dataset
dataset[, entrenamiento :=
          as.integer(foto_mes == PARAM$train_month & (clase01 == 1 | azar < 0.10))]

# Imputo los nulos
dtrain = na.roughfix(dataset[entrenamiento==TRUE, ..campos_buenos])

for(i in seq(55,100,5)) {
  boruta_out <- Boruta(clase01~.,data=dtrain, doTrace=2, maxRuns=i)
  
  fwrite(
    as.list(getSelectedAttributes(boruta_out)),
    file = paste0( output_folder , "attributes_", i ,".txt" ),
    sep = "\n"
  )
  
  jpeg( paste0( output_folder , "plot_", i ,".jpeg" ) , width = 1024, height = 800 )
  plot( boruta_out , )
  dev.off()
}

#OUTPUT$boruta_print <- as.character(Boruta.srx)

OUTPUT$time$stop <- format(Sys.time(), "%Y%m%d %H%M%S")
GrabarOutput(output_file)
