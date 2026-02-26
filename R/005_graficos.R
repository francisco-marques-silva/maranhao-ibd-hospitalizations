# ==============================================================================
# 005_graficos.R
#
# Objetivo : Gerar todas as figuras do estudo e exportar em PNG (300 dpi).
#
#   Fig. 01 — Internações por ano e diagnóstico (série temporal)
#   Fig. 02 — Taxa de internação por 100.000 hab. com linha de tendência
#   Fig. 03 — Série mensal com destaque COVID-19
#   Fig. 04 — Distribuição por sexo (barras proporcionais)
#   Fig. 05 — Pirâmide etária por diagnóstico
#   Fig. 06 — Distribuição por raça/cor
#   Fig. 07 — Box-plot de dias de permanência por período
#   Fig. 08 — Mortalidade hospitalar por ano e diagnóstico
#   Fig. 09 — Custo total anual por diagnóstico
#   Fig. 10 — Mapa coroplético dos municípios do MA
#   Fig. 11 — Top 15 municípios em número de internações
#   Fig. 12 — Comparação de indicadores por período COVID (painel multiplo)
#
# Entrada  : data/processed/*.rds
# Saída    : output/figuras/*.png
#
# Projeto  : Internações hospitalares por DII no Maranhão (2015-2025)
# Data     : Fevereiro de 2026
# ==============================================================================

if (!exists("CID_CROHN")) source("R/000_setup.R")

dii <- readRDS("data/processed/dii_limpo.rds")
desc <- readRDS("data/processed/resultados_descritivos.rds")
temporal <- readRDS("data/processed/resultados_temporal.rds")
geo <- readRDS("data/processed/resultados_geografico.rds")

# Função de conveniência para salvar figuras
salvar_fig <- function(plot, nome, width = 10, height = 6, dpi = 300) {
    caminho <- glue("output/figuras/{nome}.png")
    ggsave(caminho,
        plot = plot, width = width, height = height, dpi = dpi,
        bg = "white", limitsize = FALSE
    )
    message("Salva: ", caminho)
    invisible(plot)
}

# ==============================================================================
#  FIG. 01 — Série temporal de internações por diagnóstico
# ==============================================================================

fig01 <- temporal$serie_anual |>
    filter(diagnostico != "Total DII") |>
    ggplot(aes(x = ano, y = internacoes, colour = diagnostico, group = diagnostico)) +
    geom_line(linewidth = 1.1) +
    geom_point(size = 3, shape = 21, fill = "white", stroke = 1.5) +
    # Total (linha tracejada)
    geom_line(
        data = temporal$serie_anual |> filter(diagnostico == "Total DII"),
        aes(x = ano, y = internacoes),
        colour = "grey30", linewidth = 0.8, linetype = "dashed", inherit.aes = FALSE
    ) +
    scale_colour_manual(values = CORES) +
    scale_x_continuous(breaks = ANO_INICIO:ANO_FIM) +
    scale_y_continuous(labels = label_number(big.mark = ".")) +
    labs(
        title = "Internações hospitalares por DII no Maranhão, 2015–2025",
        subtitle = "Linha cinza tracejada = Total DII",
        x = "Ano", y = "Internações (n)", colour = "Diagnóstico",
        caption = "Fonte: SIH/SUS — DATASUS."
    ) +
    TEMA

salvar_fig(fig01, "fig01_serie_temporal_internacoes")

# ==============================================================================
#  FIG. 02 — Taxa de internação por 100.000 hab. com tendência linear
# ==============================================================================

dados_lm_total <- temporal$serie_taxa |> filter(diagnostico == "Total DII")

fig02 <- temporal$serie_taxa |>
    filter(diagnostico != "Total DII") |>
    ggplot(aes(x = ano, y = taxa_100k, colour = diagnostico, group = diagnostico)) +
    geom_line(linewidth = 1.1) +
    geom_point(size = 3, shape = 21, fill = "white", stroke = 1.5) +
    # Linha de tendência (total) com IC
    geom_smooth(
        data = dados_lm_total,
        aes(x = ano, y = taxa_100k),
        method = "lm", se = TRUE, colour = "grey30", fill = "grey80",
        linewidth = 1, linetype = "dashed", inherit.aes = FALSE
    ) +
    scale_colour_manual(values = CORES) +
    scale_x_continuous(breaks = ANO_INICIO:ANO_FIM) +
    labs(
        title = "Taxa de internação por DII no Maranhão (por 100.000 hab.)",
        subtitle = "Linha cinza = tendência linear do Total DII (com IC 95%)",
        x = "Ano", y = "Taxa / 100.000 hab.", colour = "Diagnóstico",
        caption = "Fonte: SIH/SUS — DATASUS | Denominador: IBGE, Projeções 2015–2025."
    ) +
    TEMA

salvar_fig(fig02, "fig02_taxa_100k_tendencia")

# ==============================================================================
#  FIG. 03 — Série mensal com destaque para o período COVID-19
# ==============================================================================

fig03 <- temporal$serie_mensal |>
    filter(diagnostico != "Total DII") |>
    ggplot(aes(x = ano_mes, y = internacoes, colour = diagnostico)) +
    # Destaque COVID-19
    annotate("rect",
        xmin = as.Date("2020-03-01"), xmax = as.Date("2021-12-31"),
        ymin = -Inf, ymax = Inf, fill = "#E31A1C", alpha = 0.07
    ) +
    annotate("text",
        x = as.Date("2020-10-01"), y = Inf,
        label = "COVID-19", vjust = 1.5, colour = "#E31A1C",
        size = 3, fontface = "bold"
    ) +
    geom_line(linewidth = 0.9, alpha = 0.85) +
    scale_colour_manual(values = CORES) +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    labs(
        title = "Série mensal de internações por DII — Maranhão, 2015–2025",
        subtitle = "Período COVID-19 destacado",
        x = "Mês/Ano", y = "Internações (n)", colour = "Diagnóstico",
        caption = "Fonte: SIH/SUS — DATASUS."
    ) +
    TEMA +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

salvar_fig(fig03, "fig03_serie_mensal_covid", width = 12, height = 5)

# ==============================================================================
#  FIG. 04 — Distribuição proporcional por sexo
# ==============================================================================

fig04 <- desc$sexo |>
    filter(!is.na(sexo)) |>
    ggplot(aes(x = diagnostico, y = pct, fill = sexo)) +
    geom_col(position = "fill", width = 0.6) +
    geom_text(
        aes(label = paste0(pct, "%")),
        position = position_fill(vjust = 0.5),
        colour = "white", size = 4, fontface = "bold"
    ) +
    scale_fill_manual(values = CORES) +
    scale_y_continuous(labels = label_percent()) +
    labs(
        title = "Distribuição por sexo das internações por DII",
        x = NULL, y = "Proporção", fill = "Sexo",
        caption = "Fonte: SIH/SUS — DATASUS."
    ) +
    TEMA

salvar_fig(fig04, "fig04_distribuicao_sexo", width = 7, height = 5)

# ==============================================================================
#  FIG. 05 — Pirâmide etária por diagnóstico
# ==============================================================================

piramide_data <- dii |>
    filter(!is.na(faixa_etaria), !is.na(sexo)) |>
    count(faixa_etaria, sexo, diagnostico) |>
    mutate(n_plot = if_else(sexo == "Masculino", -n, n))

fig05 <- piramide_data |>
    ggplot(aes(x = n_plot, y = faixa_etaria, fill = sexo)) +
    geom_col() +
    geom_vline(xintercept = 0, colour = "grey30", linewidth = 0.5) +
    facet_wrap(~diagnostico, scales = "free_x") +
    scale_fill_manual(values = CORES) +
    scale_x_continuous(labels = \(x) label_number(big.mark = ".")(abs(x))) +
    labs(
        title = "Pirâmide etária das internações por DII — Maranhão, 2015–2025",
        x = "Número de internações", y = "Faixa etária", fill = "Sexo",
        caption = "Fonte: SIH/SUS — DATASUS."
    ) +
    TEMA

salvar_fig(fig05, "fig05_piramide_etaria", width = 12, height = 6)

# ==============================================================================
#  FIG. 06 — Distribuição por raça/cor
# ==============================================================================

fig06 <- desc$raca_cor |>
    filter(raca_cor != "Sem informacao") |>
    ggplot(aes(x = reorder(raca_cor, pct), y = pct, fill = diagnostico)) +
    geom_col(position = "dodge", width = 0.7) +
    scale_fill_manual(values = CORES) +
    scale_y_continuous(labels = label_percent(scale = 1)) +
    coord_flip() +
    labs(
        title = "Distribuição por raça/cor das internações por DII",
        subtitle = "Excluídos registros sem informação de raça/cor",
        x = NULL, y = "Proporção (%)", fill = "Diagnóstico",
        caption = "Fonte: SIH/SUS — DATASUS."
    ) +
    TEMA

salvar_fig(fig06, "fig06_distribuicao_raca_cor", width = 9, height = 5)

# ==============================================================================
#  FIG. 07 — Box-plot de permanência hospitalar por período
# ==============================================================================

fig07 <- dii |>
    filter(!is.na(dias_perm), !is.na(periodo)) |>
    ggplot(aes(x = periodo, y = dias_perm, fill = diagnostico)) +
    geom_boxplot(outlier.alpha = 0.3, outlier.size = 0.8, width = 0.6) +
    scale_fill_manual(values = CORES) +
    scale_y_continuous(limits = c(0, 60)) +
    labs(
        title = "Permanência hospitalar por diagnóstico e período",
        subtitle = "Internações > 60 dias omitidas do gráfico",
        x = NULL, y = "Dias de permanência", fill = "Diagnóstico",
        caption = "Fonte: SIH/SUS — DATASUS."
    ) +
    TEMA +
    theme(axis.text.x = element_text(angle = 12, hjust = 1))

salvar_fig(fig07, "fig07_permanencia_boxplot", width = 10, height = 6)

# ==============================================================================
#  FIG. 08 — Taxa de mortalidade hospitalar por ano e diagnóstico
# ==============================================================================

mort_ano <- dii |>
    group_by(ano, diagnostico) |>
    summarise(taxa_mort = mean(obito, na.rm = TRUE) * 100, .groups = "drop")

fig08 <- mort_ano |>
    ggplot(aes(x = ano, y = taxa_mort, colour = diagnostico, group = diagnostico)) +
    geom_line(linewidth = 1.1) +
    geom_point(size = 3, shape = 21, fill = "white", stroke = 1.5) +
    scale_colour_manual(values = CORES) +
    scale_x_continuous(breaks = ANO_INICIO:ANO_FIM) +
    labs(
        title = "Taxa de mortalidade hospitalar por DII — Maranhão, 2015–2025",
        x = "Ano", y = "Taxa de mortalidade (%)", colour = "Diagnóstico",
        caption = "Fonte: SIH/SUS — DATASUS."
    ) +
    TEMA

salvar_fig(fig08, "fig08_mortalidade_temporal")

# ==============================================================================
#  FIG. 09 — Custo total anual por diagnóstico
# ==============================================================================

fig09 <- desc$custos_ano |>
    ggplot(aes(x = ano, y = custo_total, fill = diagnostico)) +
    geom_col(position = "stack") +
    scale_fill_manual(values = CORES) +
    scale_x_continuous(breaks = ANO_INICIO:ANO_FIM) +
    scale_y_continuous(labels = label_dollar(prefix = "R$ ", big.mark = ".", decimal.mark = ",")) +
    labs(
        title = "Custo total (SUS) das internações por DII — Maranhão, 2015–2025",
        x = "Ano", y = "Custo total (R$)", fill = "Diagnóstico",
        caption = "Fonte: SIH/SUS — DATASUS."
    ) +
    TEMA

salvar_fig(fig09, "fig09_custo_anual_total")

# ==============================================================================
#  FIG. 10 — Mapa coroplético (municípios do MA)
# ==============================================================================

if (!is.null(geo$mapa_sf)) {
    fig10 <- geo$mapa_sf |>
        ggplot() +
        geom_sf(aes(fill = faixa_intern), colour = "white", linewidth = 0.08) +
        scale_fill_manual(
            values = c(
                "0"     = "#F7FBFF",
                "1-5"   = "#C6DBEF",
                "6-15"  = "#6BAED6",
                "16-30" = "#2171B5",
                "31-60" = "#08519C",
                "60+"   = "#08306B"
            ),
            na.value = "grey90",
            name = "Internações (n)"
        ) +
        labs(
            title    = "Internações por DII por município de residência — Maranhão, 2015–2025",
            subtitle = "Município de residência do paciente",
            caption  = "Fonte: SIH/SUS — DATASUS | Malha: IBGE 2020, geobr."
        ) +
        theme_void(base_size = 12) +
        theme(
            plot.title = element_text(face = "bold", size = 12),
            plot.subtitle = element_text(colour = "grey40"),
            plot.caption = element_text(colour = "grey55", size = 8),
            legend.position = "right"
        )

    salvar_fig(fig10, "fig10_mapa_municipios", width = 9, height = 9)
} else {
    message("Fig.10 (mapa) nao gerada — malha geografica indisponivel.")
}

# ==============================================================================
#  FIG. 11 — Top 15 municípios por internações
# ==============================================================================

top15 <- geo$intern_munic_long |>
    head(15)

fig11 <- top15 |>
    ggplot(aes(x = reorder(cod_munic_res, total), y = total)) +
    geom_col(fill = CORES["Doenca de Crohn"], alpha = 0.85) +
    geom_text(aes(label = total), hjust = -0.2, size = 3.5) +
    coord_flip() +
    scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
    labs(
        title = "Top 15 municípios por internações por DII — Maranhão, 2015–2025",
        subtitle = "Município de residência do paciente (código IBGE de 6 dígitos)",
        x = "Código IBGE (6 díg.)", y = "Internações (n)",
        caption = "Fonte: SIH/SUS — DATASUS."
    ) +
    TEMA

salvar_fig(fig11, "fig11_top15_municipios", width = 9, height = 6)

# ==============================================================================
#  FIG. 12 — Painel: comparação de indicadores por período COVID
# ==============================================================================

# Sub-fig A: internações médias anuais
f12a <- temporal$var_periodo |>
    filter(diagnostico != "Total DII") |>
    ggplot(aes(x = periodo, y = media_anual, fill = diagnostico)) +
    geom_col(position = "dodge", width = 0.6) +
    geom_text(aes(label = round(media_anual, 1)),
        position = position_dodge(width = 0.6), vjust = -0.4, size = 3.5
    ) +
    scale_fill_manual(values = CORES) +
    labs(
        title = "Média anual de internações", x = NULL, y = "Internações/ano",
        fill = "Diagnóstico"
    ) +
    TEMA +
    theme(axis.text.x = element_text(angle = 12, hjust = 1), legend.position = "none")

# Sub-fig B: taxa de mortalidade por período
mort_periodo <- dii |>
    group_by(periodo, diagnostico) |>
    summarise(taxa_mort = mean(obito, na.rm = TRUE) * 100, .groups = "drop")

f12b <- mort_periodo |>
    ggplot(aes(x = periodo, y = taxa_mort, fill = diagnostico)) +
    geom_col(position = "dodge", width = 0.6) +
    geom_text(aes(label = sprintf("%.1f%%", taxa_mort)),
        position = position_dodge(width = 0.6), vjust = -0.4, size = 3.5
    ) +
    scale_fill_manual(values = CORES) +
    labs(title = "Taxa de mortalidade por período (%)", x = NULL, y = "%", fill = NULL) +
    TEMA +
    theme(axis.text.x = element_text(angle = 12, hjust = 1), legend.position = "bottom")

fig12 <- (f12a / f12b) +
    plot_annotation(
        title   = "Impacto da pandemia de COVID-19 nas internações por DII — Maranhão",
        caption = "Fonte: SIH/SUS — DATASUS."
    )

salvar_fig(fig12, "fig12_impacto_covid", width = 10, height = 8)

message("\nTodas as figuras geradas e salvas em 'output/figuras/'.")
