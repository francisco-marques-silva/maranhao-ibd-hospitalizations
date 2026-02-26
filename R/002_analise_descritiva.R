# ==============================================================================
# 002_analise_descritiva.R
#
# Objetivo : Análise descritiva das internações por DII no Maranhão:
#            - Distribuição por sexo, faixa etária, raça/cor e diagnóstico
#            - Características clínicas: permanência, UTI, mortalidade
#            - Análise de custos das internações
#
# Entrada  : data/processed/dii_limpo.rds
# Saída    : data/processed/resultados_descritivos.rds
#
# Projeto  : Internações hospitalares por DII no Maranhão (2015-2025)
# Data     : Fevereiro de 2026
# ==============================================================================

if (!exists("CID_CROHN")) source("R/000_setup.R")

dii <- readRDS("data/processed/dii_limpo.rds")

# Função auxiliar: calcula n e % com formatação limpa
freq_rel <- function(df, ...) {
    df |>
        count(...) |>
        mutate(pct = round(n / sum(n) * 100, 1))
}

# ---------------------------------------------------------------------------- #
#  1. Características sociodemográficas                                         #
# ---------------------------------------------------------------------------- #

## 1.1  Por sexo e diagnóstico
tab_sexo <- dii |>
    filter(!is.na(sexo)) |>
    group_by(diagnostico) |>
    freq_rel(sexo)

## 1.2  Por faixa etária e diagnóstico
tab_faixa <- dii |>
    filter(!is.na(faixa_etaria)) |>
    group_by(diagnostico) |>
    freq_rel(faixa_etaria)

## 1.3  Por raça/cor e diagnóstico
tab_raca <- dii |>
    group_by(diagnostico) |>
    freq_rel(raca_cor)

## 1.4  Por período (pré/durante/pós-COVID) e diagnóstico
tab_periodo <- dii |>
    group_by(diagnostico) |>
    freq_rel(periodo)

# ---------------------------------------------------------------------------- #
#  2. Características clínicas                                                   #
# ---------------------------------------------------------------------------- #

## 2.1  Tempo de permanência hospitalar
tab_permanencia <- dii |>
    filter(!is.na(dias_perm)) |>
    group_by(diagnostico) |>
    summarise(
        n = n(),
        media = round(mean(dias_perm), 1),
        dp = round(sd(dias_perm), 1),
        mediana = round(median(dias_perm), 1),
        q1 = round(quantile(dias_perm, 0.25), 1),
        q3 = round(quantile(dias_perm, 0.75), 1),
        minimo = min(dias_perm),
        maximo = max(dias_perm),
        .groups = "drop"
    )

## 2.2  Mortalidade hospitalar
tab_mortalidade <- dii |>
    group_by(diagnostico) |>
    summarise(
        internacoes = n(),
        obitos = sum(obito, na.rm = TRUE),
        taxa_mort = round(mean(obito, na.rm = TRUE) * 100, 2),
        .groups = "drop"
    )

tab_mort_sexo <- dii |>
    filter(!is.na(sexo)) |>
    group_by(diagnostico, sexo) |>
    summarise(
        internacoes = n(),
        obitos = sum(obito, na.rm = TRUE),
        taxa_mort = round(mean(obito, na.rm = TRUE) * 100, 2),
        .groups = "drop"
    )

tab_mort_faixa <- dii |>
    filter(!is.na(faixa_etaria)) |>
    group_by(diagnostico, faixa_etaria) |>
    summarise(
        internacoes = n(),
        obitos = sum(obito, na.rm = TRUE),
        taxa_mort = round(mean(obito, na.rm = TRUE) * 100, 2),
        .groups = "drop"
    )

## 2.3  Uso de UTI
tab_uti <- dii |>
    group_by(diagnostico) |>
    summarise(
        internacoes = n(),
        com_uti = sum(usou_uti, na.rm = TRUE),
        pct_uti = round(mean(usou_uti, na.rm = TRUE) * 100, 1),
        .groups = "drop"
    )

# ---------------------------------------------------------------------------- #
#  3. Custos financeiros                                                         #
# ---------------------------------------------------------------------------- #

tab_custos <- dii |>
    group_by(diagnostico) |>
    summarise(
        internacoes = n(),
        custo_total = round(sum(val_total, na.rm = TRUE), 2),
        custo_medio = round(mean(val_total, na.rm = TRUE), 2),
        custo_dp = round(sd(val_total, na.rm = TRUE), 2),
        custo_mediana = round(median(val_total, na.rm = TRUE), 2),
        .groups = "drop"
    )

tab_custos_ano <- dii |>
    group_by(ano, diagnostico) |>
    summarise(
        internacoes = n(),
        custo_total = round(sum(val_total, na.rm = TRUE), 2),
        custo_medio = round(mean(val_total, na.rm = TRUE), 2),
        .groups = "drop"
    )

# ---------------------------------------------------------------------------- #
#  4. Exibir resultados no console                                              #
# ---------------------------------------------------------------------------- #

message("\n========  ANÁLISE DESCRITIVA  ========\n")
message("--- SEXO ---")
print(as.data.frame(tab_sexo))
message("\n--- FAIXA ETÁRIA ---")
print(as.data.frame(tab_faixa))
message("\n--- RAÇA/COR ---")
print(as.data.frame(tab_raca))
message("\n--- PERÍODO COVID ---")
print(as.data.frame(tab_periodo))
message("\n--- PERMANÊNCIA (dias) ---")
print(as.data.frame(tab_permanencia))
message("\n--- MORTALIDADE ---")
print(as.data.frame(tab_mortalidade))
message("\n--- UTI ---")
print(as.data.frame(tab_uti))
message("\n--- CUSTOS (R$) ---")
print(as.data.frame(tab_custos))

# ---------------------------------------------------------------------------- #
#  5. Salvar todos os resultados descritivos                                    #
# ---------------------------------------------------------------------------- #

resultados <- list(
    sexo          = tab_sexo,
    faixa_etaria  = tab_faixa,
    raca_cor      = tab_raca,
    periodo       = tab_periodo,
    permanencia   = tab_permanencia,
    mortalidade   = tab_mortalidade,
    mort_sexo     = tab_mort_sexo,
    mort_faixa    = tab_mort_faixa,
    uti           = tab_uti,
    custos        = tab_custos,
    custos_ano    = tab_custos_ano
)

saveRDS(resultados, "data/processed/resultados_descritivos.rds")
message("\nSalvo: data/processed/resultados_descritivos.rds")
