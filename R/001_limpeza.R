# ==============================================================================
# 001_limpeza.R
#
# Objetivo : Carregar dii.rds (dados brutos SIH/SUS filtrados para K50 e K51),
#            padronizar variáveis e criar derivadas para análise.
#
# Entrada  : data/raw/dii.rds
# Saída    : data/processed/dii_limpo.rds
#
# Projeto  : Internações hospitalares por DII no Maranhão (2015-2025)
# Data     : Fevereiro de 2026
# ==============================================================================

if (!exists("CID_CROHN")) source("R/000_setup.R")

# ---------------------------------------------------------------------------- #
#  1. Carregar dados brutos                                                     #
# ---------------------------------------------------------------------------- #

arquivo_entrada <- "data/raw/dii.rds"
if (!file_exists(arquivo_entrada)) {
    stop(
        "Arquivo nao encontrado: '", arquivo_entrada, "'.\n",
        "Certifique-se de que o arquivo dii.rds esta em data/raw/."
    )
}

dii_raw <- readRDS(arquivo_entrada)
message("Dados carregados: ", nrow(dii_raw), " registros | ", ncol(dii_raw), " colunas.")

# ---------------------------------------------------------------------------- #
#  2. Padronização básica de nomes e tipos                                      #
# ---------------------------------------------------------------------------- #

dii <- dii_raw |>
    # 2.1  Diagnóstico — classificar K50.x e K51.x
    mutate(
        diagnostico = case_when(
            str_starts(DIAG_PRINC, CID_CROHN) ~ "Doenca de Crohn",
            str_starts(DIAG_PRINC, CID_COLITE) ~ "Colite Ulcerativa",
            TRUE ~ "Outro"
        ),
        diagnostico = factor(diagnostico,
            levels = c("Doenca de Crohn", "Colite Ulcerativa")
        )
    ) |>
    # 2.2  Datas (formato AAAAMMDD → Date)
    mutate(
        dt_internacao = ymd(DT_INTER),
        dt_saida = ymd(DT_SAIDA),
        dt_nascimento = suppressWarnings(ymd(NASC)),
        ano = as.integer(ANO_CMPT),
        mes = as.integer(MES_CMPT)
    ) |>
    # 2.3  Período em relação à COVID-19
    mutate(
        periodo = case_when(
            ano %in% 2015:2019 ~ "Pre-COVID (2015-2019)",
            ano %in% 2020:2021 ~ "COVID (2020-2021)",
            ano %in% 2022:2025 ~ "Pos-COVID (2022-2025)"
        ),
        periodo = factor(periodo, levels = PERIODOS_COVID)
    ) |>
    # 2.4  Idade (calculada a partir da data de nascimento e internação)
    mutate(
        idade = suppressWarnings(
            as.integer(interval(dt_nascimento, dt_internacao) / years(1))
        ),
        # Fallback: campo IDADE do SIH quando COD_IDADE == 4 (anos)
        idade = if_else(
            is.na(idade) & COD_IDADE == "4",
            as.integer(IDADE),
            idade
        ),
        faixa_etaria = case_when(
            idade < 18 ~ "< 18 anos",
            idade >= 18 & idade < 30 ~ "18-29 anos",
            idade >= 30 & idade < 40 ~ "30-39 anos",
            idade >= 40 & idade < 50 ~ "40-49 anos",
            idade >= 50 & idade < 60 ~ "50-59 anos",
            idade >= 60 & idade < 70 ~ "60-69 anos",
            idade >= 70 ~ "70+ anos",
            TRUE ~ NA_character_
        ),
        faixa_etaria = factor(faixa_etaria,
            levels = c(
                "< 18 anos", "18-29 anos", "30-39 anos",
                "40-49 anos", "50-59 anos", "60-69 anos", "70+ anos"
            )
        )
    ) |>
    # 2.5  Sexo
    mutate(
        sexo = case_when(
            SEXO == "1" ~ "Masculino",
            SEXO == "3" ~ "Feminino",
            TRUE ~ NA_character_
        ),
        sexo = factor(sexo, levels = c("Masculino", "Feminino"))
    ) |>
    # 2.6  Raça/cor (categorias do SIH)
    mutate(
        raca_cor = case_when(
            RACA_COR == "01" ~ "Branca",
            RACA_COR == "02" ~ "Preta",
            RACA_COR == "03" ~ "Parda",
            RACA_COR == "04" ~ "Amarela",
            RACA_COR == "05" ~ "Indigena",
            RACA_COR == "99" ~ "Sem informacao",
            TRUE ~ "Sem informacao"
        ),
        raca_cor = factor(raca_cor,
            levels = c("Branca", "Preta", "Parda", "Amarela", "Indigena", "Sem informacao")
        )
    ) |>
    # 2.7  Óbito e dias de permanência
    mutate(
        obito      = as.integer(MORTE) == 1,
        dias_perm  = as.integer(DIAS_PERM),
        dias_perm  = if_else(dias_perm > 365, NA_integer_, dias_perm) # outliers
    ) |>
    # 2.8  Valores financeiros
    mutate(
        val_total = as.numeric(VAL_TOT)
    ) |>
    # 2.9  UTI
    mutate(
        usou_uti = UTI_MES_TO > 0
    ) |>
    # 2.10  Município de residência (6 dígitos)
    mutate(
        cod_munic_res = str_pad(as.character(MUNIC_RES), width = 6, side = "left", pad = "0")
    )

# ---------------------------------------------------------------------------- #
#  3. Validação dos dados limpos                                                #
# ---------------------------------------------------------------------------- #

message("\n--- Resumo dos dados limpos ---")
message("Total de internacoes : ", nrow(dii))
message("Doença de Crohn      : ", sum(dii$diagnostico == "Doenca de Crohn", na.rm = TRUE))
message("Colite Ulcerativa    : ", sum(dii$diagnostico == "Colite Ulcerativa", na.rm = TRUE))
message("Periodo              : ", min(dii$ano, na.rm = TRUE), " - ", max(dii$ano, na.rm = TRUE))
message("Obitos               : ", sum(dii$obito, na.rm = TRUE))
message("Valor total gasto    : R$ ", format(sum(dii$val_total, na.rm = TRUE), big.mark = ".", decimal.mark = ",", nsmall = 2))

# ---------------------------------------------------------------------------- #
#  4. Salvar dados processados                                                  #
# ---------------------------------------------------------------------------- #

saveRDS(dii, "data/processed/dii_limpo.rds")
message("\nSalvo: data/processed/dii_limpo.rds")
