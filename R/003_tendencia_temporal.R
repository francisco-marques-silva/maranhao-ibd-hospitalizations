# ==============================================================================
# 003_tendencia_temporal.R
#
# Objetivo : Análise da tendência temporal das internações por DII:
#            - Série anual de internações por diagnóstico
#            - Taxa de internação por 100.000 hab. (popul. IBGE)
#            - Regressão linear para avaliar tendência
#            - Variação percentual acumulada no período
#
# Entrada  : data/processed/dii_limpo.rds
# Saída    : data/processed/resultados_temporal.rds
#
# Projeto  : Internações hospitalares por DII no Maranhão (2015-2025)
# Data     : Fevereiro de 2026
# ==============================================================================

if (!exists("CID_CROHN")) source("R/000_setup.R")

dii <- readRDS("data/processed/dii_limpo.rds")

# ---------------------------------------------------------------------------- #
#  1. Série anual de internações por diagnóstico e total                        #
# ---------------------------------------------------------------------------- #

serie_diag <- dii |>
    count(ano, diagnostico, name = "internacoes")

serie_total <- dii |>
    count(ano, name = "internacoes") |>
    mutate(diagnostico = "Total DII")

serie_anual <- bind_rows(serie_diag, serie_total) |>
    arrange(ano, diagnostico)

message("Serie anual de internacoes:")
print(pivot_wider(serie_anual, names_from = diagnostico, values_from = internacoes))

# ---------------------------------------------------------------------------- #
#  2. Taxa de internação por 100.000 habitantes (IBGE)                          #
# ---------------------------------------------------------------------------- #

serie_taxa <- serie_anual |>
    left_join(POP_MA, by = "ano") |>
    mutate(
        taxa_100k = round((internacoes / populacao) * 100000, 3)
    )

message("\nTaxa por 100.000 hab. (Total DII):")
print(as.data.frame(serie_taxa |> filter(diagnostico == "Total DII")))

# ---------------------------------------------------------------------------- #
#  3. Modelo de regressão linear — tendência global                             #
# ---------------------------------------------------------------------------- #

# Modelo para o total DII
dados_lm_total <- serie_taxa |>
    filter(diagnostico == "Total DII")

modelo_total <- lm(taxa_100k ~ ano, data = dados_lm_total)
resumo_total <- tidy(modelo_total, conf.int = TRUE)

message("\nCoeficientes da regressão linear (Total DII ~ ano):")
print(as.data.frame(resumo_total))

# R² do modelo
r2_total <- round(summary(modelo_total)$r.squared, 4)
p_tendencia <- resumo_total |>
    filter(term == "ano") |>
    pull(p.value)
direcao <- if_else(coef(modelo_total)["ano"] > 0, "crescente", "decrescente")

message(glue("\nR² = {r2_total} | p-valor (tendência) = {round(p_tendencia, 4)} | Tendência: {direcao}"))

# Modelo por diagnóstico separado
modelos_diag <- serie_taxa |>
    filter(diagnostico != "Total DII") |>
    group_by(diagnostico) |>
    group_modify(~ tidy(lm(taxa_100k ~ ano, data = .x), conf.int = TRUE)) |>
    ungroup()

message("\nCoeficientes por diagnóstico:")
print(as.data.frame(modelos_diag |> filter(term == "ano")))

# ---------------------------------------------------------------------------- #
#  4. Variação percentual acumulada                                             #
# ---------------------------------------------------------------------------- #

# Variação de internações brutas
variacao_internacoes <- serie_anual |>
    filter(diagnostico == "Total DII") |>
    summarise(
        ano_inicio         = first(ano),
        ano_fim            = last(ano),
        intern_inicio      = first(internacoes),
        intern_fim         = last(internacoes),
        variacao_abs       = last(internacoes) - first(internacoes),
        variacao_pct       = round((last(internacoes) / first(internacoes) - 1) * 100, 1)
    )

message("\nVariação acumulada de internações:")
print(as.data.frame(variacao_internacoes))

# Variação por período COVID
var_periodo <- dii |>
    count(periodo, diagnostico, name = "internacoes") |>
    left_join(
        tibble(periodo = PERIODOS_COVID, n_anos = c(5, 2, 4)),
        by = "periodo"
    ) |>
    mutate(media_anual = round(internacoes / n_anos, 1))

message("\nInternações por período COVID:")
print(as.data.frame(var_periodo))

# ---------------------------------------------------------------------------- #
#  5. Série mensal (para análise do impacto COVID)                              #
# ---------------------------------------------------------------------------- #

serie_mensal <- dii |>
    mutate(ano_mes = make_date(ano, mes, 1)) |>
    count(ano_mes, diagnostico, name = "internacoes") |>
    arrange(ano_mes)

# ---------------------------------------------------------------------------- #
#  6. Salvar resultados                                                         #
# ---------------------------------------------------------------------------- #

resultados_temporal <- list(
    serie_anual          = serie_anual,
    serie_taxa           = serie_taxa,
    modelo_total         = modelo_total,
    resumo_total         = resumo_total,
    r2_total             = r2_total,
    p_tendencia          = p_tendencia,
    modelos_diag         = modelos_diag,
    variacao_internacoes = variacao_internacoes,
    var_periodo          = var_periodo,
    serie_mensal         = serie_mensal
)

saveRDS(resultados_temporal, "data/processed/resultados_temporal.rds")
message("\nSalvo: data/processed/resultados_temporal.rds")
