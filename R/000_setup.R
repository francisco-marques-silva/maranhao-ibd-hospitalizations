# ==============================================================================
# 000_setup.R
#
# Objetivo : Instalar e carregar pacotes; definir constantes e tema global.
#
# Projeto  : Internações hospitalares por DII no Maranhão (2015-2025)
# Data     : Fevereiro de 2026
# Fonte    : SIH/SUS via microdatasus | IBGE/SIDRA
# ==============================================================================

# ---------------------------------------------------------------------------- #
#  1. Instalar pacotes ausentes                                                 #
# ---------------------------------------------------------------------------- #

pkgs_cran <- c(
    "tidyverse", # manipulação e visualização de dados
    "lubridate", # manipulação de datas
    "janitor", # limpeza de nomes de variáveis
    "geobr", # malhas geográficas do Brasil (IBGE)
    "sf", # dados espaciais e mapas
    "patchwork", # composição de múltiplos gráficos
    "scales", # formatação de eixos e escalas
    "gt", # tabelas estáticas de alta qualidade
    "flextable", # tabelas compatíveis com Word/HTML
    "officer", # exportação para .docx
    "broom", # tidying de saídas de modelos
    "glue", # interpolação de strings
    "fs", # manipulação de sistema de arquivos
    "knitr" # knit helpers (kable)
)

inst_ausentes <- pkgs_cran[!pkgs_cran %in% rownames(installed.packages())]
if (length(inst_ausentes) > 0) {
    message("Instalando: ", paste(inst_ausentes, collapse = ", "))
    install.packages(inst_ausentes, repos = "https://cloud.r-project.org")
}

# ---------------------------------------------------------------------------- #
#  2. Carregar pacotes                                                          #
# ---------------------------------------------------------------------------- #

suppressPackageStartupMessages({
    library(tidyverse)
    library(lubridate)
    library(janitor)
    library(geobr)
    library(sf)
    library(patchwork)
    library(scales)
    library(gt)
    library(flextable)
    library(officer)
    library(broom)
    library(glue)
    library(fs)
})

message("Pacotes carregados com sucesso.")

# ---------------------------------------------------------------------------- #
#  3. Criar diretórios de output (caso não existam)                            #
# ---------------------------------------------------------------------------- #

dirs_necessarios <- c("output/figuras", "output/tabelas", "data/processed")
walk(dirs_necessarios, ~ dir_create(.x, recurse = TRUE))

# ---------------------------------------------------------------------------- #
#  4. Constantes globais do projeto                                             #
# ---------------------------------------------------------------------------- #

# Códigos CID-10 das doenças de interesse
CID_CROHN <- "K50" # Doença de Crohn
CID_COLITE <- "K51" # Colite Ulcerativa

# Período do estudo
ANO_INICIO <- 2015
ANO_FIM <- 2025

# Código IBGE do Maranhão (para geobr e SIDRA)
CODIGO_IBGE_MA <- 21

# Estimativas populacionais do Maranhão — IBGE (Projeções 2015–2025)
# Fonte: https://sidra.ibge.gov.br/tabela/6579
POP_MA <- tibble(
    ano = 2015:2025,
    populacao = c(
        6904241, # 2015
        6954036, # 2016
        7000229, # 2017
        7035055, # 2018
        7075181, # 2019
        7114598, # 2020 (Censo ajustado)
        6823056, # 2021 (Resultado Censo 2022 retroprojetado)
        6868059, # 2022
        7004554, # 2023
        7153262, # 2024
        7300000 # 2025 (estimativa)
    )
)

# Períodos de análise em relação à pandemia de COVID-19
PERIODOS_COVID <- c(
    "Pre-COVID (2015-2019)",
    "COVID (2020-2021)",
    "Pos-COVID (2022-2025)"
)

# ---------------------------------------------------------------------------- #
#  5. Paleta de cores acessível (Color-blind friendly — Okabe-Ito adaptado)    #
# ---------------------------------------------------------------------------- #

CORES <- c(
    "Doenca de Crohn"   = "#0072B2", # azul escuro
    "Colite Ulcerativa" = "#D55E00", # laranja escuro
    "Total DII"         = "#009E73", # verde
    "Masculino"         = "#56B4E9", # azul claro
    "Feminino"          = "#E69F00" # amarelo/dourado
)

CORES_PERIODO <- c(
    "Pre-COVID (2015-2019)" = "#2166AC",
    "COVID (2020-2021)"     = "#D6604D",
    "Pos-COVID (2022-2025)" = "#4DAC26"
)

# ---------------------------------------------------------------------------- #
#  6. Tema ggplot2 padrão do projeto                                            #
# ---------------------------------------------------------------------------- #

TEMA <- theme_minimal(base_size = 12, base_family = "sans") +
    theme(
        plot.title = element_text(face = "bold", size = 13, hjust = 0),
        plot.subtitle = element_text(colour = "grey40", size = 10, hjust = 0),
        plot.caption = element_text(colour = "grey55", size = 8, hjust = 1),
        legend.position = "bottom",
        legend.title = element_text(face = "bold", size = 9),
        panel.grid.minor = element_blank(),
        axis.title = element_text(size = 10),
        strip.text = element_text(face = "bold")
    )

message("Constantes e tema global definidos.")
