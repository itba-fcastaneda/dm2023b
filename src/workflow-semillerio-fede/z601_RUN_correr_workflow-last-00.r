# Corrida general del workflow

options(error = function() {
  traceback(20)
  options(error = NULL)
  stop("exiting after script error")
})


# corrida de cada paso del workflow

# primeros pasos, relativamente rapidos
source("~/dm2023b/src/workflow-semillerio-fede/z611_CA_reparar_dataset-last-00.r")
source("~/dm2023b/src/workflow-semillerio-fede/z621_DR_corregir_drifting-last-00.r")
source("~/dm2023b/src/workflow-semillerio-fede/z631_FE_historia-last-00.r")
source("~/dm2023b/src/workflow-semillerio-fede/z641_TS_training_strategy-last-00.r")

# ultimos pasos, muy lentos
source("~/dm2023b/src/workflow-semillerio-fede/z651_HT_lightgbm-last-00.r")
source("~/dm2023b/src/workflow-semillerio-fede/z661_ZZ_final-last-00.r")
source("~/dm2023b/src/workflow-semillerio-fede/z796_HB_semillerios_hibridacion-last-00.r")

