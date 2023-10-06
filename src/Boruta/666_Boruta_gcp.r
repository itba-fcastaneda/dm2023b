library(Boruta)
require("data.table")
require("randomForest")
require("yaml")

PARAM <- list()
PARAM$experimento <- "FE6310-boruta-02"

PARAM$exp_input <- "DR6210"

OUTPUT <- list()

setwd( "~/buckets/b1/")
boruta_semilla = 800161

dataset_input <- paste0("./exp/", PARAM$exp_input, "/dataset.csv.gz")
#dataset_input <- paste0("./datasets/dataset_pequeno.csv")

############################################################
GrabarOutput <- function() {
  write_yaml(OUTPUT, file = "output.yml") # grabo OUTPUT
}

# creo la carpeta donde va el experimento
dir.create(paste0("./exp/", PARAM$experimento, "/"), showWarnings = FALSE)
# Establezco el Working Directory DEL EXPERIMENTO
setwd(paste0("./exp/", PARAM$experimento, "/"))

############################################################

dataset <- fread(dataset_input)
colnames(dataset)[which(!(sapply(dataset, typeof) %in% c("integer", "double")))]



#setorder(dataset, numero_de_cliente, foto_mes)

dataset[, clase01 := ifelse(clase_ternaria == "CONTINUA", 0, 1)]

set.seed(boruta_semilla, kind = "L'Ecuyer-CMRG")
azar <- runif(nrow(dataset))

dataset[, entrenamiento :=
             as.integer(foto_mes >= 202101 & foto_mes <= 202103 &
                          (clase01 == 1 | azar < 0.10))]

campos_buenos <- setdiff(
  colnames(dataset),
  c("clase_ternaria", "foto_mes")
)

dataset_rf <- copy(dataset[entrenamiento == TRUE, campos_buenos, with = FALSE])

set.seed(boruta_semilla, kind = "L'Ecuyer-CMRG")
azar <- runif(nrow(dataset_rf))

set.seed(boruta_semilla, kind = "L'Ecuyer-CMRG")
dtrain <- na.roughfix(dataset_rf)

ncol_antes <- ncol(dataset)

boruta_train <- Boruta(
  clase01~. ,
  data = dtrain,
)

boruta_attrs <- getSelectedAttributes(boruta_train, withTentative = FALSE)

boruta_fixed <- TentativeRoughFix(boruta.bank_train)

OUTPUT$boruta_attrs <- boruta_attrs
OUTPUT$boruta_fixed <- boruta_fixed
GrabarOutput()
