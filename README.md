# Parte 1 — Os dados: SIM-DO/RN, 2025

Repositório do trabalho de Bioestatística, Enunciado 17. O conteúdo principal é o script R da Parte 1, que baixa e descreve óbitos de residentes no Rio Grande do Norte em 2025 e prepara o recorte de mulheres em idade fértil (10–49 anos).

## Conteúdo

- `Parte_1_Os_dados/Parte1_Rafael_Marcelo.R` — script solicitado para a Parte 1.
- `CITATION.cff` — metadados de citação para GitHub e Zenodo.

Os microdados individuais não estão incluídos. O script consulta a publicação SIM-DO mais recente disponível quando executado; por isso, os resultados podem mudar conforme a atualização dos dados preliminares de 2025.

## Reproduzir

Use R e conexão à internet. Execute o arquivo `.R` no RStudio ou rode `source("Parte_1_Os_dados/Parte1_Rafael_Marcelo.R")`. O script instala `microdatasus` do CRAN se necessário e imprime a data da consulta, contagens, tabela de frequências e histograma. Consulte a [documentação do microdatasus](https://rfsaldanha.github.io/microdatasus/reference/fetch_datasus.html).

## Escopo e qualidade dos dados

A cópia de dados conferida em 06/10/2026 tinha 23.350 registros e 87 variáveis. No recorte MIF, os controles foram 1.021 óbitos, 25 causas básicas do capítulo O, 6 registros gravídicos/puerperais com causa fora de O e 432 investigações indicadas por `TPPOS = S`.

O script registra a divergência observada entre campos de investigação: 887 registros MIF tinham `NUDIASOBCO` preenchido, apesar de apenas 432 estarem marcados `S` em `TPPOS`. Esses campos não são tratados como equivalentes. A base de 2025 é preliminar e os números devem ser rechecados a cada execução.

Fonte: [Sistema de Informações sobre Mortalidade (SIM)](https://svs.aids.gov.br/daent/cgiae/sim/) e dicionário oficial da [Declaração de Óbito](https://svs.aids.gov.br/daent/cgiae/sim/documentacao/dicionario-de-dados-SIM-tabela-DO.pdf).

## Privacidade e declaração acadêmica

As matrículas foram removidas desta cópia pública. O arquivo conserva os nomes dos autores indicados na atividade. A cópia pública não afirma que os autores confirmaram pessoalmente a compreensão do código; cada integrante deve fazer essa confirmação antes de entregar a atividade à professora. O uso de IA está declarado no script.

## Licença e DOI

Nenhuma licença de reutilização foi escolhida. A visibilidade pública no GitHub, por si só, não concede licença para reutilizar o código. O DOI do Zenodo ainda não foi emitido; será acrescentado à citação depois que os autores definirem a licença e a release for arquivada.