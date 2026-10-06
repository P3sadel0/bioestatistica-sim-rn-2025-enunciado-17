# ---------------------------------------------------------------
# Nome(s): Rafael Cavalcante; Marcelo de Jesus Filho
# Matrículas: omitidas desta cópia pública.
# Enunciado n: 17
#
# DECLARACAO DE USO DE INTELIGENCIA ARTIFICIAL
# Usei ferramenta de IA neste trabalho? ( ) Nao (X) Sim
# Qual(is) ferramenta(s): ChatGPT (OpenAI).
# Em quais partes usei: leitura do Guia e do Enunciado; apoio na
# elaboração e revisão do código; conferência das codificações e dos
# números de controle no arquivo SIM/DATASUS.
# O que pedi a ela: organizar a Parte 1 conforme os itens do Guia,
# preparar o código para baixar e tratar o recorte do Enunciado,
# identificar armadilhas de codificação e conferir os números pedidos.
# O que alterei ou corrigi na resposta dela: conferi nomes e códigos
# com a tabela de frequências do arquivo; decodifiquei IDADE antes de
# filtrar; usei TPPOS conforme os códigos encontrados; distingui
# NUDIASOBCO (tempo até a conclusão da investigação) de DIFDATA
# (tempo até o recebimento original da declaração de óbito).
#
# Confirmacao para entrega academica:
# Esta copia publica nao registra confirmacao de compreensao. Antes de
# entregar a atividade, cada integrante deve ler, compreender e confirmar
# pessoalmente a declaracao exigida pelo Guia.
# ---------------------------------------------------------------

# PARTE 1 - OS DADOS
# Enunciado 17: SIM, obitos de residentes no Rio Grande do Norte, 2025.
# A Parte 1 descreve e prepara os dados; nao executa testes estatisticos.

# (a) Baixar e importar os microdados do enunciado
# O Enunciado informa que microdatasus nao esta no CRAN. Na documentacao
# oficial consultada em 06/10/2026, a versao estavel 3.0.0 ja consta no CRAN.
# Se o CRAN nao disponibilizar o pacote na sua instalacao do R, use a
# alternativa oficial de desenvolvimento:
# install.packages("remotes")
# remotes::install_github("rfsaldanha/microdatasus")

if (!requireNamespace("microdatasus", quietly = TRUE)) {
  install.packages("microdatasus", repos = "https://cloud.r-project.org")
}
library(microdatasus)

cat("Versao do R:", R.version.string, "\n")
cat("Versao do microdatasus:", as.character(packageVersion("microdatasus")), "\n")

# Registrar a data desta execucao/download. O arquivo de 2025 e preliminar
# e pode ser atualizado pelo DATASUS.
data_download <- Sys.Date()
cat("Data do download:", format(data_download, "%d/%m/%Y"), "\n")

# Uma UF e um ano, conforme o Enunciado. Sem vars, preservam-se todas as
# colunas da publicacao para conferir quantas variaveis vieram.
dados_brutos <- microdatasus::fetch_datasus(
  year_start = 2025,
  year_end = 2025,
  uf = "RN",
  information_system = "SIM-DO",
  stop_on_error = TRUE,
  timeout = 600
)

if (is.null(dados_brutos) || nrow(dados_brutos) == 0L) {
  stop("O download nao retornou registros. Confira a conexao e a publicacao do DATASUS.")
}
dados_brutos <- as.data.frame(dados_brutos, stringsAsFactors = FALSE)

# Conferir se estao presentes as variaveis do enunciado e os campos auxiliares
# necessarios para construir a populacao, identificar investigacao e validar dias.
campos_necessarios <- c(
  "IDADE", "CAUSABAS", "OBITOGRAV", "OBITOPUERP", "DTOBITO",
  "DTINVESTIG", "RACACOR", "SEXO", "CODMUNRES", "TPPOS",
  "NUDIASOBCO", "NUDIASOBIN", "DIFDATA", "DTCONINV"
)
campos_ausentes <- setdiff(campos_necessarios, names(dados_brutos))
if (length(campos_ausentes) > 0L) {
  stop(paste("Campos esperados ausentes:", paste(campos_ausentes, collapse = ", ")))
}

# (b) Quantas observacoes e quantas variaveis vieram
n_observacoes <- nrow(dados_brutos)
n_variaveis <- ncol(dados_brutos)
cat("\n(b) Tamanho da base baixada\n")
cat("Observacoes:", n_observacoes, "\n")
cat("Variaveis:", n_variaveis, "\n")
cat("Esperado pelo Enunciado: cerca de 23.000 obitos.\n")
cat(
  "Diferenca em relacao a 23.000:",
  n_observacoes - 23000L, "registros (",
  round(100 * (n_observacoes - 23000) / 23000, 1), "%).\n"
)
print(names(dados_brutos))

# Comentario de conferencia do arquivo consultado em 06/10/2026:
# DORN2025.dbc (preliminar): 23.350 observacoes e 87 variaveis; diferenca
# de 350 registros (1,5%) em relacao a 23.000, compativel com o esperado.
# Se a base for atualizada, compare a nova saida com estes valores e registre
# a data efetiva do download, sem substituir os resultados por numeros antigos.

# (c) Dicionario das variaveis do enunciado
# O formato importado no R pode ser texto; o tipo estatistico abaixo descreve
# o que cada campo mede, depois de decodificado quando necessario.
#
# | Campo | O que registra | Codificacao | Tipo estatistico |
# |---|---|---|---|
# | IDADE | Idade ao obito | 3 digitos; o primeiro indica unidade; 4=anos; 5=100 anos ou mais; 0-3=unidades menores que 1 ano; 9/999=ignorado | Quantitativa continua apos conversao; registrada em anos completos inteiros |
# | CAUSABAS | Causa basica do obito | Codigo CID-10; normalmente 4 caracteres | Qualitativa nominal |
# | OBITOGRAV | Obito durante a gravidez | 1=sim; 2=nao; 9=ignorado | Qualitativa nominal |
# | OBITOPUERP | Obito no puerperio | 1=ate 42 dias; 2=43 dias a 1 ano; 3=nao; 9=ignorado | Qualitativa nominal |
# | DTOBITO | Data do obito | Data no formato ddmmaaaa | Temporal |
# | DTINVESTIG | Data da investigacao | Data no formato ddmmaaaa | Temporal |
# | RACACOR | Raca/cor | 1=branca; 2=preta; 3=amarela; 4=parda; 5=indigena; 9=ignorada | Qualitativa nominal |
#
# Campos auxiliares utilizados, alem dos sete campos pedidos:
# | Campo | Uso neste script | Codificacao/tipo |
# | SEXO | Definir mulher | 1=masculino; 2=feminino; 0/9=ignorado no arquivo consultado; qualitativa nominal |
# | CODMUNRES | Confirmar residencia no RN | Codigo municipal IBGE; prefixo 24=RN; identificador nominal |
# | TPPOS | Indicador de obito investigado | No arquivo 2025: S=sim; N=nao; vazio=sem informacao; qualitativa nominal |
# | NUDIASOBCO | Dias do obito ate a conclusao da investigacao | Numero de dias; quantitativa discreta |
# | NUDIASOBIN | Campo alternativo de dias de investigacao | Numero de dias; quantitativa discreta; conferir completude |
# | DIFDATA | Intervalo entre obito e recebimento original da DO | Numero de dias; quantitativa discreta; nao mede tempo de investigacao |
# | DTCONINV | Data de conclusao da investigacao | Data no formato ddmmaaaa; temporal |
#
# Dicionario oficial do SIM consultado: NUDIASOBCO mede dias entre DTOBITO
# e DTCONINV; DIFDATA mede DTOBITO menos a data de recebimento original da DO.
# https://svs.aids.gov.br/daent/cgiae/sim/documentacao/dicionario-de-dados-SIM-tabela-DO.pdf

# (d) Tratamento das variaveis, com justificativa e contagem das exclusoes
# Primeiro, olhar os codigos crus. Isto tambem evidencia a armadilha de IDADE:
# por exemplo, 401 significa 1 ano, nao 401 anos; 477 significa 77 anos.
cat("\n(d) Inspecao dos codigos crus antes de tratar\n")
idade_codigo_cru <- trimws(as.character(dados_brutos$IDADE))
cat("Prefixo do campo IDADE:\n")
print(table(substr(idade_codigo_cru, 1, 1), useNA = "ifany"))
cat("SEXO:\n")
print(table(dados_brutos$SEXO, useNA = "ifany"))
cat("RACACOR:\n")
print(table(dados_brutos$RACACOR, useNA = "ifany"))
cat("OBITOGRAV:\n")
print(table(dados_brutos$OBITOGRAV, useNA = "ifany"))
cat("OBITOPUERP:\n")
print(table(dados_brutos$OBITOPUERP, useNA = "ifany"))
cat("TPPOS (investigacao):\n")
print(table(dados_brutos$TPPOS, useNA = "ifany"))

# Exibir completude dos campos de tempo antes de escolher qual usar.
# NUDIASOBCO e o tempo ate a conclusao da investigacao; DIFDATA nao e
# equivalente, pois termina no recebimento original da declaracao de obito.
# NA/vazio significa dado ausente, nunca zero dias.
converter_numero_sim <- function(x) {
  valor <- trimws(as.character(x))
  valor[is.na(x) | valor == ""] <- NA_character_
  suppressWarnings(as.numeric(valor))
}
dias_prontos_todos <- converter_numero_sim(dados_brutos$NUDIASOBCO)
dias_modulo_todos <- converter_numero_sim(dados_brutos$NUDIASOBIN)
cat("NUDIASOBCO preenchidos na base:", sum(!is.na(dias_prontos_todos)),
    "de", nrow(dados_brutos), "\n")
cat("NUDIASOBIN preenchidos na base:", sum(!is.na(dias_modulo_todos)),
    "de", nrow(dados_brutos), "\n")
cat("DIFDATA - distribuicao dos primeiros codigos observados:\n")
print(head(sort(table(dados_brutos$DIFDATA, useNA = "ifany"), decreasing = TRUE), 10))

# No arquivo consultado em 06/10/2026: NUDIASOBCO tinha 889 valores
# preenchidos; NUDIASOBIN estava vazio em 23.350/23.350 registros.
# Nao usar DIFDATA como duracao da investigacao: o dicionario oficial o define
# como intervalo entre o obito e o recebimento original da DO.

# IDADE combina unidade e quantidade. Para anos completos, unidades 0-3
# correspondem a menos de 1 ano e recebem 0; 4xx sao anos; 5xx sao 100+anos.
# Codigo 000 representa zero minutos e, em anos completos, vale 0; unidades
# 0-3 tambem resultam em 0. Codigo 999 e unidade 9 ficam como ausentes.
# Isso evita filtrar pelo numero bruto e excluir/selecionar pessoas de modo errado.
idade_unidade <- substr(idade_codigo_cru, 1, 1)
idade_valor <- suppressWarnings(as.integer(substr(idade_codigo_cru, 2, 3)))
idade_ausente <- is.na(idade_codigo_cru) |
  idade_codigo_cru %in% c("", "999") |
  idade_unidade == "9"
idade_anos <- rep(NA_integer_, length(idade_codigo_cru))
idade_menor_um_ano <- !idade_ausente & idade_unidade %in% c("0", "1", "2", "3")
idade_anos[idade_menor_um_ano] <- 0L
idade_em_anos <- !idade_ausente & idade_unidade == "4" & !is.na(idade_valor)
idade_anos[idade_em_anos] <- idade_valor[idade_em_anos]
idade_100_mais <- !idade_ausente & idade_unidade == "5" & !is.na(idade_valor)
idade_anos[idade_100_mais] <- 100L + idade_valor[idade_100_mais]
dados_brutos$idade_anos <- idade_anos

# Datas chegam como texto ddmmaaaa. Valores vazios ou de preenchimento viram NA.
converter_data_sim <- function(x) {
  if (inherits(x, "Date")) return(as.Date(x))
  if (inherits(x, c("POSIXct", "POSIXlt"))) return(as.Date(x))
  valor <- trimws(as.character(x))
  valor[is.na(x) | valor == "" | valor %in% c("00000000", "99999999")] <-
    NA_character_
  as.Date(valor, format = "%d%m%Y")
}
dados_brutos$DTOBITO_data <- converter_data_sim(dados_brutos$DTOBITO)
dados_brutos$DTINVESTIG_data <- converter_data_sim(dados_brutos$DTINVESTIG)
dados_brutos$DTCONINV_data <- converter_data_sim(dados_brutos$DTCONINV)

# Aplicar os criterios do enunciado em etapas e contar cada exclusao.
# CODMUNRES (residencia) e o criterio geografico; nao se usa CODMUNOCOR,
# que se refere ao local de ocorrencia. A consulta uf=RN seleciona o arquivo,
# mas a residencia tambem e verificada no proprio registro.
codigo_residencia <- trimws(as.character(dados_brutos$CODMUNRES))
reside_rn <- !is.na(codigo_residencia) & grepl("^24", codigo_residencia)
excluidos_residencia <- sum(!reside_rn)
dados_rn <- dados_brutos[reside_rn, , drop = FALSE]

ano_obito <- suppressWarnings(as.integer(format(dados_rn$DTOBITO_data, "%Y")))
ano_2025 <- !is.na(ano_obito) & ano_obito == 2025L
excluidos_data <- nrow(dados_rn) - sum(ano_2025)
dados_rn_2025 <- dados_rn[ano_2025, , drop = FALSE]

# No arquivo consultado: 0 registros foram excluidos por residencia e 0 por ano;
# os 23.350 registros tinham CODMUNRES iniciado por 24 e DTOBITO em 2025.
sexo_codigo <- toupper(trimws(as.character(dados_rn_2025$SEXO)))
sexo_feminino <- sexo_codigo %in% c("2", "F")
excluidos_sexo <- sum(!sexo_feminino)
sexo_masculino <- sum(sexo_codigo %in% c("1", "M"))
sexo_ignorado <- sum(!sexo_feminino & !(sexo_codigo %in% c("1", "M")))
dados_mulheres <- dados_rn_2025[sexo_feminino, , drop = FALSE]

# A populacao do estudo e obito de mulher com idade de 10 a 49 anos, inclusive.
idade_mulheres <- dados_mulheres$idade_anos
abaixo_10 <- sum(!is.na(idade_mulheres) & idade_mulheres < 10L)
idade_50_mais <- sum(!is.na(idade_mulheres) & idade_mulheres >= 50L)
idade_desconhecida <- sum(is.na(idade_mulheres))
mulher_mif <- !is.na(idade_mulheres) &
  idade_mulheres >= 10L & idade_mulheres <= 49L
excluidos_idade <- sum(!mulher_mif)
dados_mif <- dados_mulheres[mulher_mif, , drop = FALSE]

cat("\nContagem das exclusoes por criterio (sem sobreposicao, em ordem):\n")
cat("Fora da residencia RN:", excluidos_residencia, "\n")
cat("DTOBITO ausente ou fora de 2025:", excluidos_data, "\n")
cat("Sexo diferente de feminino:", excluidos_sexo,
    "(masculino:", sexo_masculino, "; ignorado/outro:", sexo_ignorado, ")\n")
cat("Mulheres fora da faixa 10-49 ou com idade desconhecida:", excluidos_idade,
    "(abaixo de 10:", abaixo_10, "; 50 ou mais:", idade_50_mais,
    "; idade desconhecida:", idade_desconhecida, ")\n")
cat("Total na populacao MIF:", nrow(dados_mif), "\n")

# Valores observados no arquivo consultado:
# 12.920 registros foram excluidos por nao serem do sexo feminino
# (12.915 masculinos e 5 com sexo ignorado).
# Entre as 10.430 mulheres, 240 tinham menos de 10 anos, 9.168 tinham
# 50 anos ou mais e 1 tinha idade desconhecida; permaneceram 1.021 MIF.
# O recorte por residencia e ano nao excluiu registros neste arquivo.

# Recodificar variaveis categoricas preservando codigos ignorados como NA.
codigo_gravidez <- trimws(as.character(dados_mif$OBITOGRAV))
gravidez_rotulo <- rep(NA_character_, nrow(dados_mif))
gravidez_rotulo[codigo_gravidez == "1"] <- "Sim"
gravidez_rotulo[codigo_gravidez == "2"] <- "Nao"
dados_mif$obito_na_gravidez <- factor(gravidez_rotulo, levels = c("Nao", "Sim"))

codigo_puerperio <- trimws(as.character(dados_mif$OBITOPUERP))
puerperio_rotulo <- rep(NA_character_, nrow(dados_mif))
puerperio_rotulo[codigo_puerperio == "1"] <- "Sim, ate 42 dias"
puerperio_rotulo[codigo_puerperio == "2"] <- "Sim, de 43 dias a 1 ano"
puerperio_rotulo[codigo_puerperio == "3"] <- "Nao"
dados_mif$obito_no_puerperio <- factor(
  puerperio_rotulo,
  levels = c("Nao", "Sim, ate 42 dias", "Sim, de 43 dias a 1 ano")
)

codigo_raca <- trimws(as.character(dados_mif$RACACOR))
raca_rotulo <- c(
  "1" = "Branca", "2" = "Preta", "3" = "Amarela",
  "4" = "Parda", "5" = "Indigena",
  "9" = NA_character_, "0" = NA_character_
)
raca_cor <- unname(raca_rotulo[codigo_raca])
dados_mif$raca_cor <- factor(
  raca_cor,
  levels = c("Branca", "Preta", "Amarela", "Parda", "Indigena")
)

# Criar faixas etarias de 10 anos, adequadas ao recorte de mulheres de 10-49.
dados_mif$faixa_etaria <- cut(
  dados_mif$idade_anos,
  breaks = c(9, 19, 29, 39, 49),
  labels = c("10-19", "20-29", "30-39", "40-49"),
  include.lowest = TRUE,
  right = TRUE
)

# Agrupar a causa basica pelas categorias pedidas. CID-10 e um codigo,
# nao uma medida numerica; codigos ausentes/invalidos ficam em grupo separado.
causa_codigo <- toupper(trimws(as.character(dados_mif$CAUSABAS)))
causa_valida <- !is.na(causa_codigo) & nzchar(causa_codigo) &
  grepl("^[A-Z][0-9]{2}", causa_codigo)
causa_letra <- substr(causa_codigo, 1, 1)
causa_dois_digitos <- suppressWarnings(
  as.integer(substr(causa_codigo, 2, 3))
)
grupo_causa <- rep("Demais", nrow(dados_mif))
grupo_causa[!causa_valida] <- "Sem causa informada/nao classificavel"
grupo_causa[causa_valida & causa_letra %in% c("V", "W", "X", "Y")] <-
  "Causas externas"
grupo_causa[
  causa_valida &
    (causa_letra == "C" |
       (causa_letra == "D" & causa_dois_digitos <= 48L))
] <- "Neoplasias"
grupo_causa[causa_valida & causa_letra == "I"] <- "Circulatorio"
grupo_causa[causa_valida & causa_letra %in% c("A", "B")] <- "Infecciosas"
grupo_causa[causa_valida & causa_letra == "O"] <- "Maternas"
dados_mif$grupo_causa <- factor(
  grupo_causa,
  levels = c(
    "Causas externas", "Neoplasias", "Circulatorio",
    "Infecciosas", "Maternas", "Demais",
    "Sem causa informada/nao classificavel"
  )
)

# TPPOS e o campo especifico para investigacao. Neste arquivo, S=sim,
# N=nao e vazio=sem informacao; nao transformar vazio em "nao".
codigo_tppos <- toupper(trimws(as.character(dados_mif$TPPOS)))
investigado_rotulo <- rep(NA_character_, nrow(dados_mif))
investigado_rotulo[codigo_tppos %in% c("S", "1")] <- "Sim"
investigado_rotulo[codigo_tppos %in% c("N", "2")] <- "Nao"
dados_mif$investigado <- factor(
  investigado_rotulo,
  levels = c("Nao", "Sim")
)

# O campo de dias da publicacao e NUDIASOBCO (obito ate a conclusao da
# investigacao). Se faltar, calcula-se pela diferenca DTCONINV - DTOBITO;
# se ambos estiverem ausentes, o tempo continua NA, nunca vira zero.
dias_prontos_mif <- converter_numero_sim(dados_mif$NUDIASOBCO)
diferenca_datas_mif <- as.integer(
  dados_mif$DTCONINV_data - dados_mif$DTOBITO_data
)
pares_dias_validos <- !is.na(dias_prontos_mif) & !is.na(diferenca_datas_mif)
n_pares_dias <- sum(pares_dias_validos)
n_pares_iguais <- sum(
  dias_prontos_mif[pares_dias_validos] ==
    diferenca_datas_mif[pares_dias_validos]
)
dias_fallback <- is.na(dias_prontos_mif) & !is.na(diferenca_datas_mif)
dias_ate_investigacao <- dias_prontos_mif
dias_ate_investigacao[dias_fallback] <- diferenca_datas_mif[dias_fallback]
dados_mif$dias_ate_investigacao <- dias_ate_investigacao

cat("\nConferencia do tempo ate a conclusao da investigacao (MIF):\n")
cat("NUDIASOBCO preenchidos:", sum(!is.na(dias_prontos_mif)), "\n")
cat("Pares NUDIASOBCO e DTCONINV - DTOBITO:", n_pares_dias, "\n")
cat("Pares iguais:", n_pares_iguais, "\n")
cat("Valores calculados por fallback das datas:", sum(dias_fallback), "\n")
cat("MIF sem tempo disponivel:", sum(is.na(dias_ate_investigacao)), "\n")
print(summary(dados_mif$dias_ate_investigacao))

# No arquivo consultado em 06/10/2026, em MIF:
# 887/1.021 tinham NUDIASOBCO preenchido e 134 nao tinham tempo disponivel.
# Os 887 valores preenchidos coincidiam com DTCONINV - DTOBITO; nenhum
# fallback foi necessario. A mediana era 67 dias; intervalo observado 0-424.
# Alerta de consistencia: 432 MIF tinham TPPOS="S", 369 TPPOS="N" e
# 220 TPPOS vazio; ainda assim 303 codigos "N" e 159 vazios tinham NUDIASOBCO.
# Outros 7 "S" nao tinham NUDIASOBCO. Mantivemos os campos originais separados:
# controle de investigados usa TPPOS; duracao usa NUDIASOBCO, sem ocultar o conflito.

# Decisao com alternativa rejeitada 1: nao comparamos IDADE bruta a 10-49,
# pois 401 significa 1 ano e 477 significa 77; o prefixo foi decodificado antes.
# Decisao com alternativa rejeitada 2: nao usamos DIFDATA nem a presenca de
# DTINVESTIG para substituir TPPOS/NUDIASOBCO; seus significados sao distintos,
# e DIFDATA e tempo ate o recebimento original da DO.

# Controles pedidos na secao 7 do Enunciado, com o codigo que os reproduz:
# 1. Quantos obitos de MIF foram obtidos?
controle_mif <- nrow(dados_mif)
cat("\nControle 1 - obitos de MIF:", controle_mif, "\n")
# Resultado observado em 06/10/2026: 1.021.

# 2. Quantos obitos de MIF tem causa basica no capitulo O?
causa_materna <- causa_valida & causa_letra == "O"
controle_causa_materna <- sum(causa_materna, na.rm = TRUE)
cat("Controle 2 - causa basica capitulo O:", controle_causa_materna, "\n")
# Resultado observado em 06/10/2026: 25.

# 3. Quantas MIF gravidas ou puerperas no obito tem causa fora do capitulo O?
gravida_no_obito <- codigo_gravidez == "1"
puerpera_no_obito <- codigo_puerperio %in% c("1", "2")
gravida_ou_puerpera <- gravida_no_obito | puerpera_no_obito
causa_fora_capitulo_o <- causa_valida & causa_letra != "O"
controle_gravida_puerpera_fora_o <- sum(
  gravida_ou_puerpera & causa_fora_capitulo_o,
  na.rm = TRUE
)
cat(
  "Controle 3 - gravidez/puerperio com causa fora do capitulo O:",
  controle_gravida_puerpera_fora_o, "\n"
)
# Resultado observado em 06/10/2026: 6.
# Campos gravide/puerperio desconhecidos nao sao tratados como "nao".

# 4. Quantos obitos de MIF foram investigados segundo TPPOS?
controle_investigados <- sum(dados_mif$investigado == "Sim", na.rm = TRUE)
cat("Controle 4 - TPPOS indica investigacao:", controle_investigados, "\n")
cat("Distribuicao TPPOS nas MIF:\n")
print(table(dados_mif$investigado, useNA = "ifany"))
# Resultado observado em 06/10/2026: 432; 369 nao investigados e 220 sem TPPOS.
# A divergencia com NUDIASOBCO foi registrada acima e precisa ser considerada
# antes de interpretar qualquer proporcao de investigacao.

# (e) Tabela de frequencias e grafico exploratorio rotulado
cat("\n(e) Frequencia do grupo de causa entre as MIF\n")
ordem_grupos <- c(
  "Causas externas", "Neoplasias", "Circulatorio",
  "Infecciosas", "Maternas", "Demais",
  "Sem causa informada/nao classificavel"
)
n_por_grupo <- vapply(
  ordem_grupos,
  function(grupo) sum(grupo_causa == grupo, na.rm = TRUE),
  integer(1)
)
tabela_grupo_causa <- data.frame(
  Grupo = ordem_grupos,
  n = as.integer(n_por_grupo),
  Percentual = round(100 * as.integer(n_por_grupo) / nrow(dados_mif), 1)
)
tabela_grupo_causa <- tabela_grupo_causa[tabela_grupo_causa$n > 0L, ]
print(tabela_grupo_causa, row.names = FALSE)

# Resultados observados em 06/10/2026: externas 164 (16,1%);
# neoplasias 269 (26,3%); circulatorio 181 (17,7%); infecciosas 50 (4,9%);
# maternas 25 (2,4%); demais 332 (32,5%). Percentuais podem somar 99,9%
# devido ao arredondamento.

# Histograma da idade em anos completos, com titulo, eixos e fonte.
# Em RStudio, o grafico aparece no painel Plots.
par(mar = c(6, 4.5, 4, 1.5) + 0.1)
hist(
  dados_mif$idade_anos,
  breaks = seq(9.5, 49.5, by = 1),
  main = "Idade ao obito entre mulheres de 10 a 49 anos\nRio Grande do Norte, 2025",
  xlab = "Idade ao obito (anos completos)",
  ylab = "Numero de obitos",
  col = "#6BAED6",
  border = "white"
)
mtext(
  paste(
    "Fonte: SIM/DATASUS, SIM-DO RN 2025 (preliminar); download em",
    format(data_download, "%d/%m/%Y")
  ),
  side = 1, line = 4.2, adj = 0, cex = 0.75
)

# (f) O que esta base nao permite responder (5-10 linhas)
# 1. O SIM registra obitos, nao todas as mulheres residentes; sem denominador
#    populacional, esta base nao estima risco, incidencia ou letalidade.
# 2. Os dados de 2025 sao preliminares e podem ser atualizados pelo DATASUS.
# 3. Causa basica pode ser mal definida ou preenchida de forma incompleta.
# 4. OBITOGRAV/OBITOPUERP estavam ausentes ou ignorados para 420 das 1.021 MIF;
#    os seis casos positivos fora do capitulo O nao representam todos os casos ocultos.
# 5. TPPOS e NUDIASOBCO divergem em parte das MIF; o indicador de investigacao
#    precisa ser interpretado com cautela e revisado com a docente.
# 6. O tempo ate a conclusao estava ausente em 134 MIF; analisar somente casos
#    com tempo preenchido pode selecionar investigacoes mais completas.
# 7. A base nao informa renda, acesso ao cuidado ou a sequencia clinica, portanto
#    nao explica por si so por que uma mulher morreu ou se a morte era evitavel.
# 8. Os dados sao observacionais e descritivos; nao demonstram causalidade.

# DIARIO DE REVISAO (dois erros encontrados e corrigidos):
# 1. Erro de sintaxe encontrado na revisao: o nome 50_mais comecava por numero
#    e nao pode ser usado como identificador em R. Foi renomeado idade_50_mais.
#    A sintaxe final e conferida com parse() antes da entrega.
# 2. Erro de classificacao encontrado na revisao: IDADE=000 foi inicialmente
#    tratado como ausente. O Guia/dicionario indica zero minutos; agora vale 0
#    anos completos. O codigo 999 e a unidade 9 continuam como desconhecidos.
