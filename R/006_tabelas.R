# ==============================================================================
# 006_tabelas.R
#
# Objetivo : Criar e exportar tabelas formatadas para publicação científica.
#
#   Tab. 1 — Características sociodemográficas e clínicas por diagnóstico
#   Tab. 2 — Internações e taxas de internação anuais (2015–2025)
#   Tab. 3 — Mortalidade hospitalar por diagnóstico, sexo e faixa etária
#   Tab. 4 — Custo das internações por diagnóstico e ano
#   Tab. 5 — Comparação entre períodos pré/durante/pós-COVID-19
#
# Formato  : .docx (Word) + .html (web)
# Saída    : output/tabelas/
#
# Projeto  : Internações hospitalares por DII no Maranhão (2015-2025)
# Data     : Fevereiro de 2026
# ==============================================================================

if (!exists("CID_CROHN")) source("R/000_setup.R")

desc <- readRDS("data/processed/resultados_descritivos.rds")
temporal <- readRDS("data/processed/resultados_temporal.rds")
dii <- readRDS("data/processed/dii_limpo.rds")

# Atalho para salvar tabela como .docx (+ HTML básico sem pandoc)
salvar_tabela <- function(ft, nome) {
    # Word (.docx) — não precisa de pandoc
    doc <- read_docx() |> body_add_flextable(ft)
    print(doc, target = glue("output/tabelas/{nome}.docx"))
    # HTML via flextable_to_rmd → fallback sem pandoc
    html_str <- tryCatch(
        htmltools_value(ft), # retorna objeto htmltools
        error = function(e) NULL
    )
    if (!is.null(html_str)) {
        html_out <- paste0(
            "<!DOCTYPE html><html><head><meta charset='UTF-8'>",
            "<style>body{font-family:Arial,sans-serif;padding:20px}</style></head><body>",
            as.character(html_str),
            "</body></html>"
        )
        writeLines(html_out, glue("output/tabelas/{nome}.html"))
    }
    message("Salva: output/tabelas/", nome, ".(docx|html)")
}

# Formatadores auxiliares
fmt_n_pct <- function(n, p) glue("{n} ({sprintf('%.1f', p)}%)")
fmt_med_dp <- function(m, d) glue("{sprintf('%.1f', m)} ± {sprintf('%.1f', d)}")
fmt_brl <- function(x) glue("R$ {format(round(x, 2), big.mark = '.', decimal.mark = ',', nsmall = 2)}")

# ==============================================================================
#  TAB. 1 — Características sociodemográficas e clínicas
# ==============================================================================

# Montar tabela 1 no formato largo para publicação
tab1_sexo <- desc$sexo |>
    mutate(valor = fmt_n_pct(n, pct)) |>
    select(diagnostico, sexo, valor) |>
    pivot_wider(names_from = diagnostico, values_from = valor) |>
    rename(Característica = sexo) |>
    mutate(Categoria = "Sexo")

tab1_faixa <- desc$faixa_etaria |>
    mutate(valor = fmt_n_pct(n, pct)) |>
    select(diagnostico, faixa_etaria, valor) |>
    pivot_wider(names_from = diagnostico, values_from = valor) |>
    rename(Característica = faixa_etaria) |>
    mutate(Categoria = "Faixa Etária")

tab1_raca <- desc$raca_cor |>
    filter(raca_cor != "Sem informacao") |>
    mutate(valor = fmt_n_pct(n, pct)) |>
    select(diagnostico, raca_cor, valor) |>
    pivot_wider(names_from = diagnostico, values_from = valor) |>
    rename(Característica = raca_cor) |>
    mutate(Categoria = "Raça/Cor")

tab1_bind <- bind_rows(tab1_sexo, tab1_faixa, tab1_raca) |>
    select(Categoria, Característica, `Doenca de Crohn`, `Colite Ulcerativa`)

tab1_ft <- flextable(tab1_bind) |>
    merge_v(j = "Categoria") |>
    bold(j = "Categoria") |>
    set_header_labels(
        Categoria           = "Categoria",
        Característica      = "Característica",
        `Doenca de Crohn`   = "Doença de Crohn\nn (%)",
        `Colite Ulcerativa` = "Colite Ulcerativa\nn (%)"
    ) |>
    theme_booktabs() |>
    autofit() |>
    set_caption("Tabela 1. Características sociodemográficas das internações por DII no Maranhão, 2015–2025")

salvar_tabela(tab1_ft, "tabela1_sociodemografico")

# ==============================================================================
#  TAB. 2 — Série temporal com taxas por 100.000 hab.
# ==============================================================================

tab2_data <- temporal$serie_taxa |>
    select(ano, diagnostico, internacoes, taxa_100k) |>
    pivot_wider(
        names_from  = diagnostico,
        values_from = c(internacoes, taxa_100k)
    ) |>
    rename(
        Ano               = ano,
        `n — Crohn`       = `internacoes_Doenca de Crohn`,
        `n — Colite`      = `internacoes_Colite Ulcerativa`,
        `n — Total`       = `internacoes_Total DII`,
        `Taxa — Crohn`    = `taxa_100k_Doenca de Crohn`,
        `Taxa — Colite`   = `taxa_100k_Colite Ulcerativa`,
        `Taxa — Total`    = `taxa_100k_Total DII`
    ) |>
    mutate(across(starts_with("Taxa"), ~ sprintf("%.2f", .x)))

tab2_ft <- flextable(tab2_data) |>
    add_header_row(
        values    = c("", "Internações (n)", "Taxa por 100.000 hab."),
        colwidths = c(1, 3, 3)
    ) |>
    theme_booktabs() |>
    autofit() |>
    set_caption("Tabela 2. Internações e taxas de internação por DII no Maranhão, 2015–2025")

salvar_tabela(tab2_ft, "tabela2_serie_temporal")

# ==============================================================================
#  TAB. 3 — Mortalidade hospitalar por subgrupos
# ==============================================================================

tab3_total <- desc$mortalidade |>
    mutate(Subgrupo = as.character(diagnostico), .before = 1) |>
    select(Subgrupo, internacoes, obitos, taxa_mort)

tab3_sexo <- desc$mort_sexo |>
    mutate(Subgrupo = glue("{diagnostico} — {sexo}"), .before = 1) |>
    select(Subgrupo, internacoes, obitos, taxa_mort)

tab3_faixa <- desc$mort_faixa |>
    mutate(Subgrupo = glue("{diagnostico} — {faixa_etaria}"), .before = 1) |>
    select(Subgrupo, internacoes, obitos, taxa_mort)

tab3_data <- bind_rows(tab3_total, tab3_sexo, tab3_faixa) |>
    mutate(taxa_mort = sprintf("%.2f%%", taxa_mort))

tab3_ft <- flextable(tab3_data) |>
    set_header_labels(
        Subgrupo     = "Grupo",
        internacoes  = "Internações (n)",
        obitos       = "Óbitos (n)",
        taxa_mort    = "Taxa de mortalidade (%)"
    ) |>
    theme_booktabs() |>
    autofit() |>
    set_caption("Tabela 3. Mortalidade hospitalar por DII no Maranhão, 2015–2025")

salvar_tabela(tab3_ft, "tabela3_mortalidade")

# ==============================================================================
#  TAB. 4 — Custos por diagnóstico e ano
# ==============================================================================

tab4_data <- desc$custos_ano |>
    mutate(
        custo_total = fmt_brl(custo_total),
        custo_medio = fmt_brl(custo_medio)
    ) |>
    rename(
        Ano             = ano,
        Diagnóstico     = diagnostico,
        `Internações`   = internacoes,
        `Custo Total`   = custo_total,
        `Custo Médio`   = custo_medio
    )

tab4_ft <- flextable(tab4_data) |>
    theme_booktabs() |>
    autofit() |>
    set_caption("Tabela 4. Custos das internações por DII — Maranhão, 2015–2025")

salvar_tabela(tab4_ft, "tabela4_custos")

# ==============================================================================
#  TAB. 5 — Comparação entre períodos COVID
# ==============================================================================

tab5_data <- dii |>
    group_by(periodo, diagnostico) |>
    summarise(
        internacoes = n(),
        obitos = sum(obito, na.rm = TRUE),
        taxa_mort = sprintf("%.2f%%", mean(obito, na.rm = TRUE) * 100),
        perm_media = sprintf("%.1f", mean(dias_perm, na.rm = TRUE)),
        custo_medio = fmt_brl(mean(val_total, na.rm = TRUE)),
        .groups = "drop"
    ) |>
    rename(
        Período = periodo,
        Diagnóstico = diagnostico,
        `Internações` = internacoes,
        `Óbitos` = obitos,
        `Mortalidade` = taxa_mort,
        `Perm. média (d.)` = perm_media,
        `Custo médio` = custo_medio
    )

tab5_ft <- flextable(tab5_data) |>
    merge_v(j = "Período") |>
    theme_booktabs() |>
    autofit() |>
    set_caption("Tabela 5. Comparação entre períodos pré, durante e pós-COVID-19 — DII no Maranhão")

salvar_tabela(tab5_ft, "tabela5_pandemia")

message("\nTodas as tabelas exportadas para 'output/tabelas/'.")
