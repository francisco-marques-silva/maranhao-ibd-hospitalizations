# ==============================================================================
# 004_distribuicao_geografica.R
#
# Objetivo : Análise da distribuição geográfica das internações por DII:
#            - Ranking dos municípios do MA por número de internações
#            - Mapa coroplético com malha IBGE via geobr
#            - Internações por macroregião de saúde
#
# Entrada  : data/processed/dii_limpo.rds
# Saída    : data/processed/resultados_geografico.rds
#            data/processed/mapa_sf.rds
#
# Projeto  : Internações hospitalares por DII no Maranhão (2015-2025)
# Data     : Fevereiro de 2026
# ==============================================================================

if (!exists("CID_CROHN")) source("R/000_setup.R")

dii <- readRDS("data/processed/dii_limpo.rds")

# ---------------------------------------------------------------------------- #
#  1. Contagem de internações por município de residência                       #
# ---------------------------------------------------------------------------- #

intern_munic <- dii |>
    filter(!is.na(cod_munic_res)) |>
    count(cod_munic_res, diagnostico, name = "internacoes") |>
    pivot_wider(names_from = diagnostico, values_from = internacoes, values_fill = 0) |>
    mutate(total = rowSums(across(where(is.numeric)))) |>
    arrange(desc(total))

# Versão longa (para gráficos e mapas)
intern_munic_long <- dii |>
    count(cod_munic_res, name = "total") |>
    arrange(desc(total))

message("Top 10 municipios por internacoes (DII total):")
print(head(as.data.frame(intern_munic_long), 10))

# ---------------------------------------------------------------------------- #
#  2. Baixar malha geográfica do Maranhão via geobr (IBGE 2020)                #
# ---------------------------------------------------------------------------- #

message("\nBaixando malha de municipios do Maranhao (geobr)...")

munic_sf <- tryCatch(
    geobr::read_municipality(code_muni = CODIGO_IBGE_MA, year = 2020, showProgress = FALSE),
    error = function(e) {
        warning("Nao foi possivel baixar a malha: ", e$message)
        NULL
    }
)

# ---------------------------------------------------------------------------- #
#  3. Unir dados de internações com malha geoespacial                           #
# ---------------------------------------------------------------------------- #

if (!is.null(munic_sf)) {
    message("Malha obtida: ", nrow(munic_sf), " municipios.")

    # O geobr usa 7 dígitos; o SIH usa 6. Truncar os 6 primeiros para o join.
    munic_sf <- munic_sf |>
        mutate(cod_munic_res = str_sub(as.character(code_muni), 1, 6))

    mapa_sf <- munic_sf |>
        left_join(intern_munic_long, by = "cod_munic_res") |>
        mutate(
            total = replace_na(total, 0),
            faixa_intern = cut(total,
                breaks = c(-1, 0, 5, 15, 30, 60, Inf),
                labels = c("0", "1-5", "6-15", "16-30", "31-60", "60+")
            )
        )

    saveRDS(mapa_sf, "data/processed/mapa_sf.rds")
    message("Mapa salvo: data/processed/mapa_sf.rds")
} else {
    mapa_sf <- NULL
    message("Mapa nao gerado — malha indisponivel.")
}

# ---------------------------------------------------------------------------- #
#  4. Salvar resultados geográficos                                             #
# ---------------------------------------------------------------------------- #

resultados_geo <- list(
    intern_munic      = intern_munic,
    intern_munic_long = intern_munic_long,
    mapa_sf           = mapa_sf
)

saveRDS(resultados_geo, "data/processed/resultados_geografico.rds")
message("\nSalvo: data/processed/resultados_geografico.rds")
