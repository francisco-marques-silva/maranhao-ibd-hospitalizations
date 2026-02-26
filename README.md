# Internações Hospitalares por Doença Inflamatória Intestinal no Maranhão
## Análise Epidemiológica Descritiva — 2015 a 2025

[![R](https://img.shields.io/badge/R-%3E%3D4.2-276DC3?logo=r&logoColor=white)](https://www.r-project.org/)
[![SIH/SUS](https://img.shields.io/badge/Dados-SIH%2FSUS-009c3b)](https://datasus.saude.gov.br/)
[![IBGE](https://img.shields.io/badge/Popula%C3%A7%C3%A3o-IBGE%2FSIDRA-003399)](https://sidra.ibge.gov.br/)
[![Licença](https://img.shields.io/badge/Licen%C3%A7a-MIT-yellow)](LICENSE)

---

## 📋 Sobre o Estudo

Estudo epidemiológico descritivo-analítico que analisa o perfil das **internações hospitalares por Doença Inflamatória Intestinal (DII)** no estado do **Maranhão**, Brasil, entre **2015 e 2025**.

As doenças de interesse são:

| Doença | CID-10 | Característica |
|---|---|---|
| **Doença de Crohn** | K50 | Inflamação transmural, pode afetar qualquer segmento do trato GI |
| **Colite Ulcerativa** | K51 | Inflamação limitada à mucosa do cólon e reto |

Os dados provêm do **Sistema de Informações Hospitalares do SUS (SIH/SUS)** — Ministério da Saúde/DATASUS — e as estimativas populacionais utilizam as **Projeções Populacionais do IBGE (2015–2025)**.

---

## 🎯 Objetivos

### Objetivo Geral
Descrever o perfil epidemiológico das internações por DII no Maranhão entre 2015 e 2025, avaliando tendências temporais, distribuição geográfica e impacto da pandemia de COVID-19.

### Objetivos Específicos
1. Caracterizar o perfil sociodemográfico (sexo, faixa etária, raça/cor) dos pacientes
2. Analisar a tendência temporal de internações e calcular taxas por 100.000 habitantes
3. Avaliar a mortalidade hospitalar e seus preditores (modelo de Poisson)
4. Quantificar os custos das internações para o SUS
5. Mapear a distribuição geográfica por município de residência (Maranhão)
6. Comparar indicadores entre os períodos pré-COVID (2015–2019), COVID (2020–2021) e pós-COVID (2022–2025)
7. Identificar comorbidades e diagnósticos secundários associados

---

## 🔬 Metodologia

### Fonte de Dados
- **Base de dados:** SIH/SUS — Autorização de Internação Hospitalar Reduzida (AIH-RD)
- **Unidade de análise:** internação hospitalar (AIH aprovada)
- **Período:** janeiro de 2015 a dezembro de 2025
- **Recorte geográfico:** Estado do Maranhão (UF = 21)
- **Filtragem:** diagnóstico principal CID-10 K50 (Doença de Crohn) ou K51 (Colite Ulcerativa)
- **Acesso:** pacote `microdatasus` (Saldanha & Bastos, 2019)

### Variáveis Estudadas

| Categoria | Variáveis |
|---|---|
| **Sociodemográficas** | Sexo, idade (calculada), faixa etária, raça/cor |
| **Clínicas** | Diagnóstico principal (K50/K51), diagnósticos secundários, uso de UTI, dias de permanência |
| **Desfechos** | Óbito hospitalar (mortalidade), custo total (R$) |
| **Temporais** | Ano, mês, período (pré/durante/pós-COVID) |
| **Geográficas** | Município de residência (IBGE 6 dígitos) |

### Construção das Variáveis Derivadas

- **Idade:** calculada a partir da data de nascimento (`NASC`) e data de internação (`DT_INTER`) usando intervalos em anos completos; quando indisponível, usa o campo `IDADE` do SIH com `COD_IDADE == 4`
- **Faixa etária:** categorizada em 7 grupos (< 18, 18–29, 30–39, 40–49, 50–59, 60–69, ≥ 70 anos)
- **Período COVID:** Pré-COVID (2015–2019), COVID (2020–2021), Pós-COVID (2022–2025)
- **Raça/cor:** reclassificada conforme categorias IBGE (Branca, Preta, Parda, Amarela, Indígena)
- **Permanência:** outliers > 365 dias foram excluídos como erros de registro

### Análise Estatística

| Análise | Método |
|---|---|
| Descritiva | Frequências absolutas e relativas; medidas de tendência central e dispersão |
| Taxas populacionais | Internações / população × 100.000 (denominador: IBGE, Projeções 2015–2025) |
| Tendência temporal | Regressão linear simples (taxa ~ ano); R² e p-valor do coeficiente angular |
| Mortalidade | Taxa = óbitos / internações × 100 (%); IC 95% por aproximação binomial |
| Correlação | Correlação de Spearman (custo × dias de permanência) |
| Sazonalidade | Média mensal de internações por diagnóstico |
| Preditores de óbito | Regressão de Poisson (link log); razão de risco (RR) com IC 95% |
| Distribuição geográfica | Análise de municípios; mapa coroplético (geobr/IBGE 2020) |

### Critérios de Inclusão e Exclusão

**Inclusão:**
- Internações com diagnóstico principal K50.x ou K51.x
- Pacientes residentes no Maranhão
- Competências de jan/2015 a dez/2025

**Exclusão:**
- Registros com sexo não informado (nas análises estratificadas)
- Permanência > 365 dias (outliers de registro)
- Valores ausentes nas variáveis de interesse (analisados por par disponível)

---

## 📊 Resultados Esperados

### Perfil Descritivo
- Descrição completa da coorte (n = 1.243 internações no período)
- Predominância da Doença de Crohn (~57%) sobre a Colite Ulcerativa (~43%)
- Maior proporção de homens na Doença de Crohn; distribuição equilibrada na Colite Ulcerativa
- Acometimento principalmente em adultos jovens (18–49 anos)
- Predomínio de raça/cor parda (MA possui ~67% de pardos — IBGE 2022)

### Tendência Temporal
- Crescimento estatisticamente significativo das internações no período (tendência crescente, R² ≈ 0,42, p < 0,05)
- Taxa de internação passando de ~1,1 para ~1,7 por 100.000 hab. entre 2015 e 2025
- Variação acumulada de +62,7% no volume de internações

### Mortalidade e Custos
- Mortalidade hospitalar maior na Doença de Crohn (~8,8%) do que na Colite Ulcerativa (~3,6%)
- Custo total SUS no período: ~R$ 1,7 milhão
- Custo médio por internação significativamente maior no Crohn (R$ ~1.919) vs. Colite (R$ ~663)
- Permanência média maior no Crohn (~9,5 dias vs. ~7,0 dias na Colite)

### Impacto da Pandemia COVID-19
- Aumento expressivo de internações por Doença de Crohn durante o período COVID (+127% em relação à média pré-COVID anual)
- Redução de internações por Colite Ulcerativa durante o período COVID (provável subdiagnóstico/represamento)
- Recuperação pós-COVID com novo crescimento em ambas as condições

### Distribuição Geográfica
- Concentração nas capitais e municípios de referência (São Luís - código 211130)
- São Luís responde por ~21% de todas as internações
- Padrão de desigualdade geográfica com interior subrepresentado (barreiras de acesso)

---

## 🗂️ Estrutura do Projeto

```
crohn_dii_ma/
├── R/
│   ├── 000_setup.R                  # Pacotes, constantes, pop. IBGE, tema ggplot
│   ├── 001_limpeza.R                # Padronização de variáveis e criação de derivadas
│   ├── 002_analise_descritiva.R     # Tabelas: sexo, faixa etária, raça/cor, UTI, custos
│   ├── 003_tendencia_temporal.R     # Série anual; taxas/100k (IBGE); regressão linear
│   ├── 004_distribuicao_geografica.R # Ranking de municípios; malha IBGE via geobr
│   ├── 005_graficos.R               # 12 figuras PNG (300 dpi)
│   ├── 006_tabelas.R                # 5 tabelas formatadas (.docx)
│   ├── 007_main.R                   # ⭐ Orquestrador — roda toda a análise
│   └── 008_analises_adicionais.R    # 7 figuras e 3 tabelas extras (Poisson, heatmap...)
├── data/                            # ⚠️ gitignored — não commitado
│   ├── raw/
│   │   └── dii.rds                  # Dados brutos filtrados (K50 e K51 — SIH/SUS)
│   └── processed/                   # Arquivos .rds intermediários gerados automaticamente
├── output/                          # ⚠️ Arquivos gerados são gitignored (*.png, *.docx)
│   ├── figuras/                     # Figuras (fig01–fig19) — reproduzíveis via código
│   └── tabelas/                     # Tabelas (tabela1–tabela8) — reproduzíveis via código
├── .gitignore
├── crohn_colite_ma.Rproj
└── README.md
```

> **Nota sobre outputs:** PNG, DOCX e HTML são gerados automaticamente pelo script e estão listados no `.gitignore`. Todos são **100% reproduzíveis** com `source("R/007_main.R")`.

---

## ⚙️ Como Reproduzir

### Pré-requisitos

- **R** ≥ 4.2 — [r-project.org](https://www.r-project.org/)
- **Rtools 4.5** (Windows) — necessário para compilar `read.dbc`
- **RStudio** (recomendado)
- Arquivo `data/raw/dii.rds` (dados filtrados do SIH/SUS, fornecidos separadamente)

### Passo a passo

```bash
# 1. Clone o repositório
git clone https://github.com/seu-usuario/crohn_dii_ma.git
cd crohn_dii_ma
```

```r
# 2. Abra o projeto no RStudio: clique em crohn_colite_ma.Rproj

# 3. Instale os pacotes (primeira vez apenas)
source("R/000_setup.R")

# 4. Coloque o arquivo dii.rds em data/raw/

# 5. Execute toda a análise
source("R/007_main.R")

# 6. (Opcional) Execute análises adicionais
source("R/008_analises_adicionais.R")
```

Os outputs serão gerados automaticamente em `output/figuras/` e `output/tabelas/`.

---

## 📦 Pacotes Utilizados

| Pacote | Finalidade |
|---|---|
| `microdatasus` | Download e pré-processamento dos dados SIH/DATASUS |
| `tidyverse` | Manipulação e visualização de dados |
| `lubridate` | Manipulação de datas e intervalos |
| `geobr` | Malhas geográficas do Brasil (IBGE) |
| `sf` | Dados espaciais e exportação de mapas |
| `patchwork` | Composição de múltiplos gráficos |
| `scales` | Formatação de eixos e escalas |
| `flextable` | Tabelas compatíveis com Word (.docx) |
| `officer` | Exportação para documentos .docx |
| `broom` | Tidying de saídas de modelos estatísticos |
| `glue` | Interpolação de strings |
| `janitor` | Limpeza de nomes de variáveis |
| `fs` | Manipulação de sistema de arquivos |

---

## 🖼️ Figuras Geradas

| Figura | Conteúdo |
|---|---|
| `fig01` | Série temporal de internações por diagnóstico |
| `fig02` | Taxa de internação/100k hab. com tendência linear |
| `fig03` | Série mensal com destaque COVID-19 |
| `fig04` | Distribuição proporcional por sexo |
| `fig05` | Pirâmide etária por diagnóstico |
| `fig06` | Distribuição por raça/cor |
| `fig07` | Box-plot de permanência por período COVID |
| `fig08` | Mortalidade hospitalar por ano |
| `fig09` | Custo total anual por diagnóstico |
| `fig10` | Mapa coroplético dos municípios do MA |
| `fig11` | Top 15 municípios em internações |
| `fig12` | Painel comparativo COVID (internações + mortalidade) |
| `fig13` | Sazonalidade das internações por mês |
| `fig14` | Heatmap ano × mês (calendário de calor) |
| `fig15` | Diagnósticos secundários (categorias CID) |
| `fig16` | Correlação custo × dias de permanência (Spearman) |
| `fig17` | Mortalidade por faixa etária com IC 95% |
| `fig18` | Custo médio por sexo e período (IC 95%) |
| `fig19` | Forest plot — Regressão de Poisson |

## 📋 Tabelas Geradas

| Tabela | Conteúdo |
|---|---|
| `tabela1` | Características sociodemográficas por diagnóstico |
| `tabela2` | Série temporal com taxas por 100k hab. |
| `tabela3` | Mortalidade por diagnóstico, sexo e faixa etária |
| `tabela4` | Custos das internações por diagnóstico e ano |
| `tabela5` | Comparação por período pré/durante/pós-COVID |
| `tabela6` | Modelo de regressão de Poisson (preditores de óbito) |
| `tabela7` | Internações ano × diagnóstico × sexo |
| `tabela8` | Resumo executivo com principais indicadores |

---

## 🗃️ Fonte dos Dados

- **SIH/SUS** — Sistema de Informações Hospitalares do SUS, Ministério da Saúde / DATASUS.
  Disponível em: https://datasus.saude.gov.br/
- **IBGE** — Estimativas e projeções populacionais 2015–2025.
  Disponível em: https://sidra.ibge.gov.br/tabela/6579
- **geobr** — Saldanha R, Casado L (2025). geobr: Download Official Spatial Data Sets of Brazil.
  R package version 1.9.1. https://github.com/ipeadata-lab/geobr
- **microdatasus** — Saldanha RF, Bastos RR, Barcellos C (2019).
  Microdatasus: pacote para download e pré-processamento de microdados do DATASUS.
  *Cadernos de Saúde Pública*, 35(9), e00032419.
  https://doi.org/10.1590/0102-311X00032419

---

## 📄 Licença

Este projeto está licenciado sob a licença **MIT** — veja o arquivo [LICENSE](LICENSE) para detalhes.
