# ==============================================================================
# 007_main.R
#
# Objetivo : Script orquestrador — executa toda a análise em sequência.
#            Para reproduzir o estudo completo, basta rodar:
#
#                source("R/007_main.R")
#
# Pré-requisito: arquivo 'data/raw/dii.rds' deve existir.
#
# Projeto  : Internações hospitalares por DII no Maranhão (2015-2025)
# Data     : Fevereiro de 2026
# Fonte    : SIH/SUS via microdatasus | IBGE/SIDRA
# ==============================================================================

inicio <- Sys.time()

cat("\n")
cat("================================================================\n")
cat("  Internações por DII no Maranhão — Análise 2015-2025\n")
cat("  Início:", format(inicio, "%d/%m/%Y %H:%M:%S"), "\n")
cat("================================================================\n\n")

# Verificar pré-requisito
if (!file.exists("data/raw/dii.rds")) {
    stop(
        "ERRO: arquivo 'data/raw/dii.rds' nao encontrado.\n",
        "Por favor, coloque o arquivo de dados filtrado na pasta data/raw/ e tente novamente."
    )
}

# ---------------------------------------------------------------------------- #
#  PASSO 0 — Setup (pacotes, constantes, diretórios)                           #
# ---------------------------------------------------------------------------- #
cat("[ 0/7 ] Setup e configuracao...\n")
source("R/000_setup.R")

# ---------------------------------------------------------------------------- #
#  PASSO 1 — Limpeza e criação de variáveis                                    #
# ---------------------------------------------------------------------------- #
cat("[ 1/7 ] Limpeza e preparacao dos dados...\n")
source("R/001_limpeza.R")

# ---------------------------------------------------------------------------- #
#  PASSO 2 — Análise descritiva                                                 #
# ---------------------------------------------------------------------------- #
cat("[ 2/7 ] Análise descritiva...\n")
source("R/002_analise_descritiva.R")

# ---------------------------------------------------------------------------- #
#  PASSO 3 — Tendência temporal e taxas IBGE                                    #
# ---------------------------------------------------------------------------- #
cat("[ 3/7 ] Tendência temporal e taxas por 100.000 hab. (IBGE)...\n")
source("R/003_tendencia_temporal.R")

# ---------------------------------------------------------------------------- #
#  PASSO 4 — Distribuição geográfica e mapa                                     #
# ---------------------------------------------------------------------------- #
cat("[ 4/7 ] Distribuição geográfica (geobr/IBGE)...\n")
source("R/004_distribuicao_geografica.R")

# ---------------------------------------------------------------------------- #
#  PASSO 5 — Figuras principais (PNG 300 dpi)                                   #
# ---------------------------------------------------------------------------- #
cat("[ 5/7 ] Gerando figuras principais (fig01-fig12)...\n")
source("R/005_graficos.R")

# ---------------------------------------------------------------------------- #
#  PASSO 6 — Tabelas para publicação (.docx)                                    #
# ---------------------------------------------------------------------------- #
cat("[ 6/7 ] Exportando tabelas principais (tabela1-tabela5)...\n")
source("R/006_tabelas.R")

# ---------------------------------------------------------------------------- #
#  PASSO 7 — Análises adicionais (Poisson, heatmap, sazonalidade, etc.)         #
# ---------------------------------------------------------------------------- #
cat("[ 7/7 ] Análises adicionais (fig13-fig19 + tabela6-tabela8)...\n")
source("R/008_analises_adicionais.R")

# ---------------------------------------------------------------------------- #
#  Finalização                                                                  #
# ---------------------------------------------------------------------------- #
fim <- Sys.time()
elapsed <- round(difftime(fim, inicio, units = "mins"), 1)

figs_n <- length(list.files("output/figuras", pattern = "\\.png$"))
tabs_n <- length(list.files("output/tabelas", pattern = "\\.docx$"))

cat("\n")
cat("================================================================\n")
cat("  ANÁLISE CONCLUÍDA COM SUCESSO!\n")
cat("  Fim    :", format(fim, "%d/%m/%Y %H:%M:%S"), "\n")
cat("  Tempo  :", as.numeric(elapsed), "minutos\n")
cat("----------------------------------------------------------------\n")
cat("  Outputs gerados:\n")
cat("    output/figuras/ ->", figs_n, "figuras (.png)\n")
cat("    output/tabelas/ ->", tabs_n, "tabelas (.docx)\n")
cat("    data/processed/ ->", length(list.files("data/processed")), "arquivos .rds\n")
cat("================================================================\n\n")
