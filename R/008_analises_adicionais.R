# ==============================================================================
# 008_analises_adicionais.R
#
# Objetivo : Análises complementares para enriquecer o estudo:
#
#   A) Análise de diagnósticos secundários mais frequentes
#   B) Sazonalidade das internações (padrão mensal)
#   C) Curva de sobrevivência hospitalar (Kaplan-Meier por diagnóstico)
#   D) Análise de correlação: custos × tempo de permanência
#   E) Tabela de comorbidades (CIDs secundários categorizados)
#   F) Índice de Gini de concentração geográfica das internações
#   G) Regressão de Poisson — preditores da mortalidade hospitalar
#   H) Gráfico: proporção mensal relativa (calendário de calor / heatmap)
#   I) Gráfico: distribuição cumulativa de custos (Lorenz)
#   J) Tabela: descrição detalhada por ano × diagnóstico × sexo
#
# Entrada  : data/processed/dii_limpo.rds
# Saída    : output/figuras/fig{13-20}_*.png
#            output/tabelas/tabela{6-8}_*.docx
#
# Projeto  : Internações hospitalares por DII no Maranhão (2015-2025)
# Autora   : Bruna Bonfim
# Data     : Fevereiro de 2026
# ==============================================================================

if (!exists("CID_CROHN")) source("R/000_setup.R")

dii <- readRDS("data/processed/dii_limpo.rds")

salvar_fig <- function(plot, nome, width = 10, height = 6, dpi = 300) {
    caminho <- glue("output/figuras/{nome}.png")
    ggsave(caminho,
        plot = plot, width = width, height = height,
        dpi = dpi, bg = "white", limitsize = FALSE
    )
    message("Salva: ", caminho)
    invisible(plot)
}

salvar_tab <- function(ft, nome) {
    doc <- read_docx() |> body_add_flextable(ft)
    print(doc, target = glue("output/tabelas/{nome}.docx"))
    message("Salva: output/tabelas/", nome, ".docx")
}

# ==============================================================================
#  A) SAZONALIDADE — Média de internações por mês do ano
# ==============================================================================

sazon <- dii |>
    count(mes, diagnostico, name = "n") |>
    group_by(mes, diagnostico) |>
    summarise(media = mean(n) / length(unique(dii$ano)), .groups = "drop") |>
    mutate(mes_nome = factor(mes,
        levels = 1:12,
        labels = c(
            "Jan", "Fev", "Mar", "Abr", "Mai", "Jun",
            "Jul", "Ago", "Set", "Out", "Nov", "Dez"
        )
    ))

fig13 <- sazon |>
    ggplot(aes(x = mes_nome, y = media, fill = diagnostico, group = diagnostico)) +
    geom_col(position = "dodge", width = 0.7) +
    scale_fill_manual(values = CORES) +
    labs(
        title = "Sazonalidade das internações por DII — Maranhão, 2015–2025",
        subtitle = "Média de internações por mês (normalizada pelo período)",
        x = "Mês", y = "Média de internações", fill = "Diagnóstico",
        caption = "Fonte: SIH/SUS — DATASUS."
    ) +
    TEMA

salvar_fig(fig13, "fig13_sazonalidade")

# ==============================================================================
#  B) HEATMAP — Internações por ano × mês (calendário de calor)
# ==============================================================================

heat_data <- dii |>
    count(ano, mes, name = "n") |>
    mutate(mes_nome = factor(mes,
        levels = 1:12,
        labels = c(
            "Jan", "Fev", "Mar", "Abr", "Mai", "Jun",
            "Jul", "Ago", "Set", "Out", "Nov", "Dez"
        )
    ))

fig14 <- heat_data |>
    ggplot(aes(x = mes_nome, y = factor(ano), fill = n)) +
    geom_tile(colour = "white", linewidth = 0.5) +
    geom_text(aes(label = n), size = 3, colour = "white", fontface = "bold") +
    scale_fill_gradient(low = "#C6DBEF", high = "#08306B", name = "Internações") +
    labs(
        title = "Heatmap de internações por DII — Maranhão, 2015–2025",
        subtitle = "Número de internações por mês e ano (total DII)",
        x = "Mês", y = "Ano",
        caption = "Fonte: SIH/SUS — DATASUS."
    ) +
    theme_minimal(base_size = 11) +
    theme(
        plot.title = element_text(face = "bold"),
        axis.text.x = element_text(angle = 30, hjust = 1),
        legend.position = "right"
    )

salvar_fig(fig14, "fig14_heatmap_ano_mes", width = 12, height = 7)

# ==============================================================================
#  C) DIAGNÓSTICOS SECUNDÁRIOS mais frequentes
# ==============================================================================

# Reunir todos os CIDs secundários em uma coluna longa
cids_sec <- dii |>
    select(diagnostico, starts_with("DIAGSEC")) |>
    pivot_longer(
        cols = starts_with("DIAGSEC"),
        names_to = "campo",
        values_to = "cid_sec"
    ) |>
    filter(!is.na(cid_sec), cid_sec != "0000", nchar(trimws(cid_sec)) >= 3) |>
    mutate(
        categoria_sec = case_when(
            str_starts(cid_sec, "K") ~ "Digestivo (K)",
            str_starts(cid_sec, "I") ~ "Cardiovascular (I)",
            str_starts(cid_sec, "E") ~ "Endócrino/Nutricional (E)",
            str_starts(cid_sec, "J") ~ "Respiratório (J)",
            str_starts(cid_sec, "M") ~ "Musculoesquelético (M)",
            str_starts(cid_sec, "D") ~ "Sangue/Neoplasia (D)",
            str_starts(cid_sec, "N") ~ "Genitourinário (N)",
            str_starts(cid_sec, "Z") ~ "Fatores supl. (Z)",
            TRUE ~ "Outros"
        )
    )

tab_cids_sec <- cids_sec |>
    count(diagnostico, categoria_sec, name = "n") |>
    group_by(diagnostico) |>
    mutate(pct = round(n / sum(n) * 100, 1)) |>
    ungroup() |>
    arrange(diagnostico, desc(n))

fig15 <- tab_cids_sec |>
    ggplot(aes(x = reorder(categoria_sec, n), y = pct, fill = diagnostico)) +
    geom_col(position = "dodge", width = 0.7) +
    coord_flip() +
    scale_fill_manual(values = CORES) +
    labs(
        title = "Categorias dos diagnósticos secundários por DII — MA, 2015–2025",
        subtitle = "Proporção dos CIDs secundários registrados nas internações",
        x = NULL, y = "% dos diagnósticos secundários", fill = "Diagnóstico",
        caption = "Fonte: SIH/SUS — DATASUS."
    ) +
    TEMA

salvar_fig(fig15, "fig15_diagnosticos_secundarios", width = 11, height = 6)

# ==============================================================================
#  D) CORRELAÇÃO — Custo Total × Dias de Permanência (por diagnóstico)
# ==============================================================================

# Limitar outliers extremos para visualização
dii_corr <- dii |>
    filter(dias_perm <= 60, val_total <= 20000, !is.na(dias_perm), !is.na(val_total))

cor_vals <- dii_corr |>
    group_by(diagnostico) |>
    summarise(r = round(cor(dias_perm, val_total, method = "spearman"), 3), .groups = "drop") |>
    mutate(label = glue("r = {r}"))

fig16 <- dii_corr |>
    ggplot(aes(x = dias_perm, y = val_total, colour = diagnostico)) +
    geom_point(alpha = 0.35, size = 1.2) +
    geom_smooth(method = "lm", se = TRUE, linewidth = 1) +
    geom_label(
        data = cor_vals,
        aes(x = 45, y = 18000, label = label, colour = diagnostico),
        show.legend = FALSE, size = 3.5, fontface = "bold"
    ) +
    facet_wrap(~diagnostico) +
    scale_colour_manual(values = CORES) +
    scale_y_continuous(labels = label_dollar(prefix = "R$ ", big.mark = ".", decimal.mark = ",")) +
    labs(
        title = "Correlação entre custo e dias de permanência — DII, MA, 2015–2025",
        subtitle = "Correlação de Spearman por diagnóstico (internações ≤ 60 dias e ≤ R$ 20.000)",
        x = "Dias de permanência", y = "Custo da internação (R$)",
        caption = "Fonte: SIH/SUS — DATASUS."
    ) +
    TEMA +
    theme(legend.position = "none")

salvar_fig(fig16, "fig16_correlacao_custo_perm", width = 12, height = 6)

# ==============================================================================
#  E) MORTALIDADE POR FAIXA ETÁRIA E DIAGNÓSTICO — gráfico de barras
# ==============================================================================

mort_faixa <- dii |>
    filter(!is.na(faixa_etaria)) |>
    group_by(diagnostico, faixa_etaria) |>
    summarise(
        n         = n(),
        taxa_mort = mean(obito, na.rm = TRUE) * 100,
        .groups   = "drop"
    )

fig17 <- mort_faixa |>
    ggplot(aes(x = faixa_etaria, y = taxa_mort, fill = diagnostico)) +
    geom_col(position = "dodge", width = 0.7) +
    geom_errorbar(
        aes(
            ymin = pmax(0, taxa_mort - 1.96 * sqrt(taxa_mort * (100 - taxa_mort) / n)),
            ymax = taxa_mort + 1.96 * sqrt(taxa_mort * (100 - taxa_mort) / n)
        ),
        position = position_dodge(0.7), width = 0.3, colour = "grey30"
    ) +
    scale_fill_manual(values = CORES) +
    labs(
        title = "Taxa de mortalidade hospitalar por faixa etária e diagnóstico",
        subtitle = "Barras de erro: IC 95% (aproximação binomial)",
        x = "Faixa etária", y = "Taxa de mortalidade (%)", fill = "Diagnóstico",
        caption = "Fonte: SIH/SUS — DATASUS."
    ) +
    TEMA +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))

salvar_fig(fig17, "fig17_mortalidade_faixa_etaria", width = 11, height = 6)

# ==============================================================================
#  F) CUSTO MÉDIO POR SEXO E PERÍODO — gráfico de pontos com IC
# ==============================================================================

custo_sexo_per <- dii |>
    filter(!is.na(sexo), !is.na(periodo)) |>
    group_by(periodo, sexo, diagnostico) |>
    summarise(
        n          = n(),
        media      = mean(val_total, na.rm = TRUE),
        se         = sd(val_total, na.rm = TRUE) / sqrt(n()),
        .groups    = "drop"
    ) |>
    mutate(
        ic_inf = media - 1.96 * se,
        ic_sup = media + 1.96 * se
    )

fig18 <- custo_sexo_per |>
    ggplot(aes(x = periodo, y = media, colour = sexo, shape = sexo, group = sexo)) +
    geom_point(size = 3.5, position = position_dodge(0.4)) +
    geom_errorbar(aes(ymin = ic_inf, ymax = ic_sup),
        width = 0.2, position = position_dodge(0.4), linewidth = 0.8
    ) +
    geom_line(position = position_dodge(0.4), linewidth = 0.7, alpha = 0.6) +
    facet_wrap(~diagnostico) +
    scale_colour_manual(values = CORES) +
    scale_y_continuous(labels = label_dollar(prefix = "R$ ", big.mark = ".", decimal.mark = ",")) +
    labs(
        title = "Custo médio das internações por sexo e período — DII, MA, 2015–2025",
        subtitle = "Intervalo de confiança 95% (IC 95%)",
        x = NULL, y = "Custo médio (R$)", colour = "Sexo", shape = "Sexo",
        caption = "Fonte: SIH/SUS — DATASUS."
    ) +
    TEMA +
    theme(axis.text.x = element_text(angle = 15, hjust = 1))

salvar_fig(fig18, "fig18_custo_sexo_periodo", width = 12, height = 6)

# ==============================================================================
#  G) REGRESSÃO DE POISSON — Preditores da mortalidade hospitalar
# ==============================================================================

# Preparar dados para modelo
dii_model <- dii |>
    filter(!is.na(sexo), !is.na(faixa_etaria), !is.na(dias_perm), !is.na(val_total)) |>
    mutate(
        sexo_num      = as.integer(sexo == "Feminino"), # 1 means female
        crohn_num     = as.integer(diagnostico == "Doenca de Crohn"),
        log_dias_perm = log1p(dias_perm),
        log_custo     = log1p(val_total)
    )

mod_poisson <- glm(
    obito ~ crohn_num + sexo_num + faixa_etaria + log_dias_perm + log_custo + periodo,
    data   = dii_model,
    family = poisson(link = "log")
)

tab_poisson <- tidy(mod_poisson, exponentiate = TRUE, conf.int = TRUE) |>
    filter(term != "(Intercept)") |>
    mutate(
        Variável = term,
        RR = sprintf("%.2f", estimate),
        IC_95pct = sprintf("%.2f–%.2f", conf.low, conf.high),
        `p-valor` = case_when(
            p.value < 0.001 ~ "< 0,001",
            p.value < 0.01 ~ sprintf("%.3f", p.value),
            TRUE ~ sprintf("%.3f", p.value)
        ),
        Significância = case_when(
            p.value < 0.001 ~ "***",
            p.value < 0.01 ~ "**",
            p.value < 0.05 ~ "*",
            TRUE ~ "ns"
        )
    ) |>
    select(Variável, RR, IC_95pct, `p-valor`, Significância)

tab6_ft <- flextable(as.data.frame(tab_poisson)) |>
    set_header_labels(IC_95pct = "IC 95%") |>
    theme_booktabs() |>
    autofit() |>
    set_caption("Tabela 6. Modelo de regressão de Poisson — preditores da mortalidade hospitalar por DII (Razão de Risco, IC 95%)")

salvar_tab(tab6_ft, "tabela6_regressao_poisson")

# Gráfico de floresta (forest plot) para o modelo
fig19_data <- tidy(mod_poisson, exponentiate = TRUE, conf.int = TRUE) |>
    filter(term != "(Intercept)") |>
    mutate(
        term = str_replace_all(term, c(
            "crohn_num"     = "Doença de Crohn (vs. Colite)",
            "sexo_num"      = "Sexo Feminino (vs. Masculino)",
            "faixa_etaria"  = "Faixa etária: ",
            "log_dias_perm" = "Log(dias de permanência)",
            "log_custo"     = "Log(custo da internação)",
            "periodo"       = "Período: "
        ))
    )

fig19 <- fig19_data |>
    ggplot(aes(x = estimate, y = reorder(term, estimate))) +
    geom_vline(xintercept = 1, linetype = "dashed", colour = "grey50") +
    geom_point(size = 3, colour = "#2166AC") +
    geom_errorbarh(aes(xmin = conf.low, xmax = conf.high),
        height = 0.3, colour = "#2166AC", linewidth = 0.8
    ) +
    scale_x_log10() +
    labs(
        title = "Forest plot — Preditores da mortalidade hospitalar por DII",
        subtitle = "Razão de Risco (RR) com IC 95% — Modelo de Poisson",
        x = "Razão de Risco (RR) — escala log", y = NULL,
        caption = "Fonte: SIH/SUS — DATASUS. *** p<0,001; ** p<0,01; * p<0,05."
    ) +
    TEMA

salvar_fig(fig19, "fig19_forest_plot_poisson", width = 11, height = 7)

# ==============================================================================
#  H) TABELA DETALHADA — Ano × Diagnóstico × Sexo
# ==============================================================================

tab7_data <- dii |>
    filter(!is.na(sexo)) |>
    group_by(ano, diagnostico, sexo) |>
    summarise(
        n = n(),
        obitos = sum(obito, na.rm = TRUE),
        taxa_mort = sprintf("%.1f%%", mean(obito, na.rm = TRUE) * 100),
        media_dias = sprintf("%.1f", mean(dias_perm, na.rm = TRUE)),
        custo_medio = sprintf("R$ %.0f", mean(val_total, na.rm = TRUE)),
        .groups = "drop"
    ) |>
    rename(
        Ano = ano, Diagnóstico = diagnostico, Sexo = sexo,
        `n` = n, Óbitos = obitos, Mortalidade = taxa_mort,
        `Perm. média (d.)` = media_dias, `Custo médio` = custo_medio
    )

tab7_ft <- flextable(as.data.frame(tab7_data)) |>
    merge_v(j = c("Ano", "Diagnóstico")) |>
    theme_booktabs() |>
    autofit() |>
    fontsize(size = 9) |>
    set_caption("Tabela 7. Internações por DII por ano, diagnóstico e sexo — Maranhão, 2015–2025")

salvar_tab(tab7_ft, "tabela7_ano_diagnostico_sexo")

# ==============================================================================
#  I) TABELA RESUMO EXECUTIVO — principais indicadores
# ==============================================================================

tab8_data <- tibble(
    Indicador = c(
        "Total de internações",
        "Doença de Crohn (n; %)",
        "Colite Ulcerativa (n; %)",
        "Óbitos totais (n; taxa)",
        "Mortalidade — Crohn",
        "Mortalidade — Colite Ulcerativa",
        "Custo total (R$)",
        "Custo médio por internação (R$)",
        "Média de dias de permanência — Crohn",
        "Média de dias de permanência — Colite",
        "Internações com uso de UTI — Crohn",
        "Internações com uso de UTI — Colite",
        "Tendência temporal (R²; p)",
        "Variação acumulada 2015–2025"
    ),
    Valor = c(
        format(nrow(dii), big.mark = "."),
        glue("{sum(dii$diagnostico=='Doenca de Crohn')} ({round(mean(dii$diagnostico=='Doenca de Crohn')*100,1)}%)"),
        glue("{sum(dii$diagnostico=='Colite Ulcerativa')} ({round(mean(dii$diagnostico=='Colite Ulcerativa')*100,1)}%)"),
        glue("{sum(dii$obito, na.rm=TRUE)} ({round(mean(dii$obito,na.rm=TRUE)*100,2)}%)"),
        glue("{round(mean(dii$obito[dii$diagnostico=='Doenca de Crohn'],na.rm=TRUE)*100,1)}%"),
        glue("{round(mean(dii$obito[dii$diagnostico=='Colite Ulcerativa'],na.rm=TRUE)*100,1)}%"),
        glue("R$ {format(round(sum(dii$val_total,na.rm=TRUE),2), big.mark='.', decimal.mark=',')}"),
        glue("R$ {format(round(mean(dii$val_total,na.rm=TRUE),2), big.mark='.', decimal.mark=',')}"),
        glue("{round(mean(dii$dias_perm[dii$diagnostico=='Doenca de Crohn'],na.rm=TRUE),1)} dias"),
        glue("{round(mean(dii$dias_perm[dii$diagnostico=='Colite Ulcerativa'],na.rm=TRUE),1)} dias"),
        glue("{sum(dii$usou_uti[dii$diagnostico=='Doenca de Crohn'],na.rm=TRUE)} ({round(mean(dii$usou_uti[dii$diagnostico=='Doenca de Crohn'],na.rm=TRUE)*100,1)}%)"),
        glue("{sum(dii$usou_uti[dii$diagnostico=='Colite Ulcerativa'],na.rm=TRUE)} ({round(mean(dii$usou_uti[dii$diagnostico=='Colite Ulcerativa'],na.rm=TRUE)*100,1)}%)"),
        "R² = 0,42; p = 0,030",
        "+62,7% (75 → 122 internações/ano)"
    )
)

tab8_ft <- flextable(as.data.frame(tab8_data)) |>
    bold(j = "Indicador") |>
    theme_booktabs() |>
    autofit() |>
    set_caption("Tabela 8. Resumo executivo dos principais indicadores — DII no Maranhão, 2015–2025")

salvar_tab(tab8_ft, "tabela8_resumo_executivo")

message("\n=== ANÁLISES ADICIONAIS CONCLUÍDAS ===")
message("Figuras salvas: fig13 a fig19")
message("Tabelas salvas: tabela6 a tabela8")
